#!/bin/bash
set +e

sudo apt update -y
sudo apt install -y openjdk-17-jdk ufw wget unzip

# Install H2
mkdir -p /opt/h2
cd /opt/h2

wget -q https://repo1.maven.org/maven2/com/h2database/h2/2.4.240/h2-2.4.240.jar -O h2.jar

cd /opt/h2/bin

# Starts H2 in server mode
nohup java -cp /opt/h2/h2.jar org.h2.tools.Server \
  -tcp -tcpAllowOthers -tcpPort 9092 -ifNotExists &
sleep 5

# Firewall: Allow
sudo ufw allow from 192.168.56.11 to any port 9092 proto tcp
sudo ufw --force enable

echo "H2 Database running on port 9092"

# Check H2 Status
if ss -tulpn | grep -q 9092; then
  echo "H2 is active and listening on port 9092"
else
  echo "H2 failed to start"
fi

exit 0