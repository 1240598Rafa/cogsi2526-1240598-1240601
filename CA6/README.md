# CA6 - Jenkins
# Part 1: Blue–Green Deployment with Vagrant, Ansible, Jenkins & Spring Boot

This project implements Week 1 of CA6, whose objective is to build an automated Continuous Delivery pipeline using:

Vagrant + VirtualBox (infrastructure provisioning)
Ansible Local (configuration management)
Spring Boot Gradle application
Jenkins Declarative Pipeline (CI/CD)
Blue–Green Deployment strategy
Rollback mechanism
Git tags to mark stable builds
Two virtual machines (blue and green) are used to simulate a real production environment where deployments occur safely with minimal downtime.

## Project Architecture Overview

Week 1 requires implementing a fully automated deployment flow:

blue VM (192.168.56.10)
Receives the initial deployment and acts as the active environment.

green VM (192.168.56.11)
Only used after a manual approval in the Jenkins pipeline.
Intended to become the next active environment.

Assignment Requirement:
Both VMs must run inside a single host using Vagrant
The same Spring Boot application should run on both
Deployment must be executed via Ansible
A CI/CD pipeline must orchestrate build - test - deploy - approval - deploy to green
A rollback mechanism must be available

Implementation Summary:

Infrastructure created using a Vagrantfile
Deployment scripts created as Ansible playbooks
Rollback implemented via Ansible with a second JAR file
Jenkins pipeline automates all steps
Health-checks performed via curl
Stable builds are tagged in GitHub

## Vagrant Environment (Infrastructure Layer)

This Vagrant file defines both blue and green machines with:

Ubuntu Focal 20.04
Host-only networking
Fixed IPs
2 vCPUs and 2 GB RAM
Local Ansible provisioning

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.boot_timeout = 600

  ### BLUE
  config.vm.define "blue" do |blue|
    blue.vm.hostname = "blue"
    blue.vm.network "private_network", ip: "192.168.56.10"
    blue.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end
    blue.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "/vagrant/ansible/deploy-blue.yml"
      ansible.inventory_path = "/vagrant/ansible/hosts"
    end
  end

  ### GREEN
  config.vm.define "green" do |green|
    green.vm.hostname = "green"
    green.vm.network "private_network", ip: "192.168.56.11"
    green.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end
    green.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "/vagrant/ansible/deploy-green.yml"
      ansible.inventory_path = "/vagrant/ansible/hosts"
    end
  end
end

## Spring Boot Application (Application Layer)

It was then asked to build a simple REST service (/greeting) using Gradle, packaged into a runnable JAR, and deployed to both VMs.

The Spring Boot project resides in:
CA6/Part1/spring-app/

It contains:
GreetingController
Gradle wrapper
Systemd service unit (installed via Ansible)

Build command:
cd spring-app
./gradlew clean build

Generated JAR:
spring-app/build/libs/rest-service-0.0.1-SNAPSHOT.jar

## Ansible Playbooks (Configuration Layer)

The assignment requires to create a ansible playbook to provision the VMs

Installing Java
Copying the built application
Creating the application directory
Running the service as systemd
Implementing a rollback mechanism

All playbooks are located in:
CA6/Part1/ansible/

### deploy-blue.yml

Deployment to the blue VM during initial provisioning.

- hosts: blue
  become: yes
  tasks:
    - name: Install Java
      apt:
        name: openjdk-11-jre
        state: present
        update_cache: yes

    - name: Create /opt/spring-app
      file:
        path: /opt/spring-app
        state: directory

    - name: Copy JAR
      copy:
        src: /vagrant/spring-app/build/libs/rest-service-0.0.1-SNAPSHOT.jar
        dest: /opt/spring-app/app.jar

    - name: Install systemd service
      copy:
        src: /vagrant/ansible/spring.service
        dest: /etc/systemd/system/spring-app.service

    - name: Start service
      systemd:
        name: spring-app
        enabled: yes
        state: started

### deploy-green.yml

- hosts: green
  become: yes
  tasks:
    - name: Install Java
      apt:
        name: openjdk-17-jre-headless
        state: present
        update_cache: yes

    - name: Create app directory
      file:
        path: /opt/app
        state: directory

    - name: Copy JAR
      copy:
        src: ../spring-app/build/libs/rest-service-0.0.1-SNAPSHOT.jar
        dest: /opt/app/app.jar
        mode: '0755'

    - name: Create systemd service
      copy:
        dest: /etc/systemd/system/spring-app.service
        content: |
          [Unit]
          Description=Spring App

          [Service]
          ExecStart=/usr/bin/java -jar /opt/app/app.jar
          Restart=always

          [Install]
          WantedBy=multi-user.target

    - name: Reload systemd
      command: systemctl daemon-reload

    - name: Start service
      systemd:
        name: spring-app
        enabled: yes
        state: restarted


### rollback-green.yml

It was asked to provide the ability to revert to a previous version.

A rollback JAR is placed in:
CA6/Part1/rollback/rest-service-rollback.jar

Playbook:

- hosts: green
  become: yes

  tasks:
    - name: Stop current service
      systemd:
        name: spring-app
        state: stopped

    - name: Replace JAR with rollback version
      copy:
        src: /vagrant/rollback/rest-service-rollback.jar
        dest: /opt/spring-app/app.jar
        force: yes

    - name: Start service
      systemd:
        name: spring-app
        state: started

    - name: Health check
      uri:
        url: http://localhost:8080/greeting
      register: result
      retries: 5
      delay: 3
      until: result.status == 200

## Jenkins Pipeline (CI/CD Layer)

It was asked to create a pipeline with the following stages:

- SCM checkout
- Build with Gradle
- Execute tests
- Archive artifacts
- Deploy to blue
- Manual approval
- Deploy to green
- Health-check
- Tag stable version in GitHub

The Jenkinsfile implements all required steps.

Pipeline Breakdown

Checkout:
Pulls repository into Jenkins workspace.

Assemble:
Runs the Gradle build:
./gradlew clean build

Test:
Executes unit tests and publishes JUnit results.

Archive:
Stores JARs inside Jenkins.

Deploy to Production
input "Deploy to GREEN VM?"

After the user approves:
vagrant provision green

Health-Check
Performed via:
curl -s -o /dev/null -w "%{http_code}" http://192.168.56.11:8080/greeting

Tag Stable Build:
git tag ca6-part1
git push origin ca6-part1

## Commands to Run the Project Manually
Start VMs:
vagrant up blue
vagrant up green --no-provision

Re-provision blue:
vagrant provision blue

Re-provision green:
vagrant provision green

Test Application
Blue:
curl http://192.168.56.10:8080/greeting

Green:
curl http://192.168.56.11:8080/greeting

Execute Rollback:
cd ansible
sudo ansible-playbook rollback-green.yml -i hosts

Run Jenkins Pipeline:
Click Build Now on Jenkins page.

## Stable Build Tagging

It was required tagging successful builds using a clear semantic naming convention, ensuring that only builds that pass:

Build
Test
Deployment
Production health-check

can be considered “stable”.

Tags follow the format:
stable-v<major>.<minor>

Examples:
stable-v1.0
stable-v1.1
stable-v2.0


Jenkins increments the minor version automatically

Major version can be manually changed when breaking changes are introduced

Tags are pushed automatically to GitHub only for successful pipelines.

## Pipeline Notifications

The pipeline must output a notification summarizing the final status of execution.

At the end of the Jenkins pipeline, a notification step prints:

Pipeline completed successfully.
Build tagged as stable-vX.Y.

or, in case of failure:

Pipeline failed during <stage>.
No stable tag created.


This provides immediate visibility into the pipeline’s success or failure.

## Deployment Verification (Health Check)

After deploying the application to the green VM, the pipeline must automatically:

Validate that the service is running
Send a real HTTP request to /greeting
Fail the pipeline if the response is not HTTP 200

We added a Jenkins stage:
curl -s -o /dev/null -w "%{http_code}" http://192.168.56.11:8080/greeting

The pipeline:
Retries the check
Fails if not 200
Only tags the build as stable if successful

## Git Tag for Submission

git tag ca6-week1
git push origin ca6-week1