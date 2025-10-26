#!/bin/bash
set +e

sudo apt update -y
sudo apt install -y git openjdk-17-jdk gradle netcat

# CA2 Repo Clone
cd /home/vagrant
git clone https://github.com/1240598Rafa/cogsi2526-1240598-1240601.git
cd cogsi2526-1240598-1240601/CA2/Part2

mkdir -p src/main/resources

# DB Connection
cat > src/main/resources/application.properties <<EOF
spring.datasource.url=jdbc:h2:tcp://192.168.56.10:9092/~/testdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.h2.console.enabled=true
server.port=8080
EOF

echo "Waiting for Database..."
until nc -z 192.168.56.10 9092; do
  sleep 2
done

./gradlew build
nohup java -jar build/libs/*.jar &

echo "App Running"
