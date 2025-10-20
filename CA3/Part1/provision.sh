export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y git openjdk-17-jdk wget unzip

wget https://services.gradle.org/distributions/gradle-8.7-bin.zip -P /tmp
unzip -d /opt/gradle /tmp/gradle-8.7-bin.zip
echo 'export PATH=$PATH:/opt/gradle/gradle-8.7/bin' >> /etc/profile.d/gradle.sh
chmod +x /etc/profile.d/gradle.sh
source /etc/profile.d/gradle.sh

apt-get install -y maven

if [ "$CLONE_REPO" = "true" ]; then
  cd /home/vagrant
  git clone https://github.com/1240598-1240601/cogsi2526.git project
fi

if [ "$RUN_APPS" = "true" ]; then
  cd /home/vagrant/project/CA2/Part1
  gradle build

  nohup gradle runServer > /home/vagrant/server.log 2>&1 &

  cd /home/vagrant/project/CA2/Part2
  ./gradlew build
  nohup ./gradlew bootRun > /home/vagrant/spring.log 2>&1 &
fi
