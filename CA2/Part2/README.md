# CA2 – Part 2: Gradle Build Tools (Spring Boot “links” → Gradle)
# Overview

This Part2 converts the Spring Guides “Building REST Services with Spring” (tut-rest/links) sample from Maven to Gradle, then adds custom Gradle tasks:

deployToDev – prepares a development deployment directory.

runDist – runs the app through a Gradle task (no Maven).

zipJavadoc – generates and zips Javadoc.

integrationTest – separate source set and task for integration tests.

The project name is cogsi and it runs on port 8080.

#Step 1 — Get the source and verify (Maven)

git clone https://github.com/spring-guides/tut-rest.git
cd tut-rest/links
../mvnw spring-boot:run
Open http://localhost:8080/employees

This confirms the original sample works.

# Step 2 — Create a clean Gradle project (Wrapper)

Created an empty folder for Part 2 and initialized Gradle

mkdir Part2
cd Part2
gradle init --type java-application

# Step 3 — Copy to Part 2 the Spring links folder

Replace the generated src with the links src
Create settings.gradle:
rootProject.name = 'cogsi'

# Step 4 — Gradle build file

# Java and Application Setup

Configured in build.gradle:

java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

application {
    mainClass = 'payroll.PayrollApplication'
}


Explanation:
Defines Java 21 as the build version and tells Gradle which class contains main().

# Task: runDist
task runDist(type: JavaExec) {
    dependsOn installDist
    group = "application"
    description = "Run the app from the generated distribution"
    mainClass = 'payroll.PayrollApplication'
    classpath = sourceSets.main.runtimeClasspath
}


What it does:
Runs the Spring Boot app through Gradle directly, avoiding Windows long-path issues with the .bat file.

# Task: deployToDev

task deployToDev {
    group = "deployment"
    description = "Deploy to dev environment"

    def deployDir = file("build/deployment/dev")

    tasks.register("cleanDev", Delete) {
        delete deployDir
    }

    tasks.register("copyJar", Copy) {
        dependsOn bootJar
        from(tasks.named("bootJar").get().archiveFile)
        into deployDir
    }

    tasks.register("copyLibs", Copy) {
        dependsOn "copyJar"
        from configurations.runtimeClasspath
        into "${deployDir}/lib"
    }

    tasks.register("copyConfig", Copy) {
        dependsOn "copyLibs"
        from("src/main/resources") {
            include "*.properties"
            filter(org.apache.tools.ant.filters.ReplaceTokens, tokens: [version: project.version])
        }
        into("${deployDir}/config")
    }

    dependsOn "cleanDev", "copyJar", "copyLibs", "copyConfig"
}


What it does:
Deletes any previous deployment folder.
Copies the built JAR.
Copies only runtime dependencies into /lib.
Copies configuration files (.properties) into /config replacing version tokens.
Result: A ready-to-run deployment at build/deployment/dev.

# Task: zipJavadoc
task zipJavadoc(type: Zip) {
    dependsOn javadoc
    group = "documentation"
    description = "Generate and zip the project Javadoc"
    from javadoc.destinationDir
    archiveFileName = "javadoc-${version}.zip"
    destinationDirectory = file("$buildDir/docs")
}


What it does:
Builds the project’s Javadoc and compresses it into a ZIP file stored in build/docs.

# Integration Tests
Source Set
sourceSets {
    integrationTest {
        java.srcDir file('src/integrationTest/java')
        resources.srcDir file('src/integrationTest/resources')
        compileClasspath += sourceSets.main.output + configurations.testRuntimeClasspath
        runtimeClasspath += output + compileClasspath
    }
}


Purpose:
Creates a separate folder (src/integrationTest/java) for integration tests, independent from unit tests.

# Task integrationTest

task integrationTest(type: Test) {
    description = 'Run integration tests'
    group = 'verification'
    testClassesDirs = sourceSets.integrationTest.output.classesDirs
    classpath = sourceSets.integrationTest.runtimeClasspath
    shouldRunAfter test
    useJUnitPlatform()
    failOnNoDiscoveredTests = false
}


Purpose:
Runs all integration tests using JUnit 5 after unit tests.
The failOnNoDiscoveredTests avoids errors if no tests are found.

# Example Integration Test:
src/integrationTest/java/com/example/IntegrationTest.java

package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class IntegrationTest {
    @Test
    public void testEnvironmentIsWorking() {
        assertTrue(true);
    }
}


Run with:
.\gradlew integrationTest

# Summary

| Task              | Description                                             | Example Command             |
| ----------------- | ------------------------------------------------------- | --------------------------- |
| `runDist`         | Runs the built app via Gradle                           | `.\gradlew runDist`         |
| `deployToDev`     | Creates a dev deployment folder with JAR, libs, configs | `.\gradlew deployToDev`     |
| `zipJavadoc`      | Generates and zips the Javadoc                          | `.\gradlew zipJavadoc`      |
| `integrationTest` | Executes integration tests                              | `.\gradlew integrationTest` |


# Common Issues and Fixes

“Could not set unknown property ‘sourceCompatibility’”
Add id 'java' plugin and use the java { … } block or JavaVersion.VERSION_21.

Toolchain wants Java 17
Remove the toolchain block and set Java 21 as above, or install JDK 17.

HATEOAS classes not found (EntityModel, CollectionModel)
Add implementation 'org.springframework.boot:spring-boot-starter-hateoas'.

Windows “The input line is too long” with .bat
Use runDist with JavaExec (already configured) instead of calling the batch script.

Integration tests not discovered
Ensure file path matches package, class and method are public, and useJUnitPlatform() is set.

# Useful Commands
.\gradlew clean build
.\gradlew bootRun
.\gradlew runDist
.\gradlew zipJavadoc
.\gradlew deployToDev
.\gradlew integrationTest
