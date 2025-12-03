# CA6 - Jenkins
# Part 1: Blue-Green Deployment with Vagrant, Ansible, Jenkins & Spring Boot

This part of CA6 implements a CI/CD pipeline that builds a Gradle-based Spring Boot application and deploys 
it to a **green** VM using a **blue-green** deployment topology.

Two VMs are used to simulate a production environment:

- **blue** - initial deployment 
- **green** - becomes the new production after approval

---

## 1. Requirements Mapping (CA6 Part 1)

From the specification :

- Create two VMs (blue/green) with Vagrant and provision them with Ansible  
- Run Jenkins on the host machine  
- Pipeline stages:  
  - Checkout, Assemble, Test, Archive  
  - Deploy to Production? (manual approval)  
  - Deploy (using an Ansible playbook on the green VM)  
- Tag stable builds (`stable-vx.x`) only after all stages succeed  
- Post-actions:  
  - Notification about the pipeline result  
  - Deployment verification (health-check after deploy)  
- Create an Ansible playbook to roll back to a previous **stable** version

---

## 2. Architecture Overview

### 2.1 Blue–Green topology

Both VMs run inside a single host using Vagrant.
The same Spring Boot application runs on both machines.
Deployment is executed via Ansible.

- **blue VM – 192.168.56.10**  
  - Provisioned with `deploy-blue.yml` via `ansible_local`.  
  - Runs an initial version of the Spring Boot app and acts as the active environment.

- **green VM – 192.168.56.11**  
  - Provisioned with `deploy-green.yml`.  
  - Receives deployments from Jenkins after manual approval and is intended to become the next active environment.
  - Target for health-checks and rollback.

The Vagrant/Ansible configuration is kept under version control in `CA6/Part1`, so the whole environment can be recreated from scratch.

---

## 3. Infrastructure Layer – Vagrant + Ansible

### 3.1 Vagrantfile

The `Vagrantfile` in `CA6/Part1` defines both VMs:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.boot_timeout = 600

  # VM BLUE
  config.vm.define "blue" do |blue|
    blue.vm.hostname = "blue"
    blue.vm.network "private_network", ip: "192.168.56.10"

    blue.vm.network "forwarded_port",
                    guest: 22, host: 2223, auto_correct: true

    blue.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--natpf1", "delete", "ssh"]
      vb.memory = 2048
      vb.cpus = 2
    end

    blue.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "/vagrant/ansible/deploy-blue.yml"
      ansible.inventory_path = "/vagrant/ansible/hosts"
    end
  end

  # VM GREEN
  config.vm.define "green" do |green|
    green.vm.hostname = "green"
    green.vm.network "private_network", ip: "192.168.56.11"
    green.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--natpf1", "delete", "ssh"]
      vb.memory = 2048
      vb.cpus = 2
    end

    green.vm.network "forwarded_port",
                     guest: 22, host: 2203, auto_correct: true

    green.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "/vagrant/ansible/deploy-green.yml"
      ansible.inventory_path = "/vagrant/ansible/hosts"
    end
  end
end
```

### 3.2 - VM lifecycle and justification

The blue and green VMs are fully managed with Vagrant and provisioned using Ansible (`ansible_local`) during `vagrant up`.  
Both virtual machines are created and configured not from Jenkins but from the host machine by running:

```bash
cd CA6/Part1
vagrant up blue
vagrant up green
```

Originally, the idea was to let Jenkins control the full lifecycle of the VMs.
However on Windows, Jenkins runs under a service account which does not have the necessary permissions to interact with VirtualBox and access the local Vagrant environment. 
Calling vagrant up from a pipeline resulted in permission errors.

Because of this limitation:

- VM lifecycle operations (create, destroy, vagrant up, vagrant provision) are performed from the host shell.
- Jenkins assumes both VMs are up and reachable at 192.168.56.10/11 when the pipeline runs.
- This keeps the requirement “Automate infrastructure setup” by versioning the Vagrantfile and Ansible playbooks.

---

## 4 - Application Layer - Spring Boot (Gradle)

The application is the “Building REST services with Spring” sample, adapted as a Gradle project, located in:

CA6/Part1/spring-app/

REST endpoint used for verification: GET /greeting (port 8080).
Built with the Gradle wrapper:

```bash
cd CA6/Part1/spring-app
./gradlew clean build
```
Output JAR:
CA6/Part1/spring-app/build/libs/rest-service-0.0.1-SNAPSHOT.jar

On the green VM the JAR is deployed to /opt/app/app.jar and started via systemd.

---

## 5 - Configuration Layer - Ansible Playbook

All configuration and deployment tasks on the VMs are done with Ansible.
All playbooks are stored under:

```bash
CA6/Part1/ansible/
```

Inventory snippet (hosts):

[blue]
localhost ansible_connection=local

[green]
localhost ansible_connection=local

Each VM runs Ansible locally (via ansible_local in Vagrant or via SSH + ansible-playbook).
In this context, localhost ansible_connection=local means:
- On the both VMs, the groups points to the VM themselfs.

This avoids hard-coding IP addresses in the inventory. The same inventory file works inside both VMs.

### 5.1 deploy-blue.yml - initial deployment (blue VM)

This playbook is used during the 'vagrant up blue' to provision the blue VM.
Its responsibilities are:

- Install Java runtime
- Create the application directory /opt/spring-app.
- Copy the built JAR from the shared folder /vagrant/spring-app/build/libs/... into /opt/spring-app/app.jar.
- Install the spring-app.service unit file under /etc/systemd/system/.
- Enable and start the service using systemd, so the app runs on boot.

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


### 5.2 deploy-green.yml - deployments from Jenkins (green VM)

This playbook is used by Jenkins to deploy the application to the green VM.
It is executed remotely from Jenkins via SSH, and it is responsible for:

- Installing Java if it isn't already present.
- Creating the application directory /opt/app.
- Copying the JAR built by Jenkins from the shared folder into /opt/app/app.jar.
- Creating the spring-app systemd service (inline content).
- Reloading systemd configuration.
- Starting (or restarting) the spring-app service.

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

Jenkins builds and tests the Spring Boot JAR.
After manual approval, Jenkins SSHs into the green VM and runs:
```bash
cd /vagrant/ansible && sudo ansible-playbook deploy-green.yml -i hosts
```
The playbook deploys the new version to green and starts the service.
The next Jenkins stage performs an HTTP health check on green to validate the deployment.

### 5.3 rollback-green.yml - rollback playbook (green VM)

A dedicated Ansible playbook, rollback-green.yml, is provided to roll back the green VM to a previously stable version of the application.
It assumes that a stable JAR has been downloaded from Jenkins to the shared folder:
On the host: CA6/Part1/rollback/rest-service-rollback.jar
Inside the VM: /vagrant/rollback/rest-service-rollback.jar

- hosts: green
  become: yes
  vars:
    jenkins_url: "http://192.168.56.1:8080"
    jenkins_job_name: "CA6-Part1-Pipeline"

    jenkins_artifact_path: "CA6/Part1/spring-app/build/libs/rest-service-0.0.1-SNAPSHOT.jar"

    rollback_dir: "/vagrant/rollback"
    rollback_jar: "/vagrant/rollback/rest-service-rollback.jar"
    app_jar_dest: "/opt/app/app.jar"

  tasks:

    - name: Ensure rollback folder exists
      file:
        path: /vagrant/rollback
        state: directory

    - name: Download last successful artifact from Jenkins
      get_url:
        url: "{{ jenkins_url }}/job/{{ jenkins_job_name }}/lastSuccessfulBuild/artifact/{{ jenkins_artifact_path }}"
        dest: "{{ rollback_jar }}"
        mode: "0755"
        headers:
          Authorization: "Basic {{ (lookup('env','JENKINS_USER') + ':' + lookup('env','JENKINS_TOKEN')) | b64encode }}"
      register: download_result

    - name: Fail if rollback JAR does not exist
      stat:
        path: "{{ rollback_jar }}"
      register: rollback_file

    - name: Stop current spring-app service
      systemd:
        name: spring-app
        state: stopped
      when: rollback_file.stat.exists

    - name: Replace current application with rollback version
      copy:
        src: "{{ rollback_jar }}"
        dest: /opt/app/app.jar
        mode: '0755'
      when: rollback_file.stat.exists

    - name: Reload systemd daemon
      command: systemctl daemon-reload
      when: rollback_file.stat.exists

    - name: Start spring-app with rollback version
      systemd:
        name: spring-app
        state: started
        enabled: yes
      when: rollback_file.stat.exists

    - name: Health-check after rollback
      uri:
        url: "http://192.168.56.11:8080/greeting"
        return_content: yes
      register: health
      retries: 5
      delay: 5
      until: health.status == 200
      when: rollback_file.stat.exists


Rollback workflow:

The operator downloads a known stable JAR from Jenkins and places it in CA6/Part1/rollback/rest-service-rollback.jar (host), 
which is exposed to the VM as /vagrant/rollback/rest-service-rollback.jar.

The playbook:

- Ensures /vagrant/rollback exists.
- Checks whether rollback_jar exists and only proceeds if the file is present.
- Stops the current spring-app systemd service on the green VM.
- Replaces /opt/app/app.jar with the rollback JAR.
- Reloads the systemd daemon.
- Restarts the spring-app service with the rollback artifact.
- Performs an HTTP health check on http://192.168.56.11:8080/greeting (with retries) to confirm that the rollback version is running correctly.

To execute the rollback manually from the host:

```bash
cd CA6/Part1/ansible
ansible-playbook rollback-green.yml -i hosts
```

## 6 - CI/CD Layer - Jenkins Declarative Pipeline

Jenkins runs on the host and uses a Declarative Pipeline defined in CA6/Part1/Jenkinsfile. 
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

### 6.1 Jenkinsfile

pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                git(
                    branch: 'main',
                    url: 'https://github.com/1240598Rafa/cogsi2526-1240598-1240601.git',
                    credentialsId: 'github-pat'
                )
            }
        }

        stage('Assemble') {
            steps {
                dir('CA6/Part1/spring-app') {
                    sh './gradlew clean build'
                }
            }
        }

        stage('Test') {
            steps {
                dir('CA6/Part1/spring-app') {
                    sh './gradlew test'
                }
            }
            post {
                always {
                    junit 'CA6/Part1/spring-app/build/test-results/test/*.xml'
                }
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'CA6/Part1/spring-app/build/libs/*.jar', fingerprint: true
            }
        }

        stage('Deploy to Production?') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    input message: "Deploy to GREEN VM?"
                }
            }
        }

        stage('Deploy') {
            steps {
                dir('CA6/Part1') {
                    sh '''
                        ssh -i "C:/Users/rafa/Desktop/ISEP/COGSI/cogsi2526-1240598-1240601/CA6/Part1/.vagrant/machines/green/virtualbox/private_key" \
                        -o StrictHostKeyChecking=no \
                        vagrant@192.168.56.11 \
                        "cd /vagrant/ansible && sudo ansible-playbook deploy-green.yml -i hosts"
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                        retry(5) {
                            sleep 5
                            def responseCode = sh(
                                script: """curl -s -o /dev/null -w '%{http_code}' \
                                http://192.168.56.11:8080/greeting?name=fail || echo 000""",
                            returnStdout: true
                            ).trim()

                        echo "Health Check HTTP response code: ${responseCode}"

                            if (responseCode != '200') {
                            error "Health check failed: Application is not responding correctly."
                            }
                        }
                    }
                }
            }
        }


        stage('Tag Stable Build') {
            when {
                expression { currentBuild.currentResult == 'SUCCESS' }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-pat',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )
                ]) {
                    sh """
                        git config user.name "jenkins"
                        git config user.email "jenkins@example.com"

                        git tag stable-v${BUILD_NUMBER}

                        git push https://${GIT_USER}:${GIT_TOKEN}@github.com/1240598Rafa/cogsi2526-1240598-1240601.git stable-v${BUILD_NUMBER}
                    """
                }
            }
        }


        stage('Rollback GREEN (manual)') {
            when {
                expression { currentBuild.currentResult == 'FAILURE' }
            }
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    input message: "Execute rollback on GREEN VM with lastSuccessfulBuild from Jenkins?"
                }

                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-pat',
                        usernameVariable: 'JENKINS_USER',
                        passwordVariable: 'JENKINS_TOKEN'
                    )
                ]) {
                    dir('CA6/Part1') {
                        sh """
                            ssh -i "C:/Users/rafa/Desktop/ISEP/COGSI/cogsi2526-1240598-1240601/CA6/Part1/.vagrant/machines/green/virtualbox/private_key" \
                            -o StrictHostKeyChecking=no \
                            vagrant@192.168.56.11 \
                            "cd /vagrant/ansible && JENKINS_USER=${JENKINS_USER} JENKINS_TOKEN=${JENKINS_TOKEN} ansible-playbook rollback-green.yml -i hosts"
                        """
                    }
                }
            }
        }
    }
    post {
        success {
            echo "Pipeline completed successfully."
        }
        failure {
            echo "Pipeline failed."
        }
    }
}


### 6.2 Stage breakdown and justification

#### Checkout
Pulls the main branch from GitHub using a personal access token (github-pat).

#### Assemble
Runs ./gradlew clean build inside CA6/Part1/spring-app, producing the JAR artifact.

#### Test
Executes unit tests (./gradlew test) and publishes JUnit XML results in Jenkins.

#### Archive
Archives the generated JARs under Jenkins for traceability and later use.

#### Deploy to Production?
Manual approval gate. The pipeline only proceeds to the Deploy stage if the user clicks Proceed, satisfying the “Deploy to Production?” requirement.

#### Deploy

The Jenkins Deploy stage connects via SSH to the green VM and delegates the deployment to Ansible:
```bash
ssh -i "<vagrant_private_key_path>" -o StrictHostKeyChecking=no vagrant@192.168.56.11 \
  "cd /vagrant/ansible && sudo ansible-playbook deploy-green.yml -i hosts"
```

Jenkins uses the private key generated by Vagrant (.vagrant/machines/green/virtualbox/private_key) to authenticate as vagrant on the green VM.
The /vagrant folder is a shared directory between the host and the VM, so the JAR produced in the Assemble stage is available to Ansible.
The deploy-green.yml playbook installs Java (if needed), ensures the application folder exists, copies the JAR into /opt/app/app.jar, creates the spring-app systemd service, reloads systemd and finally starts the service.
This satisfies the requirement “Deploy - Uses an Ansible playbook to deploy and start the application on the green VM”.


#### Health Check (Deployment Verification)

After the Ansible deployment finishes, Jenkins runs an HTTP health check against the green VM:

curl -s -o /dev/null -w "%{http_code}" http://192.168.56.11:8080/greeting

If the response code is not 200, the pipeline is marked as failed.
It retries up to 5 times with 5-second intervals.
This implements the requested Deployment Verification post-action.

#### Tag Stable Build
When all stages (Assemble, Test, Deploy and Health Check) complete successfully, the pipeline tags the current commit as a stable build:

git tag stable-v${BUILD_NUMBER}
git push origin stable-v${BUILD_NUMBER}


The tag is pushed to GitHub using a personal access token configured as a Jenkins credential.

At the end of the Jenkins pipeline, a notification step prints:

Pipeline completed successfully.
Build tagged as stable-vX.Y.

or, in case of failure:

Pipeline failed during <stage>.
No stable tag created.

This provides immediate visibility into the pipeline's success or failure.


#### Post actions (Notification)
A final post block prints either:

- Pipeline completed successfully.
- Pipeline failed.

Giving a concise textual notification of the result.

---

## 7 - How to Reproduce the Setup

From the host machine:

#1 - Start VMs (one-time)
```bash
cd CA6/Part1
vagrant up blue
vagrant up green
```

2 - (Optional) Re-provision
vagrant provision blue
vagrant provision green

3 - Configure Jenkins
Create a pipeline job pointing to this repo
Add credentials "github-pat" (username + PAT)

4 - Trigger the pipeline
In Jenkins UI press "Build Now".
Approve the "Deploy to GREEN VM?" input when prompted.

Manual verification:

Blue VM
curl http://192.168.56.10:8080/greeting

Green VM
curl http://192.168.56.11:8080/greeting


Rollback:
After downloading a stable JAR from Jenkins to CA6/Part1/rollback/
cd CA6/Part1/ansible
ansible-playbook rollback-green.yml -i hosts

## 8 - Git Tag for Submission

git tag ca6-week1
git push origin ca6-week1

## 9. Alternative CI/CD Solution (Non-Jenkins)

The CA6 specification requires an different technological solution for the configuration management / CI/CD tool, not based on Jenkins, and an analysis of how it compares to the base solution.
For this purpose, GitHub Actions is considered an alternative to Jenkins as a CI/CD platform.

### 9.1 Candidate tools

Several CI/CD platforms could replace Jenkins:

- **GitHub Actions** – Native CI/CD integrated into GitHub; pipelines defined as YAML workflows in `.github/workflows/`.
- **GitLab CI/CD** – Built into GitLab; pipelines defined in `.gitlab-ci.yml`.
- **Azure DevOps Pipelines** – Cloud CI/CD with YAML pipelines and tight integration with Azure services.

Since this assignment is already using a private GitHub repository, GitHub Actions is a natural alternative: no extra server is required, and SCM + CI/CD are managed on a single platform.

### 9.2 Jenkins vs GitHub Actions – Feature comparison

| Aspect                        | Jenkins (base solution)                                         | GitHub Actions (alternative)                                       |
|-------------------------------|------------------------------------------------------------------|--------------------------------------------------------------------|
| Hosting model                 | Self-hosted server running on the local machine                  | Managed by GitHub, with optional self-hosted runners                |
| Integration with GitHub       | Via webhooks and credentials                                     | Native integration (first-class support)                            |
| Pipeline definition           | `Jenkinsfile` (Declarative or Scripted Pipeline)                 | YAML workflows in `.github/workflows/*.yml`                         |
| Triggering                    | Webhooks, timers, manual “Build Now”                             | `push`, `pull_request`, schedules, manual `workflow_dispatch`       |
| Plugins / extensibility       | Large plugin ecosystem (e.g. JUnit, Ansible, Git, etc.)          | Marketplace of reusable “actions”                                   |
| Build agents                  | Jenkins nodes (master/agent model)                               | Hosted runners or self-hosted runners                               |
| Artifact storage              | Jenkins artifacts + integrations (e.g. with Nexus, S3, etc.)     | Built-in artifact storage (`actions/upload-artifact`) + Releases    |
| Secrets management            | Jenkins credentials store                                        | GitHub Secrets and Environments                                     |
| Operational overhead          | Requires installation, upgrade, backup of Jenkins server         | No Jenkins server to maintain; only runners (if self-hosted)        |
| Vendor lock-in                | SCM-agnostic (GitHub, GitLab, SVN, etc.)                         | Tied to GitHub as SCM provider                                      |

For this assignment, Jenkins gives full control over the CI server and fits the goal of learning a traditional on-prem pipeline tool. GitHub Actions would simplify infrastructure but at the cost of relying on a SaaS platform and GitHub-specific concepts.

### 9.3 Alternative design using GitHub Actions
#### 9.3.1 Runner model

To keep the same topology (Vagrant + Ansible + local VMs), a **self-hosted GitHub Actions runner** can be installed on the same host machine that currently runs Jenkins.
Because Ansible does not run natively on Windows, the runner integrates with **WSL (Ubuntu)** to execute all Ansible playbooks. The resulting setup provides:

- Access to the full project repository (checked out by Actions).
- Access to the Vagrant VM environment:
CA6/Part1
CA6/Part2
- Ability to run Gradle builds on Windows (PowerShell).
- Ability to run Ansible through WSL:
wsl ansible-playbook playbook.yml -i hosts
- Access to the blue and green VMs over host-only networking:
192.168.56.10 – blue VM
192.168.56.11 – green VM
- Integration with the /vagrant shared folder for file transfer between host and VMs.

This is equivalent to the current Jenkins node and allows GitHub Actions to run `vagrant` and `ansible-playbook` commands in the same way.

#### 9.3.2 Workflow for Part 1 – Blue–Green deployment

A workflow file such as `.github/workflows/ca6-part1.yml` could implement the following jobs:

1. **build-and-test** (on push to `development` or `main`)
   - Checkout repository (`actions/checkout`).
   - Run Gradle build and tests:
     ```bash
     cd CA6/Part1/spring-app
     ./gradlew clean build
     ./gradlew test
     ```
   - Publish test results using a JUnit action (for example, upload reports as artifacts).
   - Upload the built JAR as a workflow artifact to the path: CA6/Part1/spring-app/build/libs/rest-service-0.0.1-SNAPSHOT.jar

2. **tag-stable** (depends on `build-and-test`)
   - Only executes when tests pass.
   - Creates and pushes a Git tag similar to `stable-v${GITHUB_RUN_NUMBER}` using a GitHub token.
   - This reproduces the “Tag stable builds in Jenkins” requirement, but in GitHub Actions.

3. **deploy-green** (manual approval + Ansible deployment)
   - Uses GitHub **Environments** with protection rules to require manual approval before running this job.
   - After approval:
     - Downloads the JAR artifact produced in `build-and-test`.
     - Ensures the artifact is available under `/vagrant` so the green VM can access it.
     - Executes:
       ```bash
       cd CA6/Part1/ansible
       ansible-playbook deploy-green.yml -i hosts
       ```
   - This step is equivalent to the current Jenkins stage that SSHs into the green VM and runs the Ansible deployment.

4. **health-check** (depends on `deploy-green`)
   - From the self-hosted runner, calls:
     ```bash
     curl -s -o /dev/null -w '%{http_code}' http://192.168.56.11:8080/greeting
     ```
   - Fails the job if the HTTP status is not `200`.
   - Implements the same deployment verification currently done in Jenkins.

5. **rollback-green** (separate workflow, manual trigger)
   - A second workflow, e.g. `.github/workflows/rollback-green.yml`, could:
     - Accept as input the tag of the stable version to roll back to (e.g. `stable-v21`).
     - Download the corresponding JAR from:
       - A GitHub Release named after the tag, or
       - A previously uploaded artifact associated with that tag.
     - Place the rollback JAR into `/vagrant/rollback/`.
     - Execute the `rollback-green.yml` Ansible playbook:
       ```bash
       cd CA6/Part1/ansible
       ansible-playbook rollback-green.yml -i hosts
       ```
   - The playbook itself would be very similar to the existing one (stop service, replace JAR, restart, health check), but the artifact source would now be GitHub instead of Jenkins.

Overall, the GitHub Actions design reuses the same Vagrant + Ansible setup and enforces the same pipeline stages (build, test, deploy, verification, rollback), but moves orchestration from Jenkins to cloud-hosted workflows.

#### 9.3.3 Workflow for Part 2 – Docker image and production VM

For Part 2, a workflow such as `.github/workflows/ca6-part2.yml` could implement:

1. **build-and-test** job
   - Same Gradle build and test as in Part 1.
2. **build-and-push-docker-image** job
   - Build Docker image for the Spring app.
   - Tag it with the Git SHA or run number.
   - Login to Docker Hub using GitHub Secrets.
   - Push the image to Docker Hub.
3. **deploy-production** job
   - On push to the `main` branch only.
   - After manual approval via environment protection.
   - From the self-hosted runner:
     ```bash
     cd CA6/Part2/ansible
     ansible-playbook deploy-docker-production.yml -i hosts
     ```
   - The playbook ensures Docker is installed, pulls the latest image, stops the old container (if any), and runs the new one.
4. **health-check** job
   - Similar to Part 1, verifying that the containerized version responds correctly on the production VM.

### 9.4 Discussion and justification of the base choice

GitHub Actions provides a modern, tightly integrated CI/CD solution with less operational overhead than Jenkins, especially when working exclusively with GitHub repositories. It simplifies authentication, artifact management and event triggers, and would be a valid alternative to implement the full CA6 assignment.  

The alternative design with GitHub Actions shows that the same functional goals (automated build, test, blue–green deployment, health checks, stable tagging and rollback) can be achieved with a different CI/CD platform, and highlights the main trade-offs between a self-hosted CI server (Jenkins) and a cloud-native CI/CD solution (GitHub Actions).