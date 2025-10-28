# CA3 - Part 1: Vagrant and Gradle Environment

This part of the assignment required the configuration of a reproducible environment using Vagrant and Gradle, so that building and running a Spring Boot application could be automated.
The goal is to ensure that every developer can run the same project under the same conditions — same OS, same JDK, same Gradle version — without having to setup manually.

## Step 1 — Vagrant Environment Creation

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

Explanation:

Box - specifies the base OS image (Ubuntu 22.04, codename jammy).

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

Explanation:

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

This solution was chosen because it guarantees full reproducibility, isolation, and automation:

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

## Summary

This part demonstrated the creation of a fully automated development environment using Vagrant and Gradle for a Spring Boot application.
Through a single vagrant up command, the entire stack — OS, Java, Gradle, and the project — becomes ready for execution, ensuring consistency, reproducibility, and ease of collaboration.