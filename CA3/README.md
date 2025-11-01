# CA3 - Part 1: Vagrant and Gradle Environment

This part of the assignment required the configuration of a reproducible environment using Vagrant and Gradle, so that building and running a Spring Boot application could be automated.
The goal is to ensure that every developer can run the same project under the same conditions - same OS, same JDK, same Gradle version - without having to setup manually.

## Step 1 — Vagrant Environment Creation

It was requested to:

“Use Vagrant to define and provision a virtual machine with Ubuntu and all tools needed to build and run the project.”

So a new directory was created as /CA3/Part1/:
mkdir /CA3/Part1/

Then a Vagrantfile was created in the /CA3/Part1/ folder with the following configuration:

vagrant plugin install vagrant-vmware-desktop

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.synced_folder ".", "/vagrant", disabled: false
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end
  config.vm.provision "shell", path: "provision.sh"
end

Explanation of the code on the vagrant file:

Box - specifies the base OS image (Ubuntu 22.04 which goes by codename jammy).

Forwarded port - exposes the guest port 8080 to the host, so http://localhost:8080 opens the application.

Synced folder - links the current folder on the host with /vagrant inside the VM, allowing live file sync.

Provisioner - automatically runs a shell script (provision.sh) on the first vagrant up to install dependencies.

## Step 2 — Provisioning Script

It was required to install all dependencies automatically (Java, Git, Gradle).
The file provision.sh was written as follows:

#!/bin/bash
apt-get update
apt-get install -y git openjdk-17-jdk wget unzip

#Install Gradle 8.7
wget https://services.gradle.org/distributions/gradle-8.7-bin.zip -P /tmp
unzip -d /opt/gradle /tmp/gradle-8.7-bin.zip
export PATH=$PATH:/opt/gradle/gradle-8.7/bin

#Clone repository
cd /home/vagrant
git clone https://github.com/1240598Rafa/cogsi2526-1240598-1240601.git project

Explanation of the code:

Installs the JDK 17, required for Spring Boot compatibility.
Downloads and extracts Gradle 8.7 to /opt/gradle.
Updates the system PATH to use the new Gradle installation.
Clones the project repository automatically into /home/vagrant/project.

This ensures a fully self-contained environment: once vagrant up is executed, the system is ready for building and running the project without any manual setup.

## Step 3 — Launching and Verifying the VM

The following commands were used on the host:

vagrant up
vagrant ssh

Once inside the VM, the environment was verified:

java -version
gradle -v

Output confirmed:

openjdk version "17.0.16"
Gradle 8.7

This validates that both JDK and Gradle were correctly installed and available globally.

## Step 4 — Building and Running the Spring Boot Project

Inside the cloned project directory:

cd /home/vagrant/project/CA2/Part2
chmod +x gradlew
./gradlew clean build

chmod +x gradlew - gives execution permission to the Gradle wrapper script.
./gradlew clean build - compiles and packages the project, downloading dependencies if needed.

Once the build completed successfully, the application was started:

./gradlew bootRun

At this point, the REST API was available at:

http://localhost:8080/employees


After opening the url the exepected JSON response was:

[
  {"id":1,"firstName":"Bilbo","lastName":"Baggins","role":"burglar"},
  {"id":2,"firstName":"Frodo","lastName":"Baggins","role":"thief"}
]

## Step 5 — Ensuring Port Forwarding and Connectivity

It was verified that port 8080 was open:

sudo ss -tulpn | grep 8080

Output:
vagrant@ca3-vm:~$ sudo ss -tulpn | grep 8080
tcp   LISTEN 1      100                     *:8080             *:*    users:(("java",pid=7242,fd=68))

This ensures that the Spring Boot server is reachable from the host machine through the Vagrant forwarded port.


## Step 6 — Validation and Results

vagrant up successfully provisions a complete Ubuntu environment.

gradlew build compiles and packages the project.

gradlew bootRun starts the Spring Boot server on port 8080.

Gradle and JDK automatically installed and configured, they are also consistent and reproducible.

REST endpoint /employees responds correctly.

## Why this setup

This solution was build like this because it guarantees full reproducibility, isolation, and automation:

Reproducibility: Vagrant + Gradle Wrapper + JDK Toolchain ensure identical builds.
Isolation: The VM isolates all dependencies, avoiding OS-level conflicts.
Automation: The provisioning script installs everything automatically.
Compatibility: Uses Java 17, supported by Spring Boot 3.x.

This environment can be destroyed (vagrant destroy) and recreated (vagrant up) with the exact same results, which is essential for DevOps workflows.

## Final Commit and Tag

After validation, the repository was updated and tagged:

git add .
git commit -m "CA3 Part1 - Vagrant Environment Setup"
git push origin main
git tag ca3-part1
git push origin ca3-part1


# CA3 – Part 2: Two Virtual Machines with Vagrant

## Project Overview
This part of the assignment implements a virtualized environment using **Vagrant** and **VirtualBox** with two Ubuntu virtual machines:
- **db VM** – runs an **H2 database** in server mode.  
- **app VM** – runs a **Spring Boot REST API** connected to the H2 database.

The goal was to simulate a realistic setup where the application and database run on different servers, with all configuration and deployment steps automated.

---

## System Description

### Architecture
Both machines communicate through a private internal network:
- **db**: `192.168.56.10`
- **app**: `192.168.56.11`

This configuration allows communication between the two VMs while keeping them isolated from the host system.

---

## Implementation Summary

### Vagrantfile
The `Vagrantfile` defines both VMs, assigns IP addresses, and links each VM to its corresponding provisioning script:
- `provision_db.sh` – sets up the H2 database.  
- `provision_app.sh` – installs dependencies, builds, and runs the Spring Boot project.

**Command to start everything:**
```bash
vagrant up
```

Other useful Vagrant commands:
```bash
vagrant ssh db       # Access the database VM
vagrant ssh app      # Access the application VM
vagrant halt         # Stop both VMs
vagrant destroy -f   # Remove both VMs completely
```

---

## Database Provisioning (`provision_db.sh`)

### Step 1 – Update system and install dependencies
Installs Java, firewall tools, and utilities required to run the H2 database.
```bash
sudo apt update -y
sudo apt install -y openjdk-17-jdk ufw wget unzip
```

### Step 2 – Create installation directory and download H2
Creates `/opt/h2` and downloads the H2 jar directly from Maven Central.
```bash
mkdir -p /opt/h2
cd /opt/h2
wget -q https://repo1.maven.org/maven2/com/h2database/h2/2.4.240/h2-2.4.240.jar -O h2.jar
```

### Step 3 – Start H2 in server mode
Runs the H2 database in TCP mode to allow remote connections from the app VM.
```bash
nohup java -cp /opt/h2/h2.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -ifNotExists &
```

### Step 4 – Configure firewall
Allows only the app VM (192.168.56.11) to access the H2 port (9092) and enables UFW.
```bash
sudo ufw allow from 192.168.56.11 to any port 9092 proto tcp
sudo ufw --force enable
```

### Step 5 – Check H2 status
Verifies that the database is active and listening.
```bash
ss -tulpn | grep 9092
```

---

## Application Provisioning (`provision_app.sh`)

### Step 1 – Install required packages
Installs Java 21, Gradle, Git, and utilities for the build process.
```bash
sudo apt update -y
sudo apt install -y openjdk-21-jdk git gradle netcat dos2unix
```

### Step 2 – Clone the project repository
Retrieves the CA2 repository from GitHub.
```bash
cd /home/vagrant
git clone https://github.com/1240598Rafa/cogsi2526-1240598-1240601.git
cp -r cogsi2526-1240598-1240601 /home/vagrant/app
cd /home/vagrant/app/CA2/Part2
```

### Step 3 – Ensure Gradle wrapper is executable
Converts Windows-style line endings and grants execution permissions.
```bash
dos2unix gradlew
chmod +x gradlew
```

### Step 4 – Create the Spring Boot configuration file
Generates `application.properties` with connection details to the H2 server.
```bash
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
```

### Step 5 – Wait for the database to become reachable
Checks if the H2 server is available before building the project.
```bash
echo "Waiting for H2 database..."
until nc -z 192.168.56.10 9092; do
  sleep 2
done
echo "Database is reachable. Proceeding with build."
```

### Step 6 – Build the Spring Boot project
Compiles the project using the Gradle wrapper.
```bash
./gradlew clean build
```

### Step 7 – Run the Spring Boot application
Finds the correct jar file and runs it in the background.
```bash
JAR_FILE=$(find build/libs -name "*.jar" ! -name "*-plain.jar" | head -n 1)
nohup java -jar "$JAR_FILE" > /home/vagrant/app/app.log 2>&1 &
```

---

## Validation and Testing

### 1. Check database connectivity
Ensures that the app VM can connect to the H2 database.
```bash
nc -zv 192.168.56.10 9092
```

### 2. Build verification
Rebuild the project manually to confirm functionality.
```bash
./gradlew clean build
```

### 3. Test REST API endpoint
Access from the host browser:
```
http://192.168.56.11:8080/employees
```

### 4. Persistence check
Stop and restart the environment:
```bash
vagrant halt
vagrant up
```

### 5. Process and logs verification
Inside each VM:
```bash
# On db VM
ps aux | grep h2
ss -tulpn | grep 9092

# On app VM
curl http://localhost:8080/employees
tail -n 20 /home/vagrant/app/app.log
```

---

## Security and Networking
- Both VMs operate within a **private network**, isolated from external access.  
- Firewall rules on the db VM allow access only from the app VM.  
- No ports are exposed to the host machine.  
- SSH access is handled automatically by Vagrant.

---

## Conclusion
This project automates the deployment of a two-VM distributed environment.  
With a single command:
```bash
vagrant up
```
both machines are created, provisioned, configured, and started automatically.
