#!/bin/bash
set -euo pipefail

# Terraform-provided values.
VOLUME_ID="${volume_id}"
DEVICE_NAME="${device_name}"

# Fetch metadata using IMDSv2.
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s \
  http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s \
  http://169.254.169.254/latest/dynamic/instance-identity/document | \
  awk -F"\"" '/region/ {print $4}')

# Ensure we can attach the data volume even on instance replacement.
ATTACH_STATE=$(aws ec2 describe-volumes --region "$REGION" --volume-ids "$VOLUME_ID" \
  --query "Volumes[0].Attachments[0].State" --output text 2>/dev/null || true)
if [ "$ATTACH_STATE" != "attached" ]; then
  for _ in $(seq 1 10); do
    if aws ec2 attach-volume --region "$REGION" --volume-id "$VOLUME_ID" \
      --instance-id "$INSTANCE_ID" --device "$DEVICE_NAME"; then
      break
    fi
    sleep 6
  done
fi

# Wait for the device path to appear (NVMe on Nitro, /dev/xvdX otherwise).
DEVICE_PATH=""
for _ in $(seq 1 60); do
  if [ -e "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_$VOLUME_ID" ]; then
    DEVICE_PATH=$(readlink -f "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_$VOLUME_ID")
    break
  fi
  if [ -e "$DEVICE_NAME" ]; then
    DEVICE_PATH="$DEVICE_NAME"
    break
  fi
  sleep 2
done

if [ -z "$DEVICE_PATH" ]; then
  echo "EBS device not found for volume $VOLUME_ID" >&2
  exit 1
fi

mkdir -p /var/lib/elasticsearch

# Format only if the volume is empty (no filesystem yet).
if ! blkid -o value -s TYPE "$DEVICE_PATH" >/dev/null 2>&1; then
  mkfs -t xfs "$DEVICE_PATH"
fi

UUID=$(blkid -o value -s UUID "$DEVICE_PATH")
if ! grep -q "$UUID" /etc/fstab; then
  echo "UUID=$UUID /var/lib/elasticsearch xfs defaults,nofail 0 2" >> /etc/fstab
fi

mount -a

# Elasticsearch prerequisites.
cat >/etc/sysctl.d/99-elasticsearch.conf <<'SYSCTL'
vm.max_map_count=262144
SYSCTL
sysctl -p /etc/sysctl.d/99-elasticsearch.conf

# Install Elasticsearch 8.x.
cat >/etc/yum.repos.d/elasticsearch.repo <<'REPO'
[elasticsearch-8.x]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
REPO

yum install -y elasticsearch

# Configure single-node operation with persistent data path.
cat >/etc/elasticsearch/elasticsearch.yml <<'CONFIG'
cluster.name: es-logs
node.name: es-singleton
discovery.type: single-node
path.data: /var/lib/elasticsearch
network.host: 0.0.0.0
http.port: 9200
xpack.security.enabled: false
CONFIG

chown -R elasticsearch:elasticsearch /var/lib/elasticsearch

# Ensure clean shutdown to reduce risk of data corruption.
mkdir -p /etc/systemd/system/elasticsearch.service.d
cat >/etc/systemd/system/elasticsearch.service.d/override.conf <<'OVERRIDE'
[Service]
ExecStop=
ExecStop=/usr/share/elasticsearch/bin/elasticsearch-shutdown
TimeoutStopSec=180
ExecStopPost=/bin/sleep 10
OVERRIDE

systemctl daemon-reload
systemctl enable --now elasticsearch
