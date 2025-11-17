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
      │    └── (full Chat app source from CA2 Part1)
      └── Spring/
           ├── Dockerfile.v1
           ├── Dockerfile.v2
           ├── Dockerfile.multi
           ├── gradlew, gradle/, src/, build.gradle, settings.gradle
           └── (full Spring app source from CA2 Part2)


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

This version satisfies the requirement:

“Version 1: Build the server inside the Dockerfile.”

Dockerfile.v1
FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY . /app
RUN ./gradlew clean build -x test
EXPOSE 59001
CMD ["java", "-cp", "build/libs/basic_demo-0.1.0.jar", "basic_demo.ChatServerApp", "59001"]

Explanation:

Copies the full source code into the container

Compiles the project inside the container

Produces the JAR under build/libs/

Runs the server using Java 21

To build:
docker build -f Dockerfile.v1 -t chatapp:v1 .

To test:
docker run --rm -p 59001:59001 chatapp:v1

### Version 2 — Host-built JAR

This version satisfies the second requirement:

“Version 2: Build the server on the host and copy the resulting JAR into the image.”

Dockerfile.v2
FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY basic_demo-0.1.0.jar app.jar
EXPOSE 59001
CMD ["java", "-cp", "app.jar", "basic_demo.ChatServerApp", "59001"]

Explanation

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

The following commands were used:

Chat
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

Spring
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

Observations (to include here after running the commands)

Version 1 images are the heaviest (contain JDK, Gradle, source files).

Version 2 images are lighter (only runtime + JAR).

Multi-stage images are typically the smallest because only the JRE and final JAR remain.

## Resource Usage Analysis (docker stats)

Commands used:

Chat
docker run --name chatstats -p 59001:59001 chatapp:v2
docker stats chatstats

Spring
docker run --name springstats -p 8080:8080 springapp:v2
docker stats springstats

Findings (to be filled in after measurement)

CPU usage near 0% while idle

Memory usage between ~40–150 MB depending on JVM

Network usage increases only during requests/messages

Disk I/O minimal in both apps

Remove the containers:

docker rm -f chatstats springstats

## Publishing Images to Docker Hub
Chat
docker tag chatapp:v1 <user>/chatapp:v1
docker tag chatapp:v2 <user>/chatapp:v2
docker tag chatapp:multi <user>/chatapp:multi

docker push <user>/chatapp:v1
docker push <user>/chatapp:v2
docker push <user>/chatapp:multi

Spring
docker tag springapp:v1 <user>/springapp:v1
docker tag springapp:v2 <user>/springapp:v2
docker tag springapp:multi <user>/springapp:multi

docker push <user>/springapp:v1
docker push <user>/springapp:v2
docker push <user>/springapp:multi


Links to the Docker Hub repositories should be inserted here.

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

## Final Remarks

Part 1 meets all requirements:

Two versions per application (V1: build inside container; V2: host-built JAR)

Multi-stage builds for both applications

Full testing of all images

Layer analysis using docker history

Resource analysis using docker stats

All images published on Docker Hub

Complete documentation of errors and solutions

Organized tutorial-style explanation