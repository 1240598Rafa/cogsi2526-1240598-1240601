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

To test:
docker run --rm -p 59001:59001 chatapp:v2

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

Stage 1:

FROM - uses JDK
WORKDIR - sets /build as working directory
COPY - copies all source files into the builder container
RUN - Executes the full Gradle build

Stage 2:

FROM - uses a lighweight JRE which doesn't include compilers and tools so it improves the image size and the startup time
WORKDIR - is set to /app
COPY - copies only the compiled JAR from the build stage into the runtime stage
EXPOSE - exposes port 59001
CMD - lauches the chat server inside the container

Why this version is better:
The build stage includes JDK + Gradle
The runtime stage uses only the small JRE
The final image is significantly lighter and safer

This is the recommended production practice

To build:
docker build -f Dockerfile.multi -t chatapp:v3 .

To test:
docker run --rm -p 59001:59001 chatapp:v3

## Spring Application
### Version 1 - Build inside the container
Dockerfile
FROM eclipse-temurin:21-jdk AS build
RUN apt-get update && apt-get install -y git
WORKDIR /app
RUN git clone https://github.com/spring-guides/gs-rest-service.git .
WORKDIR /app/complete
RUN ./gradlew build

FROM eclipse-temurin:21-jdk 
COPY --from=build /app/complete/build/libs/rest-service-0.0.1-SNAPSHOT.jar /app/app.jar
WORKDIR /app
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]

FROM - uses a JDK base image that is required since the app will the compiled inside the container.
WORKDIR - sets the /app as the working directory.
COPY - copies the entire working directory, allowing commands to be run inside this directory.
RUN - executes the gradle build process inside the image.
EXPOSE - the container will listen on port 8080.
CMD - Starts the Spring Boot app when the container runs.

The Spring Boot Version 1 Dockerfile is more complex than the Chat server Version 1 because the Spring Boot project originates from a GitHub template that already uses a two-stage structure, requires Git installation, and contains a multi-folder layout (“complete” folder). The Chat server project, in contrast, exists entirely in the local repository, has a simpler structure, and does not require external dependencies or cloning.

Both Version 1 implementations fulfil the same requirement (“build inside the container”), but their Dockerfiles differ because the applications themselves differ in structure, origin, tooling and complexity.

To build:
docker build -f Dockerfile -t springapp:v1 .

To test:
docker run --rm -p 8080:8080 springapp:v1

### Version 2 — Host-built JAR
Dockerfile.v2
FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY build/libs/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]

FROM - uses a JDK base image.
WORKDIR - sets the /app as the working directory.
COPY - only the final Spring Boot JAR is copied.
RUN - executes the gradle build process inside the image.
EXPOSE - the container will listen on port 8080.
CMD - Starts the Spring Boot app.

To build:
docker build -f Dockerfile.v2 -t springapp:v2 .

To test:
docker run --rm -p 8080:8080 springapp:v2

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

Stage 1:

FROM - uses JDK as base image
WORKDIR - sets /build as working directory
COPY - copies the entire Spring project into the container
RUN - executes the spring boot build inside the container which will then store a JAR

Stage 2:

FROM - uses a JRE which has no compilers or dev tools
WORKDIR - sets /app as the working directory
COPY - copies only the HAR from the build stage
EXPOSE - uses por 8080
ENTRYPOINT - entrypoint was used instead of CMD so the container behaves like a dedicvated app server.


Explanation

Same multi-stage approach used for Chat
Produces the smallest and cleanest final image
No source code or build tooling exists in the final container

To build:
docker build -f Dockerfile.multi -t springapp:v3 .

To test:
docker run --rm -p 8080:8080 springapp:v3

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
Fix: Open Docker Desktop - wait for "Docker is running".

Error 3: Building from the wrong directory

Cause: Running docker build from a folder that did not contain the full project.
Fix: Navigate to the project's root folder before building.

## Git Tag for Part 1
git add .
git commit -m "CA5 Part 1 completed"
git tag ca5-part1
git push origin ca5-part1
git push --tags

# CA5 – Part 2: Dockerized Spring Boot Application with H2 Database

This project implements Part 2 of CA5, whose goal is to containerize the Spring Boot (Gradle) application from CA2/Part2 using **Docker** and **Docker Compose**.  
The final architecture consists of two isolated containers:

- `web` — runs the Spring Boot application  
- `db` — runs the H2 database server in TCP mode  

Both containers interact over an internal Docker network and start in the correct order using Docker health checks.  
The application image is built from a Dockerfile and **published on Docker Hub**.

---

## 1. Project Architecture Overview

### **db container**
- Based on `eclipse-temurin:21-jdk`
- Installs required tools (`wget`, `netcat-openbsd`)
- Downloads the H2 JAR directly from Maven Central
- Runs H2 in TCP server mode (`-tcp -tcpAllowOthers -tcpPort 9092`)
- Uses a Docker volume to persist data
- Provides a health check to ensure readiness

### **web container**
- Built from a custom Dockerfile
- Installs Gradle, Git, Java, and other tools
- Clones the required GitHub repository (mandatory for the assignment)
- Builds the Spring Boot project using the Gradle wrapper
- Runs the generated JAR
- Pulled from Docker Hub by Docker Compose

---

## 2. Dockerfile (Application Image)

This Dockerfile replicates the behaviour previously implemented using Vagrant provisioning scripts.  
It installs all dependencies, clones the repository, builds the application, and runs the resulting JAR.

```dockerfile
FROM eclipse-temurin:21-jdk

WORKDIR /app

RUN apt-get update -y &&     apt-get install -y git gradle wget unzip &&     rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/1240598Rafa/cogsi2526-1240598-1240601.git /app/repo

WORKDIR /app/repo/CA2/Part2

RUN chmod +x gradlew

RUN ./gradlew clean build -x test

EXPOSE 8080

CMD ["sh", "-c", "java -jar build/libs/*0.0.jar"]
```

### **Purpose of this Dockerfile**
- Ensures a reproducible build environment  
- Avoids dependency issues across systems  
- Automatically compiles the Spring Boot project  
- Produces a runnable container image  
- Encapsulates the entire application inside a portable artifact  

The final image is pushed to Docker Hub as:

```
xavidocker99/part2-web:latest
```

---

## 3. Docker Compose File

This Compose file defines both containers (`web` and `db`), their dependencies, shared networks, volumes, and startup order.

```yaml
version: '3.9'

services:
  db:
    image: eclipse-temurin:21-jdk
    container_name: h2-db
    working_dir: /opt/h2
    command: >
      sh -c "
        apt-get update -y &&
        apt-get install -y wget netcat-openbsd &&
        wget -q https://repo1.maven.org/maven2/com/h2database/h2/2.2.224/h2-2.2.224.jar -O h2.jar &&
        java -cp h2.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -ifNotExists
      "
    ports:
      - "9092:9092"
    volumes:
      - h2_data:/opt/h2
    healthcheck:
      test: ["CMD", "nc", "-z", "localhost", "9092"]
      interval: 3s
      timeout: 3s
      retries: 10
    networks:
      - backend

  web:
    image: xavidocker99/part2-web:latest
    container_name: spring-web
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8080:8080"
    networks:
      - backend

volumes:
  h2_data:

networks:
  backend:
    driver: bridge
```

---

## 4. Purpose of Each Section in Docker Compose

### **services.db**
Runs the H2 database server.  
It includes:
- Commands to install tools and download the H2 JAR  
- Startup command for H2 in TCP mode  
- Port mapping for external access  
- Health check to ensure the DB is ready before the web container starts  

### **services.web**
Runs the Spring Boot application.  
It includes:
- The image hosted on Docker Hub  
- A dependency ensuring that the database is fully ready  
- Port exposure for browser access  
- Connection to the same internal network as the DB  

### **volumes**
Defines persistent storage for H2 database files, ensuring data survives container restarts.

### **networks**
Creates an isolated Docker network that guarantees communication only between defined services.

---

## 5. Publishing the Application Image to Docker Hub

### 1. Tag the local image:
```
docker tag part2-web:latest xavidocker99/part2-web:latest
```

### 2. Login to Docker Hub:
```
docker login
```

### 3. Push the image:
```
docker push xavidocker99/part2-web:latest
```

The image is now publicly available at:

https://hub.docker.com/r/xavidocker99/part2-web

---

## 6. Running the Project

### Start all containers:
```
docker compose up
```

### Or pull updated images:
```
docker compose pull
docker compose up
```

### Application available at:
http://localhost:8080/

---

## 7. Git Tag for Submission

The final commit was tagged as required:

```
git tag ca5-part2
git push origin ca5-part2
```


# 2. Alternative Solution (Non-Docker Approach)

This alternative leverages:

- **containerd** (CNCF runtime used by Docker & Kubernetes)  
- **nerdctl** (Docker-compatible CLI)  
- **buildkit** (OCI image builder)  
- **CNI plugins** (networking)  

Together, these components reproduce nearly all Docker/Compose functionality.

---

## 2.1 Why containerd?

containerd is the official container runtime used by major cloud platforms:

- Docker  
- Kubernetes  
- AWS, Azure, Google Cloud  
- GitHub Actions  

### Strengths
- Lightweight  
- Production-grade  
- CNCF-maintained  
- Lower overhead than Docker  
- Strong security guarantees  

### Limitations
- No native Dockerfile support  
- Requires additional tooling (buildkit and nerdctl)  

---

## 2.2 Install containerd

```bash
sudo apt update
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
```

---

## 2.3 Install CNI Plugins

```bash
sudo mkdir -p /opt/cni/bin
curl -L -o cni.tgz https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz
sudo tar -C /opt/cni/bin -xzf cni.tgz
```

---

## 2.4 Install buildkit

```bash
sudo apt install -y buildkit
sudo systemctl enable --now buildkit
```

---

## 2.5 Install nerdctl

```bash
VERSION=1.7.4
curl -L https://github.com/containerd/nerdctl/releases/download/v${VERSION}/nerdctl-${VERSION}-linux-amd64.tar.gz -o nerdctl.tgz
sudo tar -xzf nerdctl.tgz -C /usr/local/bin
```

---

## 2.6 Alternative compose.yaml for nerdctl

```yaml
version: "3.9"

services:
  db:
    image: eclipse-temurin:21-jdk
    command: >
      sh -c "
        apt-get update -y &&
        apt-get install -y wget netcat-openbsd &&
        wget -q https://repo1.maven.org/maven2/com/h2database/h2/2.2.224/h2-2.2.224.jar -O h2.jar &&
        java -cp h2.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -ifNotExists
      "
    ports:
      - "9092:9092"
    volumes:
      - h2-data:/opt/h2
    healthcheck:
      test: ["CMD", "nc", "-z", "localhost", "9092"]

  web:
    build:
      context: app
      dockerfile: Dockerfile
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8080:8080"

volumes:
  h2-data:
```

---

## 2.7 Running with nerdctl

### Build:

```
nerdctl build -t part2-web:latest app/
```

### Run:

```
nerdctl compose up
```

### Push to Registry:

```
nerdctl tag part2-web xavidocker99/part2-web
nerdctl push xavidocker99/part2-web
```

---

# 3. Comparison of Container Alternatives

| Feature / Runtime     | Docker            | containerd           |
|-----------------------|-------------------|----------------------|
| Target use            | General purpose   | Low-level runtime    | 
| Easy CLI              | Yes               | Minimal              | 
| Build Tools           | Yes               | No                   | 
| Security footprint    | Medium            | Low                  | 
| Supports systemd      | No                | No                   | 
| Best for production   | Broad use cases   | Kubernetes, cloud    | 
| Learning curve        | Low               | Medium               | 

---

# 4. Final Recommendation

containerd is the most realistic and production-oriented alternative to Docker.  
When enhanced with **nerdctl**, **buildkit**, and **CNI**, it replicates most Docker Compose features while offering:

- lower overhead  
- cloud-native architecture  
- CNCF governance  
- strong integration with Kubernetes  

For Kubernetes-only deployments, **CRI-O** may be preferred.  
For system-level virtualization, **LXC/LXD** is more appropriate.  