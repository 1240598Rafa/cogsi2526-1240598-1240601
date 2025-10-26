#!/bin/bash
set +e

sudo apt update -y
sudo apt install -y openjdk-17-jdk ufw wget unzip

# Install H2
mkdir -p /opt/h2
cd /opt/h2
wget -q https://h2database.com/h2-2023-06-19.zip
unzip -o h2-2023-06-19.zip
cd h2/bin

# Starts H2 in server mode
nohup java -cp h2*.jar org.h2.tools.Server \
  -tcp -tcpAllowOthers -tcpPort 9092 -ifNotExists &
sleep 5

# Firewall: Allow
sudo ufw allow from 192.168.56.11 to any port 9092 proto tcp
sudo ufw --force enable

echo "H2 Database running on port 9092"

exit 0