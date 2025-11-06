export DEBIAN_FRONTEND=noninteractive
set -e

apt-get update -y
apt-get install -y git openjdk-21-jdk wget unzip

if [ ! -d "/opt/gradle/gradle-8.7" ]; then
  wget -q https://services.gradle.org/distributions/gradle-8.7-bin.zip -P /tmp
  unzip -d /opt/gradle /tmp/gradle-8.7-bin.zip
fi
echo 'export PATH=$PATH:/opt/gradle/gradle-8.7/bin' >> /etc/profile.d/gradle.sh
chmod +x /etc/profile.d/gradle.sh
source /etc/profile.d/gradle.sh

apt-get install -y maven

CLONE_REPO=${CLONE_REPO:-true}
RUN_APPS=${RUN_APPS:-false}
BUILD_APPS=${BUILD_APPS:-true}

if [ "$CLONE_REPO" = "true" ]; then
  cd /home/vagrant
  if [ -d "project/.git" ]; then
    echo "Repository already exists, pulling latest changes..."
    cd project && git pull origin main
  else
    echo "Cloning repository..."
    git clone https://github.com/1240598Rafa/cogsi2526-1240598-1240601.git project
  fi
else
  echo "Skipping clone (CLONE_REPO=false)"
fi

if [ "$BUILD_APPS" = "true" ]; then
  echo "Building CA2 Part1 and Part2..."
  cd /home/vagrant/project/CA2/Part1
  gradle clean build

  cd /home/vagrant/project/CA2/Part2
  chmod +x gradlew
  ./gradlew clean build
else
  echo "Skipping build (BUILD_APPS=false)"
fi

if [ "$RUN_APPS" = "true" ]; then
  echo "Starting CA2 Part1 (Chat Server)..."
  cd /home/vagrant/project/CA2/Part1
  nohup gradle runServer > /home/vagrant/server.log 2>&1 &

  echo "Starting CA2 Part2 (Spring Boot)..."
  cd /home/vagrant/project/CA2/Part2
  nohup ./gradlew bootRun > /home/vagrant/spring.log 2>&1 &
else
  echo "Skipping application start (RUN_APPS=false)"
fi

echo "Provisioning completed successfully!"