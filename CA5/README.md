# CA5 Containers
## Part 1 - Containerization of CA3 Applications (Chat & Spring)

The objective of this module is to gain hands-on experience with Docker by creating multiple image versions, analyzing image layers, evaluating resource usage, and publishing final images to Docker Hub.
This document describes the full implementation of CA5, the part 1  focus on containerizing the two applications previously developed in CA3:

Chat Application and Building REST Services with Spring

## Project Structure

The CA5 folder was organized as follows:

CA5/
 └── Part1/
      ├── Chat/
      │    ├── Dockerfile
      │    ├── Dockerfile.v1
      │    ├── Dockerfile.multi
      │    ├── gradlew, gradle/, src/, build.gradle, settings.gradle
      └── Spring/
           ├── Dockerfile.v1
           ├── Dockerfile.v2
           ├── Dockerfile.multi
           ├── gradlew, gradle/, src/, build.gradle, settings.gradle


The multi-stage and Version 1 builds require the full project source code.
Version 2 uses only a pre-compiled JAR.

## Prerequisites

Docker Desktop

JDK 21-based images

Gradle Wrapper inside both projects

Full source code of CA2 Part1 and CA2 Part2

## Step-By-Step

## Chat Application
### Version 1 - Build inside the container

First it was required to:
“Version 1: Build the server inside the Dockerfile.”

The Dockerfile complies the application inside the image, meaning the final container includes all build dependencies, tools and cache.

Dockerfile.v1

FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY . /app
RUN ./gradlew clean build -x test
EXPOSE 59001
CMD ["java", "-cp", "build/libs/basic_demo-0.1.0.jar", "basic_demo.ChatServerApp", "59001"]

Explanation:

FROM - selects a JDK base image, it is required so the application can be compiled inside the container.
WORKDIR - sets the working directory of the container, all following commands will be runed inside /app.
COPY - copies the entire project.
RUN - executes Gradle build inside the container.
EXPOSE - documents that the application expects to listen on port 59001.
CMD - defines the default command to run when the containers start, it runs the Chat using the JAR.
Copies the full source code into the container

To build:
docker build -f Dockerfile.v1 -t chatapp:v1 .

To test:
docker run --rm -p 59001:59001 chatapp:v1

### Version 2 — Host-built JAR

This version satisfies:

“Version 2: Build the server on the host and copy the resulting JAR into the image.”

So the application is built locally before building the image.

Dockerfile
FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY basic_demo-0.1.0.jar app.jar
EXPOSE 59001
CMD ["java", "-cp", "app.jar", "basic_demo.ChatServerApp", "59001"]

Explanation for the Dockerfilev2:

FROM - uses a JDK base image
WORKDIR - sets /app as the working directory
COPY - only the final JAR is copied into the image
EXPOSE - port to be used
CMD - starts the app by running the JAR

The JAR is compiled locally using:
./gradlew clean build -x test

The container only contains the JAR + runtime

This produces a smaller image compared to Version 1

To build:
docker build -f Dockerfile.v2 -t chatapp:v2 .

### Multi-Stage Build (Version 3)

This version satisfies the requirement:

“Implement a multi-stage build to separate the build and runtime stages.”

Dockerfile.multi
FROM eclipse-temurin:21-jdk AS builder
WORKDIR /build
COPY . /build
RUN ./gradlew clean build -x test

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /build/build/libs/basic_demo-0.1.0.jar app.jar
EXPOSE 59001
CMD ["java", "-cp", "app.jar", "basic_demo.ChatServerApp", "59001"]

Why this version is better

The build stage includes JDK + Gradle

The runtime stage uses only the small JRE

The final image is significantly lighter and safer

This is the recommended production practice

## Spring Application
### Version 1 - Build inside the container
Dockerfile
FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY . /app
RUN ./gradlew clean build -x test
EXPOSE 8080
CMD ["java", "-jar", "build/libs/app.jar"]


(The JAR name may vary; wildcard can be used.)

### Version 2 — Host-built JAR
Dockerfile.v2
FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY build/libs/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]

### Multi-Stage Build
Dockerfile.multi
FROM eclipse-temurin:21-jdk AS builder
WORKDIR /build
COPY . /build
RUN ./gradlew clean build -x test

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /build/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

Explanation

Same multi-stage approach used for Chat
Produces the smallest and cleanest final image
No source code or build tooling exists in the final container

## Image Layer Analysis (docker history)

It was then asked to explain how version 1 differ from version 2 and multi-stage in termos of image layers and size.
The following commands were used:

### Chat
docker history chatapp:v1:

IMAGE          CREATED        CREATED BY                                      SIZE      COMMENT
fe08739a7805   14 hours ago   CMD ["java" "-cp" "build/libs/basic_demo-0.1…   0B        buildkit.dockerfile.v0
<missing>      14 hours ago   EXPOSE map[59001/tcp:{}]                        0B        buildkit.dockerfile.v0
<missing>      14 hours ago   RUN /bin/sh -c ./gradlew clean build -x test…   692MB     buildkit.dockerfile.v0
<missing>      14 hours ago   COPY . /app # buildkit                          11.7MB    buildkit.dockerfile.v0
<missing>      4 days ago     WORKDIR /app                                    8.19kB    buildkit.dockerfile.v0
<missing>      8 days ago     CMD ["jshell"]                                  0B        buildkit.dockerfile.v0
<missing>      8 days ago     ENTRYPOINT ["/__cacert_entrypoint.sh"]          0B        buildkit.dockerfile.v0
<missing>      8 days ago     COPY --chmod=755 entrypoint.sh /__cacert_ent…   12.3kB    buildkit.dockerfile.v0
<missing>      8 days ago     RUN /bin/sh -c set -eux;     echo "Verifying…   12.3kB    buildkit.dockerfile.v0
<missing>      8 days ago     RUN /bin/sh -c set -eux;     ARCH="$(dpkg --…   308MB     buildkit.dockerfile.v0
<missing>      8 days ago     ENV JAVA_VERSION=jdk-21.0.9+10                  0B        buildkit.dockerfile.v0
<missing>      8 days ago     RUN /bin/sh -c set -eux;     apt-get update;…   68.8MB    buildkit.dockerfile.v0
<missing>      8 days ago     ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_AL…   0B        buildkit.dockerfile.v0
<missing>      8 days ago     ENV PATH=/opt/java/openjdk/bin:/usr/local/sb…   0B        buildkit.dockerfile.v0
<missing>      8 days ago     ENV JAVA_HOME=/opt/java/openjdk                 0B        buildkit.dockerfile.v0
<missing>      6 weeks ago    /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>      6 weeks ago    /bin/sh -c #(nop) ADD file:249778a1782b02a1c…   87.6MB
<missing>      6 weeks ago    /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      6 weeks ago    /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      6 weeks ago    /bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH     0B
<missing>      6 weeks ago    /bin/sh -c #(nop)  ARG RELEASE                  0B

The layer created by RUN /bin/sh -c ./gradlew clean build -x test… includes the Gradle cache, compiled classes, temporary build directories and downloaded dependencies
The COPY . /app # buildkit  should be the full project source code
This version is the largest and least effecient build, because everything that is needed to compile the project is inside the final image.

docker history chatapp:v2:

IMAGE          CREATED       CREATED BY                                      SIZE      COMMENT
0c6f720e4265   2 days ago    CMD ["java" "-cp" "app.jar" "basic_demo.Chat…   0B        buildkit.dockerfile.v0
<missing>      2 days ago    EXPOSE map[59001/tcp:{}]                        0B        buildkit.dockerfile.v0
<missing>      2 days ago    COPY basic_demo-0.1.0.jar app.jar # buildkit    1.89MB    buildkit.dockerfile.v0
<missing>      4 days ago    WORKDIR /app                                    8.19kB    buildkit.dockerfile.v0
<missing>      8 days ago    CMD ["jshell"]                                  0B        buildkit.dockerfile.v0
<missing>      8 days ago    ENTRYPOINT ["/__cacert_entrypoint.sh"]          0B        buildkit.dockerfile.v0
<missing>      8 days ago    COPY --chmod=755 entrypoint.sh /__cacert_ent…   12.3kB    buildkit.dockerfile.v0
<missing>      8 days ago    RUN /bin/sh -c set -eux;     echo "Verifying…   12.3kB    buildkit.dockerfile.v0
<missing>      8 days ago    RUN /bin/sh -c set -eux;     ARCH="$(dpkg --…   308MB     buildkit.dockerfile.v0
<missing>      8 days ago    ENV JAVA_VERSION=jdk-21.0.9+10                  0B        buildkit.dockerfile.v0
<missing>      8 days ago    RUN /bin/sh -c set -eux;     apt-get update;…   68.8MB    buildkit.dockerfile.v0
<missing>      8 days ago    ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_AL…   0B        buildkit.dockerfile.v0
<missing>      8 days ago    ENV PATH=/opt/java/openjdk/bin:/usr/local/sb…   0B        buildkit.dockerfile.v0
<missing>      8 days ago    ENV JAVA_HOME=/opt/java/openjdk                 0B        buildkit.dockerfile.v0
<missing>      6 weeks ago   /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>      6 weeks ago   /bin/sh -c #(nop) ADD file:249778a1782b02a1c…   87.6MB
<missing>      6 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      6 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      6 weeks ago   /bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH     0B
<missing>      6 weeks ago   /bin/sh -c #(nop)  ARG RELEASE                  0B

The only application specific layer is COPY basic_demo-0.1.0.jar app.jar # buildkit 
No Gradle layer is present and the rest of the layers come from the base OpenJDK 21 image
This means that the version 2 is much smaller compared to the version 1, because only the JAR is added to the image, so no build tools, no source code
and no Gradle cache are included.

docker history chatapp:multi:
IMAGE          CREATED        CREATED BY                                      SIZE      COMMENT
2e2db3636902   14 hours ago   CMD ["java" "-cp" "app.jar" "basic_demo.Chat…   0B        buildkit.dockerfile.v0
<missing>      14 hours ago   EXPOSE map[59001/tcp:{}]                        0B        buildkit.dockerfile.v0
<missing>      14 hours ago   COPY /build/build/libs/basic_demo-0.1.0.jar …   1.89MB    buildkit.dockerfile.v0
<missing>      14 hours ago   WORKDIR /app                                    8.19kB    buildkit.dockerfile.v0
<missing>      3 days ago     ENTRYPOINT ["/__cacert_entrypoint.sh"]          0B        buildkit.dockerfile.v0
<missing>      3 days ago     COPY --chmod=755 entrypoint.sh /__cacert_ent…   12.3kB    buildkit.dockerfile.v0
<missing>      3 days ago     RUN /bin/sh -c set -eux;     echo "Verifying…   12.3kB    buildkit.dockerfile.v0
<missing>      3 days ago     RUN /bin/sh -c set -eux;     ARCH="$(dpkg --…   165MB     buildkit.dockerfile.v0
<missing>      3 days ago     ENV JAVA_VERSION=jdk-21.0.9+10                  0B        buildkit.dockerfile.v0
<missing>      3 days ago     RUN /bin/sh -c set -eux;     apt-get update;…   49.6MB    buildkit.dockerfile.v0
<missing>      3 days ago     ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_AL…   0B        buildkit.dockerfile.v0
<missing>      3 days ago     ENV PATH=/opt/java/openjdk/bin:/usr/local/sb…   0B        buildkit.dockerfile.v0
<missing>      3 days ago     ENV JAVA_HOME=/opt/java/openjdk                 0B        buildkit.dockerfile.v0
<missing>      4 weeks ago    /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>      4 weeks ago    /bin/sh -c #(nop) ADD file:ddf1aa62235de6657…   87.6MB
<missing>      4 weeks ago    /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      4 weeks ago    /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      4 weeks ago    /bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH     0B
<missing>      4 weeks ago    /bin/sh -c #(nop)  ARG RELEASE                  0B

The runtime layer includes COPY /build/build/libs/basic_demo-0.1.0.jar … 
The Gradle build layers that are the heaviest, aren't on the final image.
The OpenJRE base image is smaller than the Open JDK.

This means that the multi-stage produces the smalles and cleanest image, doesn't need dependencies, no source file and has a smaller runtime compared to JDK.


### Spring
docker history springapp:v1:

IMAGE          CREATED       CREATED BY                                      SIZE      COMMENT
cba67610e2b7   4 days ago    CMD ["java" "-jar" "app.jar"]                   0B        buildkit.dockerfile.v0
<missing>      4 days ago    EXPOSE map[8080/tcp:{}]                         0B        buildkit.dockerfile.v0
<missing>      4 days ago    WORKDIR /app                                    4.1kB     buildkit.dockerfile.v0
<missing>      4 days ago    COPY /app/complete/build/libs/rest-service-0…   21MB      buildkit.dockerfile.v0
<missing>      8 days ago    CMD ["jshell"]                                  0B        buildkit.dockerfile.v0
<missing>      8 days ago    ENTRYPOINT ["/__cacert_entrypoint.sh"]          0B        buildkit.dockerfile.v0
<missing>      8 days ago    COPY --chmod=755 entrypoint.sh /__cacert_ent…   12.3kB    buildkit.dockerfile.v0
<missing>      8 days ago    RUN /bin/sh -c set -eux;     echo "Verifying…   12.3kB    buildkit.dockerfile.v0
<missing>      8 days ago    RUN /bin/sh -c set -eux;     ARCH="$(dpkg --…   308MB     buildkit.dockerfile.v0
<missing>      8 days ago    ENV JAVA_VERSION=jdk-21.0.9+10                  0B        buildkit.dockerfile.v0
<missing>      8 days ago    RUN /bin/sh -c set -eux;     apt-get update;…   68.8MB    buildkit.dockerfile.v0
<missing>      8 days ago    ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_AL…   0B        buildkit.dockerfile.v0
<missing>      8 days ago    ENV PATH=/opt/java/openjdk/bin:/usr/local/sb…   0B        buildkit.dockerfile.v0
<missing>      8 days ago    ENV JAVA_HOME=/opt/java/openjdk                 0B        buildkit.dockerfile.v0
<missing>      6 weeks ago   /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>      6 weeks ago   /bin/sh -c #(nop) ADD file:249778a1782b02a1c…   87.6MB
<missing>      6 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      6 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      6 weeks ago   /bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH     0B
<missing>      6 weeks ago   /bin/sh -c #(nop)  ARG RELEASE                  0B

The COPY /app/complete/build/libs/rest-service-0… represents tje compiled Spring Boot JAR
This version is the heaviest because it contains everything needed to build the Spring Boot app, the Gradle dependencies bring huge overhead and it also keeps
both the soruce codes and build tools.

docker history springapp:v2:

IMAGE          CREATED       CREATED BY                                      SIZE      COMMENT
e433fc3c3d32   4 days ago    CMD ["java" "-jar" "app.jar"]                   0B        buildkit.dockerfile.v0
<missing>      4 days ago    EXPOSE map[8080/tcp:{}]                         0B        buildkit.dockerfile.v0
<missing>      4 days ago    COPY Cogsi-1.0.0.jar /app/app.jar # buildkit    51MB      buildkit.dockerfile.v0
<missing>      4 days ago    WORKDIR /app                                    8.19kB    buildkit.dockerfile.v0
<missing>      8 days ago    CMD ["jshell"]                                  0B        buildkit.dockerfile.v0
<missing>      8 days ago    ENTRYPOINT ["/__cacert_entrypoint.sh"]          0B        buildkit.dockerfile.v0
<missing>      8 days ago    COPY --chmod=755 entrypoint.sh /__cacert_ent…   12.3kB    buildkit.dockerfile.v0
<missing>      8 days ago    RUN /bin/sh -c set -eux;     echo "Verifying…   12.3kB    buildkit.dockerfile.v0
<missing>      8 days ago    RUN /bin/sh -c set -eux;     ARCH="$(dpkg --…   308MB     buildkit.dockerfile.v0
<missing>      8 days ago    ENV JAVA_VERSION=jdk-21.0.9+10                  0B        buildkit.dockerfile.v0
<missing>      8 days ago    RUN /bin/sh -c set -eux;     apt-get update;…   68.8MB    buildkit.dockerfile.v0
<missing>      8 days ago    ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_AL…   0B        buildkit.dockerfile.v0
<missing>      8 days ago    ENV PATH=/opt/java/openjdk/bin:/usr/local/sb…   0B        buildkit.dockerfile.v0
<missing>      8 days ago    ENV JAVA_HOME=/opt/java/openjdk                 0B        buildkit.dockerfile.v0
<missing>      6 weeks ago   /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>      6 weeks ago   /bin/sh -c #(nop) ADD file:249778a1782b02a1c…   87.6MB
<missing>      6 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      6 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      6 weeks ago   /bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH     0B        
<missing>      6 weeks ago   /bin/sh -c #(nop)  ARG RELEASE                  0B

Just like for the Chat app, the COPY Cogsi-1.0.0.jar /app/app.jar # buildkit is the only application-specific layer.
Version 2 is significantly smaller than the first version, because only thr final JAR is added.


docker history springapp:multi:

IMAGE          CREATED        CREATED BY                                      SIZE      COMMENT
d19bced32677   14 hours ago   ENTRYPOINT ["java" "-jar" "app.jar"]            0B        buildkit.dockerfile.v0
<missing>      14 hours ago   EXPOSE map[8080/tcp:{}]                         0B        buildkit.dockerfile.v0
<missing>      14 hours ago   COPY /build/build/libs/*.jar app.jar # build…   51MB      buildkit.dockerfile.v0
<missing>      14 hours ago   WORKDIR /app                                    8.19kB    buildkit.dockerfile.v0
<missing>      3 days ago     ENTRYPOINT ["/__cacert_entrypoint.sh"]          0B        buildkit.dockerfile.v0
<missing>      3 days ago     COPY --chmod=755 entrypoint.sh /__cacert_ent…   12.3kB    buildkit.dockerfile.v0
<missing>      3 days ago     RUN /bin/sh -c set -eux;     echo "Verifying…   12.3kB    buildkit.dockerfile.v0
<missing>      3 days ago     RUN /bin/sh -c set -eux;     ARCH="$(dpkg --…   165MB     buildkit.dockerfile.v0
<missing>      3 days ago     ENV JAVA_VERSION=jdk-21.0.9+10                  0B        buildkit.dockerfile.v0
<missing>      3 days ago     RUN /bin/sh -c set -eux;     apt-get update;…   49.6MB    buildkit.dockerfile.v0
<missing>      3 days ago     ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_AL…   0B        buildkit.dockerfile.v0
<missing>      3 days ago     ENV PATH=/opt/java/openjdk/bin:/usr/local/sb…   0B        buildkit.dockerfile.v0
<missing>      3 days ago     ENV JAVA_HOME=/opt/java/openjdk                 0B        buildkit.dockerfile.v0
<missing>      4 weeks ago    /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>      4 weeks ago    /bin/sh -c #(nop) ADD file:ddf1aa62235de6657…   87.6MB
<missing>      4 weeks ago    /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      4 weeks ago    /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B
<missing>      4 weeks ago    /bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH     0B
<missing>      4 weeks ago    /bin/sh -c #(nop)  ARG RELEASE                  0B

Multi-stage produces one again the smallest and most efficient final image, this is an ideal pattern for production Spring Boot deployments. 

### Final observations:

The docker history analysis clearly shows the impact of different build strategies on image size and composition.

Version 1 images are the heaviest because they include the full JDK, the Gradle wrapper, the cache of the build, all downloaded dependencies and the full
application source code. This makes them suitable for production environments.

Version 2 images are lighter since they only contain the final JAR produced on the host, and the runtime environment.
However the underlying base image (JDK) is still relatively heavy.

Multi-stage images are typically the smallest and cleanest because the build tools only exist on the first stage, and the final image contains only a lightweight JRE,
a compiled application JAR and a minimal runtime configuration.
This approach reduces significantly the final image size, improves security, minimizes attack surface and follows industry best practices for deploying Java apps in containers.

## Resource Usage Analysis (docker stats)

To evaluate runtime performance, docker stats was executed on the Version 2 images of both applications. Version 2 was selected because it contains only the JAR file and 
the minimal runtime environment, without additional build tools or Gradle caches, providing the cleanest and most representative runtime metrics.

Chat
docker run --name chatstats -p 59001:59001 chatapp:v2
docker stats chatstats

CONTAINER ID   NAME        CPU %     MEM USAGE / LIMIT     MEM %     NET I/O      BLOCK I/O   PIDS
46f0a2d8755e   chatstats   0.05%     69.58MiB / 15.57GiB   0.44%     1.5kB / 0B   0B / 0B     19  

This means that while the application is running, the CPU usage is extremely low as the server is waiting for client connections, the memory usage is average,
the PIDS means that JVM spawned a few internal threads, the network I/O was low since there were no messages being exchanged.

Spring
docker run --name springstats -p 8080:8080 springapp:v2
docker stats springstats

CONTAINER ID   NAME          CPU %     MEM USAGE / LIMIT     MEM %     NET I/O       BLOCK I/O   PIDS
37d895055116   springstats   0.11%     329.1MiB / 15.57GiB   2.06%     1.05kB / 0B   0B / 0B     46  

While the Spring app was running a heavier memory usage was registered, the CPU usage remained low since it was idle and the 46 PDSS reflect the many Spring threads such
as request workers, async handlers, background schedulers and JVM internals.

Both applications demonstrate low CPU usage during idle operation. The memory footprint differs significantly between the Chat (lightweight Java server) and the Spring Boot REST 
service (full-stack framework). These results confirm correct container operation and provide insight into expected runtime resource requirements.

Remove the containers:

docker rm -f chatstats springstats

## Publishing Images to Docker Hub

docker login

Chat
docker tag chatapp:v1 1240598/chatapp:v1
docker tag chatapp:v2 1240598/chatapp:v2
docker tag chatapp:multi 1240598/chatapp:multi

docker push 1240598/chatapp:v1
docker push 1240598/chatapp:v2
docker push 1240598/chatapp:multi

Spring
docker tag springapp:v1 1240598/springapp:v1
docker tag springapp:v2 1240598/springapp:v2
docker tag springapp:multi 1240598/springapp:multi

docker push 1240598/springapp:v1
docker push 1240598/springapp:v2
docker push 1240598/springapp:multi

Here the user was 1240598.

By accessing to https://hub.docker.com/u/1240598 we can clearly see the 2 reps and each of them has 3 tags that are the v1,v2 and multi.

## Errors Encountered and Solutions
Error 1: ./gradlew: not found

Cause: The build context did not include the full source code (only the JAR).
Fix: Copy all files from CA2 Part1 and CA2 Part2, including:

gradlew
gradlew.bat
gradle/
build.gradle
settings.gradle
src/

Error 2: Docker daemon not running

Error message:

open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified.


Cause: Docker Desktop was closed.
Fix: Open Docker Desktop → wait for "Docker is running".

Error 3: Building from the wrong directory

Cause: Running docker build from a folder that did not contain the full project.
Fix: Navigate to the project's root folder before building.

## Git Tag for Part 1
git add .
git commit -m "CA5 Part 1 completed"
git tag ca5-part1
git push origin ca5-part1
git push --tags

# Alteranatives to Docker

While Docker is one of the most widely used container platforms, there are several mature alternatives that provide different trade-offs in terms of 
performance, security, ecosystem support and integration with cloud environments.

## containerd

containerd is an industry-standard container runtime originally developed by Docker and now maintained under the Cloud Native Computing Foundation (CNCF).
It provides the core low-level functionality for running containers and is used internally by many platforms, including Kubernetes.

Use Cases:
Kubernetes container runtime
High-performance, low-level orchestration
Server environments where Docker is unnecessary overhead

Strengths:
Lightweight and minimal
CNCF-maintained
Production-grade and cloud-provider approved
Less overhead than Docker

Limitations:
No built-in image build tools
CLI is less user-friendly than Docker

## CRI-O

CRI-O is a Kubernetes-native container runtime created specifically to implement the Kubernetes Container Runtime Interface (CRI).
It is optimized for running containers in Kubernetes clusters with minimal components.

Use Cases:
Kubernetes environments
Enterprises requiring minimal attack surface
Systems focused on compliance and stability

Strengths:
Lightweight and secure
Designed specifically for Kubernetes
No daemon, minimal footprint
Backed by Red Hat

Limitations:

Not designed for standalone use
Requires Kubernetes to be meaningful

## LXC / LXD (Linux Containers)

LXC (lower level) and LXD (higher level management tool) provide system-level containers that behave more like lightweight virtual machines than traditional Docker containers.

Use Cases:
Running full Linux OS environments
Long-running services that require systemd
Infrastructure virtualization where Docker is too restrictive

Strengths:

Very lightweight compared to full virtual machines
Supports systemd and full init systems
Strong isolation

Limitations:

Less application-focused than Docker
Requires deeper understanding of Linux internals


## Comparison of Alternatives
| Feature / Runtime     | Docker            | containerd           | CRI-O               | LXC / LXD                    |
|-----------------------|-------------------|----------------------|---------------------|------------------------------|
| Target use            | General purpose   | Low-level runtime    | Kubernetes-native   | System-level containers      |
| Easy CLI              | Yes               | Minimal              | Minimal             | Yes (LXD)                    |
| Build Tools           | Yes               | No                   | No                  | No                           |
| Security footprint    | Medium            | Low                  | Very Low            | Medium                       |
| Supports systemd      | No                | No                   | No                  | Yes                          |
| Best for production   | Broad use cases   | Kubernetes, cloud    | Kubernetes only     | Lightweight VM-like workloads|
| Learning curve        | Low               | Medium               | Medium              | Higher                       |

Overall, the table shows that the choice of runtime depends heavily on the deployment context: Docker for general usage 
and developer experience, containerd for cloud-native production systems, CRI-O for Kubernetes-exclusive environments, and LXC/LXD for system-level virtualization.

## Why containerd is the best general-purpose choice:

It is the core runtime used by Docker itself, Kubernetes, AWS, Google Cloud, Azure, GitHub Actions, etc.

CNCF-maintained and neutral (open ecosystem)

Lower overhead and attack surface compared to Docker

Supported by all major cloud providers

Does not include unnecessary extras (builder, desktop GUI, daemon features)

## When containerd makes the most sense:

You want Docker-compatible performance without Docker’s overhead

You care about stability, security, and production readiness

You deploy to Kubernetes

You are running server environments

## Final Recommendation

containerd is the best overall alternative to Docker
because it is lightweight, cloud-native, production-grade, and widely used as the underlying runtime for Kubernetes and modern orchestration platforms.

For Kubernetes-exclusive environments, CRI-O may be even more appropriate, while LXC/LXD are suited for full system-level virtualization rather than application-level containers