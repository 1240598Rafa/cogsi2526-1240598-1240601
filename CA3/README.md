# CA3 - Part 1: Vagrant and Gradle Environment

This part of the assignment required the configuration of a reproducible environment using Vagrant and Gradle, so that building and running a Spring Boot application could be automated.
The goal is to ensure that every developer can run the same project under the same conditions - same OS, same JDK, same Gradle version - without having to setup manually.

## Step 1 - Vagrant Environment Creation

It was requested to:

“Use Vagrant to define and provision a virtual machine with Ubuntu and all tools needed to build and run the project.”

So a new directory was created as /CA3/Part1/:
mkdir /CA3/Part1/

Then a Vagrantfile was created in the /CA3/Part1/ folder with the following configuration:

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

## Step 2 - Provisioning Script

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

## Step 3 - Launching and Verifying the VM

The following commands were used on the host:

vagrant up
vagrant ssh


## Step 3.1 – Vagrant Provisioning and Gradle Verification

To confirm that the Vagrant provisioning script installed all required tools correctly, we can run:

vagrant up --provision

Which will show the installed Git, OpenJDK, Gradle and Maven, it will also clon or update the project repository.

Or the following verifications can also be done inside the VM:

### Check Java installation
```bash
java -version
gradle -v
```

Output confirmed:

openjdk version "17.0.16"
Gradle 8.7

This validates that both JDK and Gradle were correctly installed and added to the system PATH via the provisioning script.

## Step 4 - Building and Running the Spring Boot Project

In case the provision.sh is runned automatically
cd /vagrant
sudo bash provision.sh
or
git clone https://github.com/1240598Rafa/cogsi2526-1240598-1240601.git project

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

To test the Chat Application we go to CA2/Part1:

./gradlew runServer

And to verify if it is working we can do 2 ways:
sudo ss -tulpn | grep 59001
or
We start a connection on the host:
.\gradlew.bat runClient

And by connecting to localhost:59001 the connection should be redirected to the VM and give the following output:

Connected to chat server on port 59001

Unfortunately this was tested several times but maybe for lack of resources (even though they were upgraded on Vagrantfile) we couldn't get the results we wanted. 

## Step 5 - Ensuring Port Forwarding and Connectivity

It was verified that port 8080 was open:

sudo ss -tulpn | grep 8080

Output:
vagrant@ca3-vm:~$ sudo ss -tulpn | grep 8080
tcp   LISTEN 1      100                     *:8080             *:*    users:(("java",pid=7242,fd=68))

This ensures that the Spring Boot server is reachable from the host machine through the Vagrant forwarded port.


## Step 6 - Validation and Results

vagrant up successfully provisions a complete Ubuntu environment.

gradlew build compiles and packages the project.

gradlew bootRun starts the Spring Boot server on port 8080.

Gradle and JDK automatically installed and configured, they are also consistent and reproducible.

REST endpoint /employees responds correctly.

## Step 7 - Automated Provisioning with Envrionment Variables

It was also requested to:
"Automate the cloning, building, and starting of applications
▪ Use environment variables to control whether specific steps (like repo
cloning or service start-up) should be executed when provisioning"

To implement this, the provision.sh script was updated to include three key variables:
```bash
CLONE_REPO=${CLONE_REPO:-true}
BUILD_APPS=${BUILD_APPS:-true}
RUN_APPS=${RUN_APPS:-false}
```

Explanation of these variables:

CLONE_REPO: controls whether the Git repository should be cloned or updated.

BUILD_APPS: determines if Gradle should build the applications automatically.

RUN_APPS: controls whether the applications (Chat Server and Spring Boot) should start automatically after provisioning.

This variables allow flexible automation.
This setup automatically clones or updates repositories, builds both applications and starts the chat server and spring boot REST APi.

The following code was also added 

### Code Extract Stage

```bash
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
```

This code will check wheter the repository already exists inside /home/vagrant, and if it does it will do a 'git pull' to update it.
Otherwise it will perform a fresh clone.

Also if CLONE_REPO is set to false it will just skip this step entirely

### Build Stage

```bash
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
```
This block of code compiles both applications automatically using Gradle, making sure all dependencies are downloaded inside the VM.

### Execution Stage

```bash
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
```

Both applications are launched in the background using nohup, allowing the provisioning to complete without being blocked.

The logs are then stored on:
/home/vagrant/server.log
/home/vagrant/spring.log

## Step 8 - Persistent H2 Database Configuration

Here it was asked to:
"Ensure the H2 database in the VM retains data across restarts
▪ In the VM's provisioning script, configure the H2 database to store data on
disk, using a synced folder between the VM and the host machine for
persistent storage
▪ You must create or modify the application.properties
configuration file to specify the correct database URL"

To meet this requirements of ensuring that H2 retains data across restarts, the Vagrant file and the Spring boot configuration were updated

On the Vagrant file we added:
config.vm.synced_folder "../h2data", "/home/vagrant/h2data"

This mounts a persistent folder from the host (../h2data) into the VM at /home/vagrant/h2data.
Any database file created by H2 in that location will survive VM restarts and is also accessible on the host because Vagrant creates a bidirectional sync, so any file 
created on the host will be replicated to the VM, and vice versa.

For the H2 database configuration, a file application.properties was then created with the following commands:

spring.datasource.url=jdbc:h2:file:/home/vagrant/h2data/appdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console

Explanation for this file:

The application.properties is the main configuration file of Spring Boot application.

jdbc:h2:file:/home/vagrant/h2data/appdb - Tells Spring Boot where the data base is on the VM.

DB_CLOSE_DELAY=-1 - Keeps the data base open in memory while the Java process is active

DB_CLOSE_ON_EXIT=FALSE - prevent H2 from wiping the database when the app stops.

spring.datasource.driverClassName=org.h2.Driver - Defines the JDBC driver to use

spring.jpa.database-platform=org.hibernate.dialect.H2Dialect - Tells the Hibernate(Java Framework) that it's using H2, adjusting the generated SQL

spring.h2.console.enabled=true - activates the web console for debugging.

spring.h2.console.path=/h2-console - defines the endpoint


Any H2 database files created under /home/vagrant/h2data are physically stored on the host in ../h2data.
So with the addition of that command to the Vagrant file and the addition of the application.properties file we can now ensure persistence even after vagrant halt or
vagrant destroy, since the data is not erased with the virtual machine.


## Step 9 - Final Commit and Tag

After validation, the repository was updated and tagged:

git add .
git commit -m "CA3 Part1 - Vagrant Environment Setup"
git push origin main
git tag ca3-part1
git push origin ca3-part1


# CA3 - Part 2: Two Virtual Machines with Vagrant

## Project Overview
This part of the assignment implements a virtualized environment using **Vagrant** and **VirtualBox** with two Ubuntu virtual machines:
- **db VM** - runs an **H2 database** in server mode.  
- **app VM** - runs a **Spring Boot REST API** connected to the H2 database.

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
- `provision_db.sh` - sets up the H2 database.  
- `provision_app.sh` - installs dependencies, builds, and runs the Spring Boot project.

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

### Step 1 - Update system and install dependencies
Installs Java, firewall tools, and utilities required to run the H2 database.
```bash
sudo apt update -y
sudo apt install -y openjdk-17-jdk ufw wget unzip
```

### Step 2 - Create installation directory and download H2
Creates `/opt/h2` and downloads the H2 jar directly from Maven Central.
```bash
mkdir -p /opt/h2
cd /opt/h2
wget -q https://repo1.maven.org/maven2/com/h2database/h2/2.4.240/h2-2.4.240.jar -O h2.jar
```

### Step 3 - Start H2 in server mode
Runs the H2 database in TCP mode to allow remote connections from the app VM.
```bash
nohup java -cp /opt/h2/h2.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -ifNotExists &
```

### Step 4 - Configure firewall
Allows only the app VM (192.168.56.11) to access the H2 port (9092) and enables UFW.
```bash
sudo ufw allow from 192.168.56.11 to any port 9092 proto tcp
sudo ufw --force enable
```

### Step 5 - Check H2 status
Verifies that the database is active and listening.
```bash
ss -tulpn | grep 9092
```

---

## Application Provisioning (`provision_app.sh`)

### Step 1 - Install required packages
Installs Java 21, Gradle, Git, and utilities for the build process.
```bash
sudo apt update -y
sudo apt install -y openjdk-21-jdk git gradle netcat dos2unix
```

### Step 2 - Clone the project repository
Retrieves the CA2 repository from GitHub.
```bash
cd /home/vagrant
git clone https://github.com/1240598Rafa/cogsi2526-1240598-1240601.git
cp -r cogsi2526-1240598-1240601 /home/vagrant/app
cd /home/vagrant/app/CA2/Part2
```

### Step 3 - Ensure Gradle wrapper is executable
Converts Windows-style line endings and grants execution permissions.
```bash
dos2unix gradlew
chmod +x gradlew
```

### Step 4 - Create the Spring Boot configuration file
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

### Step 5 - Wait for the database to become reachable
Checks if the H2 server is available before building the project.
```bash
echo "Waiting for H2 database..."
until nc -z 192.168.56.10 9092; do
  sleep 2
done
echo "Database is reachable. Proceeding with build."
```

### Step 6 - Build the Spring Boot project
Compiles the project using the Gradle wrapper.
```bash
./gradlew clean build
```

### Step 7 - Run the Spring Boot application
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


# Alternative Solution - Using Multipass

## Overview
An alternative to **Vagrant** for creating and managing virtualized environments is **Multipass**, developed by Canonical (the creators of Ubuntu).  
Multipass provides a lightweight command-line interface for launching and managing Ubuntu virtual machines quickly, with far less overhead than Vagrant.  
It integrates directly with virtualization backends such as **QEMU**, **Hyper-V**, or **VirtualBox**, depending on the host system.

Using Multipass, the same two-machine setup from this project (application and database) can be implemented efficiently, maintaining separation of services and automation of provisioning.

## Comparison: Multipass vs Vagrant

| Feature | Vagrant (Base Solution) | Multipass (Alternative) |
|----------|------------------------|-------------------------|
| **Type** | Full virtual machines managed by VirtualBox | Lightweight Ubuntu VMs managed directly by Multipass |
| **Performance** | Slightly slower (depends on VirtualBox) | Faster boot time, optimized for Ubuntu images |
| **Provisioning** | Shell scripts or configuration management tools | Cloud-init scripts or inline provisioning commands |
| **Networking** | Manual network configuration via VirtualBox | Simple `--network` flag for private or bridged networks |
| **Storage** | Synced folders or local disk mounts | Native mounting with `multipass mount` |
| **Ease of Use** | Requires Vagrantfile setup | Simple CLI commands for VM lifecycle |
| **Portability** | Works with many OS images | Optimized for Ubuntu-based environments |

## Design of the Alternative Solution

The environment would consist of two Ubuntu instances created using **Multipass**:
- `db-instance` - runs the **H2 database** in TCP server mode.  
- `app-instance` - runs the **Spring Boot REST API** that connects to the H2 database.

Each instance would be provisioned using initialization scripts (`cloud-init` files) that automate software installation and configuration.

---

## Step-by-Step Design

### Installing Multipass

winget install Canonical.Multipass

You might need to adjust the Path variable after

Use the following command to make sure it's working:

multipass version

### Launching an Ubuntu VM
Instead of defining a Vagrant file, we use a single command:

multipass launch --name ca3-vm --cpus 2 --mem 2G --disk 10G jammy

--name - defines the VM name
--cpus, --mem, --disk - defines resources limits
jammy - defines the Ubuntu version

multipass list - can be used to list all running instances

To access the shell we use:
multipass shell ca3-vm

### Provisioning Script
We can pass a provisioning script using --cloud-init or local script, we will reuse the same setup logic from provision.sh

To do so we use the following command if we want to create a VM from scratch:
multipass launch --name ca3-vm --cpus 2 --mem 2G --disk 10G jammy --cloud-init provision.sh

Taking into account we already had the ca3-vm created we copy the files to the vm with:
multipass transfer provision.sh ca3-vm:/home/ubuntu/provision.sh

Then we go to the VM:
multipass shell ca3-vm

Once inside it we do:
chmod +x provision.sh
sudo bash provision.sh

Before executing it in the Multipass VM, environment variables control which stages to perform:

```bash
export CLONE_REPO=true
export BUILD_APPS=true
export RUN_APPS=false
sudo bash provision.sh
```
This gives flexibility to skip clone, build, or execution during reprovisioning.

### Persistent Storage with Multipass
To share folders, Vagrant uses synced_folder, but Multipass mounts it manually.

To make the H2 database persistent (equivelant of ../h2data) we can do on our host:

mkdir C:\Users\xxx\Desktop\h2data

Then we mount it inside the VM:

multipass mount "C:\Users\xxx\Desktop\h2data" ca3-vm:/home/ubuntu/h2data

Now any data written to /home/ubuntu/h2data inside the VM is saved to your Windows folder permanently.

### Running and Verifying the Project
Inside the VM we run:
multipass shell ca3-vm
cd /home/ubuntu/project/CA2/Part2
./gradlew bootRun

Then open on the host the http://localhost:8080/employees

To persist the database, we must ensure application.properties points to spring.datasource.url=jdbc:h2:file:/home/ubuntu/h2data/appdb

We can then restart the VM and the data will remain there

### Launch Two VMs
multipass launch jammy --name db-vm --cpus 1 --memory 1G --disk 5G
multipass launch jammy --name app-vm --cpus 2 --memory 2G --disk 10G

app-vm: runs the Spring Boot REST API

db-vm: hosts the H2 database in server mode (port 9092)

### Configure SSH keys for secure access
Secure SSH access was implemented via custom RSA keys to replace default credentials.

On the host:
ssh-keygen -t rsa -b 4096 -f my_ca3_key -N ""

Then we copy the public key to both VMs:
multipass transfer my_ca3_key.pub db-vm:/home/ubuntu/
multipass transfer my_ca3_key.pub app-vm:/home/ubuntu/

Inside each VM we should run the following commands in order to change the permissions of each file:
multipass shell db-vm (app-vm)
mkdir -p ~/.ssh
cat ~/my_ca3_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit

Now we can safelly access through:
ssh -i my_ca3_key ubuntu@<VM_IP>

### Provisioning for both VMs
DB VM:

multipass transfer provision.sh db-vm:/home/ubuntu/provision.sh
multipass shell db-vm
sudo bash provision.sh
sudo apt install -y h2database ufw

APP VM:

multipass transfer provision.sh app-vm:/home/ubuntu/provision.sh
multipass shell app-vm
sudo bash provision.sh

### Configure H2 in server mode for DB VM
cd /usr/share/h2/bin
nohup java -cp h2*.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -ifNotExists > /home/ubuntu/h2.log 2>&1 &

This will execute H2 in server mode, listening on port 9092 that is used by the application

### Add Firewall rules

Get the IP of the VM:
multipass info app-vm

Configure ufw in the DB VM
sudo ufw allow from <VM_IP> to any port 9092
sudo ufw enable
sudo ufw status

### Configure Spring Boot in APP VM
Inside the VM APP we open the applciation.properties and change the commands to:

spring.datasource.url=jdbc:h2:tcp://<VM_IP>:9092/~/appdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.hibernate.ddl-auto=update


### Startup Check on VM APP

Before we start Spring Boot, the app should wait that H2 is active, so directily on provision.sh of the VM APP we can add:
until nc -z <VM_IP> 9092; do
  echo "Waiting for H2 database..."
  sleep 3
done

Then on the VM we run:

cd /home/ubuntu/project/CA2/Part2
nohup ./gradlew bootRun > /home/ubuntu/spring.log 2>&1 &

### Verification

We execute http://localhost:8080/employees which should connecto to H2 remotely

To make sure the connection is active we do:
multipass shell db-vm
sudo ss -tulpn | grep 9092


------

### Networking
Multipass automatically places both instances on the same internal virtual network.
They can communicate using their instance names (e.g., db-instance) without any manual configuration.
For advanced scenarios, a bridged network can be created using:
```bash
multipass networks
multipass launch --network bridge0 ...
```

### Advantages of Multipass
Native Ubuntu support - optimized and lightweight Ubuntu VMs.

Simplified provisioning - uses cloud-init at launch.

Faster startup - near-instant instance creation.

Built-in management tools - multipass list, shell, exec, etc.

Automatic networking - instances connect immediately without VirtualBox adapters.

### Limitations:
Only supports Ubuntu-based operating systems.

Less flexibility for multi-OS environments.

Smaller ecosystem compared to Vagrant.

### Conclusion
Multipass provides a simpler, faster, and lighter-weight alternative to Vagrant.
It automates the creation and provisioning of Ubuntu-based virtual machines using cloud-init scripts and allows both the database and application to be configured automatically.
For projects like this one, Multipass achieves the same goals as Vagrant with improved performance and ease of use.