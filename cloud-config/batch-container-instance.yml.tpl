Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0

--==BOUNDARY==
Content-Type: text/cloud-boothook; charset="us-ascii"

# Manually mount unformatted instance store volumes. Mounting in a
# cloud-boothook ensures that the drive is mounted before the Docker daemon and
# ECS agent start, which avoids potential race conditions.
#
# See:
# - https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bootstrap_container_instance.html#bootstrap_docker_daemon
# - https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/amazon-linux-ami-basics.html#supported-user-data-formats
mkfs.ext4 -E nodiscard /dev/nvme1n1
mkdir -p /media/nvme1n1
mount -t ext4 -o defaults,nofail,discard /dev/nvme1n1 /media/nvme1n1

--==BOUNDARY==
