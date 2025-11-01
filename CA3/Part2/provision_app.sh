#!/bin/bash
set +e

# === System preparation ===
sudo apt update -y
sudo apt install -y openjdk-21-jdk git gradle netcat dos2unix

# === Clone project repository ===
cd /home/vagrant
git clone https://github.com/1240598Rafa/cogsi2526-1240598-1240601.git
cp -r cogsi2526-1240598-1240601 /home/vagrant/app
cd /home/vagrant/app/CA2/Part2

# === Ensure Gradle wrapper is executable ===
dos2unix gradlew
chmod +x gradlew

# === Create application.properties with full configuration ===
mkdir -p src/main/resources
cat > src/main/resources/application.properties <<EOF
spring.datasource.url=jdbc:h2:tcp://192.168.56.10:9092/~/testdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.h2.console.enabled=true
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
server.port=8080
EOF

# === Wait until H2 Database (on db VM) is reachable ===
echo "Waiting for H2 database to be ready..."
until nc -z 192.168.56.10 9092; do
  sleep 2
done
echo "Database is reachable. Proceeding with build."

# === Build the Spring Boot project ===
./gradlew clean build

# === Find and execute the correct (non-plain) JAR file ===
JAR_FILE=$(find build/libs -name "*.jar" ! -name "*-plain.jar" | head -n 1)
if [ -f "$JAR_FILE" ]; then
  nohup java -jar "$JAR_FILE" > /home/vagrant/app/app.log 2>&1 &
  echo "Spring Boot application started successfully on port 8080."
else
  echo "Error: Executable JAR file not found after build."
fi

exit 0
