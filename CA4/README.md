# Alternative Solution – Using SaltStack
## Overview
SaltStack automates the deployment and configuration of both virtual machines (app and db) by defining desired states rather than executing ad-hoc commands.
It uses a lightweight agent model (minions) that communicate with a central master via ZeroMQ, allowing parallel execution and continuous state enforcement.
This makes it a great alternative to Ansible.

## Alternative Tools Compared with Ansible
| **Tool**           | **Architecture**                        | **Strengths**                                                    | **Weaknesses**                                     | **Ideal Use Case**                                                   |
| ------------------ | --------------------------------------- | ---------------------------------------------------------------- | -------------------------------------------------- | -------------------------------------------------------------------- |
| **SaltStack**      | Master–minion or agentless (*salt-ssh*) | High speed (ZeroMQ), event-driven automation, strong idempotence | Requires daemon on each VM if not using *salt-ssh* | Large or long-lived infrastructures needing continuous configuration |
| **Puppet**         | Master–agent                            | Mature ecosystem, declarative DSL, great reporting               | Slower convergence, steeper learning curve         | Enterprises maintaining strict compliance baselines                  |
| **Chef**           | Master–agent (*Ruby DSL*)               | Fine-grained control, test-driven infrastructure                 | Requires Ruby, verbose recipes                     | Complex deployments needing procedural logic                         |
| **Terraform**      | Agentless, push-based via APIs          | Excellent for infrastructure provisioning (VMs, cloud)           | Not intended for OS-level config management        | Multi-cloud or hybrid environment provisioning                       |
| **Ansible (base)** | Agentless via SSH                       | Easy to learn, no agents, YAML playbooks                         | Sequential execution can be slow on many nodes     | Small to medium environments or ephemeral setups                     |


SaltStack was chosen because it best combines idempotent configuration, high execution speed, and compatibility with Vagrant-based Ubuntu VMs.
It achieves the same functional goals as Ansible, automated provisioning, configuration, and verification, but provides faster parallel runs and a more declarative state model.

## Step-by-Step Implementation with SaltStack
### Introduction

Now we will show how the alternative was implemented.
The objective was to replicate the same behavior implemented in CA3 - deploying a Spring Boot application connected to an H2 database - but now orchestrated 
with SaltStack inside the Vagrant virtual environment.

### Environment Setup

The Vagrant environment from CA3 was reused, containing two VMs:

db	Database Server (H2)	192.168.56.10	cogsidb
app	Application Server (Spring Boot)	192.168.56.11	cogsiapp

Both were created using the Vagrantfile present on CA4:

Vagrant.configure("2") do |config|
  config.vm.boot_timeout = 600

  config.vm.define "db" do |db|
    db.vm.box = "ubuntu/focal64"
    db.vm.hostname = "cogsidb"
    db.vm.network "private_network", ip: "192.168.56.10"
  end

  config.vm.define "app" do |app|
    app.vm.box = "ubuntu/focal64"
    app.vm.hostname = "cogsiapp"
    app.vm.network "private_network", ip: "192.168.56.11"
  end
end

Comparing to the Vagrantfile from CA3 Part2, we removed app.vm.provision "shell", path: "provision_app.sh" because it was no longer needed since it will now be automate.

Start both machines:

vagrant up --provider virtualbox

### SSH Key Configuration

OpenSSH Server didn't need to be installed since it is installed on Ubuntu by default

#### Enable passwordless SSH between VMs

From the APP VM, we initially tested connectivity to the DB VM using:

ssh vagrant@192.168.56.10

Permission denied (publickey)

This happend because even though each VM could SSH from the host, the APP VM couldn't SSH into the DB VM directly.
That only happend because the default Vagrant SSH key wasn't shared between them.

To fix it we generated the SSH keys inside the VM APP:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

Which created 2 files, a public key on ~/.ssh/id_rsa.pub and a private on ~/.ssh/id_rsa
Because ssh-copy-id failed, we copied it manually:
cat ~/.ssh/id_rsa.pub

Then on the DB VM we opened the authorized keys file:
sudo nano /home/vagrant/.ssh/authorized_keys 
And pasted the public key from the APP VM

Afterward we adjusted the permissions:
chmod 600 ~/.ssh/id_rsa
chown vagrant:vagrant ~/.ssh/id_rsa

Then ran, to test if we could connecto from APP VM to DB VM using SSH:
ssh vagrant@192.168.56.10

Which worked without using a password, confirming that the key-based configuration was correct.
This step was crucial because salt-ssh depends entirely on passwordless SSH access between nodes.

### Installing and Preparing SaltStack
#### Installing SaltStack via pip

Installing Salt directly from the repository failed due to DNS resolution issues (repo.saltproject.io could not resolve).
Therefore, it was installed using pip:

sudo apt update
sudo apt install python3-pip -y
pip install salt-ssh

After installation, SaltStack binaries were not yet available in the system PATH.
To fix it we did:

echo 'export PATH="$PATH:/home/vagrant/.local/bin"' >> ~/.bashrc
source ~/.bashrc

Then confirmed:

salt-ssh --version
Output: salt-ssh 9000

### Configuring SaltStack
#### Directory structure

The Salt configuration was manually created to simulate a typical master/minion layout:

sudo mkdir -p /srv/salt/app /srv/salt/db /srv/salt/system /srv/salt/files
sudo mkdir -p /home/vagrant/salt_config/{etc,cache,logs,pki}

#### Master configuration

We used:
sudo nano /home/vagrant/salt_config/etc/master

To modify the master file, which contains:

cachedir: /home/vagrant/salt_config/cache
log_file: /home/vagrant/salt_config/logs/salt.log
file_roots:
  base:
    - /srv/salt

Cachedir - indicates that the cache will be written to /home/vagrant/salt_config/cache, instead of the default /var/cache/salt since this directory required root privileges.

Log_File - defines where the logs will be saved

File_Roots - tells Salt where the state files are located (.sls).

This defines where Salt stores cached data, logs, and where it will read the .sls state files from.
This file acts as a local configuration for Salt-SSH, it replaces the role of a running "Salt master" service, keeping everything under our control as a single user.

### Creating the Roster

Since SaltStack doesn't use an inventory of hosts file like Ansible, it uses a roster file which tells Salt-SSH which machines to manage, how to connect 
to them and wheter to use sudo or not.
The file was created on:
sudo nano /etc/salt/roster

Because it's the default path where Salt will look for it.

Content:

app:
  host: 192.168.56.11
  user: vagrant
  sudo: True
  priv: /home/vagrant/.ssh/id_rsa

db:
  host: 192.168.56.10
  user: vagrant
  sudo: True
  priv: /home/vagrant/.ssh/id_rsa

host - will define the IP address for each VM;
user - defines the ssh user to connect as;
sudo - will state either True or False, if true it will execute privileged operations automatically;
priv - path to the private SSH key configuration

Then moved to the correct configuration folder:

mv /etc/salt/roster /home/vagrant/salt_config/etc/roster

This way we have all the configuration file all under the same project directory.

### Writing State Files (.sls)
#### What are state files?

Each .sls file in SaltStack defines the desired state of a system - what should be installed, configured, or running.
They are declarative, like Ansible playbooks.
When Salt executes state.apply, it reads these files and ensures the system matches the definitions.
All .sls files were placed under:
/srv/salt/

because this is the directory referenced in file_roots (defined in the master file).
This hierarchy was chosen because it mirrors professional infrastructure-as-code layout:

/srv/salt/
 ├── app/
 ├── db/
 ├── system/
 └── files/

Each folder represents a logical component of the environment - application layer, database layer, and base system configuration

#### top.sls
Located on:
sudo nano /srv/salt/top.sls

This file acts as the entry point, linking each machine to the states it should apply.

base:
  'app':
    - app.spring_app
    - system.pam
    - system.health
  'db':
    - db.h2db
    - system.pam
    - system.health

The environment base means default.
App and DB are the hostnames, this was there were also matching the roster entries.
For each machine it was defined which .sls files apply to it.
The APP will run applications setup, while the DB will run database setups.

#### app/spring_app.sls

The spring_app state handles the Java installation, Spring Boot application deployment, and execution.

install_java:
  pkg.installed:
    - name: openjdk-21-jdk

This will ensure that java is installed.

ensure_opt_dir:
  file.directory:
    - name: /opt/spring-app
    - user: vagrant
    - group: vagrant
    - mode: 755

This commands will ensure the directory for the application exists.

The 'ensure_opt_dir' was later changed to:
file.directory:
  - name: /opt/spring-app
  - user: devuser
  - group: developers
  - mode: 750

This way it makes them readable and writable only by members of the developers group.

clone_project:
  git.latest:
    - name: https://github.com/spring-guides/gs-rest-service.git
    - target: /opt/spring-app
    - require:
      - pkg: install_java

Here it clones the official Spring REST demo repository, these commands need to be placed after the Java installation.

build_project:
  cmd.run:
    - name: ./gradlew build
    - cwd: /opt/spring-app/complete
    - require:
      - git: clone_project

The application will be compiled with Gradle.

create_dev_group:
  group.present:
    - name: developers

Creates the developers group.

create_dev_user:
  user.present:
    - name: devuser
    - groups:
      - developers

Creates the devuser and adds it to the developers group.

run_app:
  cmd.run:
    - name: nohup java -jar /opt/spring-app/complete/build/libs/rest-service-0.0.1-SNAPSHOT.jar &
    - cwd: /opt/spring-app/complete
    - unless: pgrep -f rest-service

To end this file, it will run the app in the background, nohup was used so it stays running even after Salt exits.
The unless condition prevents duplicate launches.

This file installs Java, deploys the app, builds it, creates the required user/group, and starts the service.

#### db/h2db.sls

This file defines setup for the H2 database server.

install_java:
  pkg.installed:
    - name: openjdk-21-jdk

Installs Java

download_h2:
  cmd.run:
    - name: |
        mkdir -p /opt/h2 &&
        wget -q https://h2database.com/h2-2022-11-13.zip -O /opt/h2/h2.zip &&
        apt-get install -y unzip &&
        unzip -o /opt/h2/h2.zip -d /opt/h2/
    - cwd: /opt/h2
    - require:
      - pkg: install_java

Downloads and extracts H2 manually because it’s not available via apt.

create_dev_group:
  group.present:
    - name: developers

Creates the developers group.

create_dev_user:
  user.present:
    - name: devuser
    - groups:
      - developers

Creates the devuser and adds it to the developers group.

start_h2:
  cmd.run:
    - name: nohup java -cp /opt/h2/bin/h2*.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -ifNotExists &
    - cwd: /opt/h2
    - unless: pgrep -f org.h2.tools.Server

Starts the H2 TCP server in the background on port 9092.
The 'unless' commands is used to avoid multiple instances started.

This file installs Java, downloads and extracts the H2 database, creates the same user and group, and launches H2 in background mode.
Both machines share identical user/group setup to ensure consistent permissions and access for potential shared files or development operations.

#### system/pam.sls

This file enforces password security policy, ensuring pwquality.conf matches a version stored under /srv/salt/files that way we simulate a system hardening policy.

/etc/security/pwquality.conf:
  file.managed:
    - source: salt://files/pwquality.conf
    - user: root
    - group: root
    - mode: 644

This commands tell Salt to copy the file from the source to the /etc/security directory , it also sets the owner as root and the necessary file permissions on both VMs since
it was added on both nodes on file top.sls.
This way when salt-ssh -c /home/vagrant/salt_config/etc '*' state.apply is runned, the PAM file will be automaticaly created.

#### system/health.sls

This file executes health checks to confirm both services are running correctly.

check_app:
  cmd.run:
    - name: curl -f http://localhost:8080/actuator/health || echo "App not running"

check_db_port:
  cmd.run:
    - name: ss -tulpn | grep 9092 || echo "DB not listening"

The first uses Spring’s /actuator/health endpoint.

The second checks if H2 is listening on TCP port 9092.

#### Testing Salt-SSH connectivity

To test the Salt-SSH we used:

salt-ssh -c /home/vagrant/salt_config/etc '*' test.ping

After fixing SSH permissions and ownership, it returned:

app:
    True
db:
    True

### Applying the Configuration
After multiple fixes we can run:
salt-ssh -c /home/vagrant/salt_config/etc '*' state.apply

This command will run the master configuration file which will then run the files under /srv/salt.
All those files togheter are ablet to produce a full deployment.

#### Errors and Fixes

Permission denied /var/cache/salt	Salt tried to write to system cache	
Added custom cachedir in /home/vagrant/salt_config

Could not find or load main class org.h2.tools.Server	H2 zip extraction incomplete	
Added explicit unzip command

### Verifying Deployment
#### Checking running services
sudo lsof -i :8080
This shows Java process listening on port 8080

#### Testing Spring Boot
curl http://localhost:8080

Expected output is:

{"timestamp":"2025-11-06T20:05:09.565+00:00","status":404,"error":"Not Found","path":"/"}

This confirms that the Spring Boot server is running successfully.

### Conclusions

The implementation proved SaltStack can fully replace Ansible for configuration management within the Vagrant environment.
Salt-SSH required extra configuration (cache path, SSH trust, roster permissions) but ultimately achieved full automation.
The workflow is now entirely agentless, this means Salt remotely configures both VMs using SSH keys.
The final state deployment confirms successful orchestration of both the database and the application layer.
With the use of
salt-ssh -c /home/vagrant/salt_config/etc '*' state.apply full_setup
we can make our setup reproducible and automatic using a YAML setup which was structured under /srv/salt directory.

## Advantages of SaltStack in this Context

Faster parallel provisioning of both VMs through ZeroMQ.
Continuous state enforcement (automatic remediation).
Clean separation of declarative state files (.sls).
Same Vagrant environment reused with minimal changes.

## Limitations

Slightly higher initial setup (roster or minion keys).
Requires understanding of YAML and Jinja templating.

## Final Conclusion
SaltStack provides a fully equivalent alternative to Ansible for CA4 Week 1, achieving the same deployment and configuration goals while offering faster,
event-driven execution and long-term state management.
Using the existing Vagrant VMs from CA3, all configuration steps—application deployment, H2 database setup, password policy, user management, 
and health verification—are automated declaratively through SaltStack.