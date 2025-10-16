# CA2 - Part 1: Gradle Basic Demo

## Setup

This part of the assignment dealt with learning Gradle build automation.
The following Java project was used as the reference application: gradle_basic_demo

The following steps were executed to set up the project and introduce new Gradle tasks:


### Create directory, clone and prepare the demo project
It was asked to:

"
You should start by downloading and pushing to your
repository (in a folder for Part 1 of CA2) the sample application
▪ https://github.com/lmpnogueira/gradle_basic_demo
▪ You will be working with this application in Part 1
"

So we started by creating a new directory and cloning the rep:

mkdir CA2\Part1
cd CA2\Part1

git clone https://github.com/lmpnogueira/gradle_basic_demo.git tmp_gradle_demo
Copy-Item -Recurse tmp_gradle_demo\* .
Remove-Item -Recurse -Force tmp_gradle_demo\.git
Remove-Item -Recurse -Force tmp_gradle_demo

These commands fetch the demo project officially, copy the contents of this demo to our newly created CA2/Part1 directory, 
and remove any previous Git history (.git) so that this project is ours. 

### Tag initial Version
Then it was asked to:

"
Use tags to mark the versions of the application
▪ You should use a pattern major.minor.revision (e.g., 1.1.0)
▪ Tag the initial version as ca2-1.1.0 and push the tag to the server
"

git tag ca2-1.1.0
git push origin ca2-1.1.0

This way we identified the push to the server

### Build and run the base project

We run the following commands to make sure the base project would run:

.\gradlew.bat build
.\gradlew.bat run

The Gradle Wrapper (gradlew.bat) will download the appropriate Gradle version automatically.
The project builds successfully and shows a message in the terminal window.

## Gradle Task Extensions

It was then asked to:

"
Add a new runServer Gradle task to execute the server
"

So we modified the build.gradle file in order to include Gradle tasks and test configurations:

"
tasks.register('runServer', JavaExec) {
    group = "DevOps"
    description = "Launches the chat server application"
    classpath = sourceSets.main.runtimeClasspath
    mainClass = 'basic_demo.ChatServerApp'
}
"

This code runs the Java class basic_demo.ChatServerApp directly with Gradle, rather than by hand with java -jar.

And after running:

.\gradlew.bat runServer

Gradle starts the server and prints console messages to inform it is running correctly.

### Add and run a unit test

It was then asked to

"Add a simple unit test and update the Gradle build script so that it can execute the test"

Since the demo project didn’t include any tests, a new one was created on src\test\java\basic_demo\AppTest.java with the following code:

"
package basic_demo;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class AppTest {
    @Test
    void testAppRuns() {
        assertEquals(2, 1 + 1, "Gradle test environment working");
    }
}
"
Explanation of the code:
1. package basic demo - declares that this class belongs to the same package as the application source files (basic_demo), this ensure the test can access package-level
classes or methods if needed

2. org.junit.jupiter.api.Test - imports the @Test annotations from JUnit 5 (Jupiter API), this was made because the annotation marks a method as a test case so that
Gradle can automatically detect and execute it

3. org.junit.jupiter.api.Assertions.* - imports all static assertion methods such as assertEquals(), this allows a use of concise test statements instead of
using fully qualified names

4. @Test - This annotation identifies the following method as an executable test, and runs it via JUnit test runner

5. testAppRuns() - tests if the test framwork is running correctly

6. assertEquals(2, 1 + 1, "Gradle test environment working") - verifies if 1+1=2, this is called a sanity check, it proves that the JUnit library is available,
it proves that Gradle's test task is correctly running and the environment supports automated testing

As mentioned before the goal wasn't to validate logic but only to verify that Gradle test environment is functioning correctly.

The necessary dependecies were added to build.gradle:

"
dependencies {
    testImplementation 'org.junit.jupiter:junit-jupiter-api:5.10.0'
    testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.10.0'
}
test {
    useJUnitPlatform()
}
"
This dependency includes JUnit 5 API(provdides the annotation, the assertion classes and core interface) and JUnit Jupiter Engine (responsible for executing the tests at runtime)

With this additions we can verify that Gradle correctly compiles and runs JUnit 5 tests by using the command:

.\gradlew.bat test

Expected Output:
> Task :test
BUILD SUCCESSFUL in 2s
1 test passed

This verifies that the Gradle environment is functional

### Create a backup task

It was then asked to:

"
Add a new task of type Copy to be used to make a backup of the sources of the application
▪ It should copy the contents of the src folder to a new backup folder
"

So the the following code was added to build.gradle, in order to demostrate how Gradle automates file operations:

"
tasks.register('backup', Copy) {
    group = "Backup"
    description = "Copies the source code to a backup folder"
    from 'src'
    into 'backup'
}
"
.\gradlew.bat backup

With this command we expect a new folder named /backup/ to appear in the project directory, containing a full copy of the /src/ folder.

### Create a zipBackup task

"Add a new task of type Zip to be used to make an archive (i.e.,a zip file) of the backup of the application
▪ This tasks should depend on the execution of the backup task
"

This code was added to build.gradle in order to automatically compress the backup into a .zip:

"
tasks.register('zipBackup', Zip) {
    dependsOn backup
    group = "Backup"
    description = "Creates a zip archive of the backup folder"
    from 'backup'
    archiveFileName = 'backup.zip'
    destinationDirectory = file("$buildDir/archives")
}
"

.\gradlew.bat zipBackup

With this command a file 'backup.zip' is generated under build/archives/backup.zip

## Gradle Wrapper and JDK Toolchain

"Explain how the Gradle Wrapper and the JDK Toolchain ensure the correct versions of Gradle and the Java Development Kit are used without requiring manual installation
▪ In the root directory of the application, run “./gradlew –q javaToolchain” and explain the output"

### Gradle Wrapper (gradlew / gradlew.bat)

The Gradle Wrapper is a very small bootstrap process that makes all users or CI/CD systems build the project with the same version of Gradle, even if Gradle is not present on the machine.
If you execute

.\gradlew.bat build

Gradle does not rely on any globally installed version but the following happens instead:

    The script gradlew.bat (Windows) or gradlew (Linux/macOS) calls the Java class org.gradle.wrapper.GradleWrapperMain.
    This class reads the configuration file located at:

    gradle/wrapper/gradle-wrapper.properties

    Inside that file, the property:

    distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip

    Explicitly defines the exact Gradle distribution (version, type, and URL) required for the project.

    If that version is not already present on the machine, the wrapper automatically downloads and caches it under:

    USER_HOME/.gradle/wrapper/dists/

    The build thereafter executes with that cached distribution, offering reproducible behavior in all environments.

To summarize:

The Gradle Wrapper removes the need for manual installation.
All developers and build agents execute the same same version of Gradle specified in the repository.
This avoids the "works on my machine" problem.

### JDK Toolchain

The JDK Toolchain feature guarantees that Gradle compiles the project with the correct version of the Java Development Kit (JDK) irrespective of local JDK installations.

This configuration in build.gradle appears as follows:

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(17)
    }
}


When Gradle runs, it performs the following actions:

    Gradle will check for JDKs available in the environment (through environment variables, standard installation directories, and Gradle's registry).

    If a JDK version 17 is available, it will compile and execute with that single one.

    If none of these are found suitable, Gradle is able to download it automatically through its Toolchain Provisioning (from Gradle 7+).
    The download location is managed under:

    USER_HOME/.gradle/jdks/

    Gradle subsequently compiles and runs the project using that JDK, rather than the system default.

Command to test toolchain:

.\gradlew.bat -q javaToolchain

Output:

Toolchain resolution for Java 17 from vendor Eclipse Adoptium was successful

This ensures that Gradle discovered or provisioned the correct JDK and is running with it for the build.

### Combined Effect

The Gradle Wrapper in combination with the JDK Toolchain makes builds fully reproducible:

Everyone uses the same Gradle version (defined in gradle-wrapper.properties).
Everyone builds with the same Java version (defined in build.gradle).
No manual setup is required — Gradle and the JDK can be downloaded and cached automatically.
What this boils down to is that every build executes to precisely the same output, whether it's executed on Windows, macOS, Linux, or a cloud CI/CD runner.

## Final Commit and Tag

"
At the end of the assignment mark your commit with the tag
ca2-part1
"

git add .
git commit -m "Add Gradle tasks: runServer, test, backup, zipBackup"
git push origin main
git tag ca2-part1
git push origin ca2-part1

This commands are used to commit the changes and add a tag so we can version-control all changes and mark the completion of Part 1 with the tag ca2-part1

# CA2 - Part 2

## Gradle Build Tools (Spring Boot “links” → Gradle)

## Overview

This Part2 converts the Spring Guides “Building REST Services with Spring” (tut-rest/links) sample from Maven to Gradle, then adds custom Gradle tasks:

deployToDev – prepares a development deployment directory.

runDist – runs the app through a Gradle task (no Maven).

zipJavadoc – generates and zips Javadoc.

integrationTest – separate source set and task for integration tests.

The project name is cogsi and it runs on port 8080.

### Step 1 — Get the source and verify (Maven)

git clone https://github.com/spring-guides/tut-rest.git

cd tut-rest/links

../mvnw spring-boot:run

Open http://localhost:8080/employees

This confirms the original sample works.

### Step 2 — Create a clean Gradle project (Wrapper)

Created an empty folder for Part 2 and initialized Gradle

mkdir Part2

cd Part2

gradle init --type java-application

### Step 3 — Copy to Part 2 the Spring links folder

Replace the generated src with the links src

Create settings.gradle:

rootProject.name = 'cogsi'

### Step 4 — Gradle build file

#### Java and Application Setup

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

#### Task: runDist
task runDist(type: JavaExec) {

    dependsOn installDist
    group = "application"
    description = "Run the app from the generated distribution"
    mainClass = 'payroll.PayrollApplication'
    classpath = sourceSets.main.runtimeClasspath
    
}


What it does:

Runs the Spring Boot app through Gradle directly, avoiding Windows long-path issues with the .bat file.

#### Task: deployToDev

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

#### Task: zipJavadoc
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

#### Integration Tests
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

#### Task integrationTest

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

#### Example Integration Test:
src/integrationTest/java/com/example/IntegrationTest.java

public class IntegrationTest {
   
    @Test
    public void testEnvironmentIsWorking() {
        assertTrue(true);
    }
}


Run with:

.\gradlew integrationTest

### Summary

| Task              | Description                                             | Example Command             |
| ----------------- | ------------------------------------------------------- | --------------------------- |
| `runDist`         | Runs the built app via Gradle                           | `.\gradlew runDist`         |
| `deployToDev`     | Creates a dev deployment folder with JAR, libs, configs | `.\gradlew deployToDev`     |
| `zipJavadoc`      | Generates and zips the Javadoc                          | `.\gradlew zipJavadoc`      |
| `integrationTest` | Executes integration tests                              | `.\gradlew integrationTest` |


#### Common Issues and Fixes

Could not set unknown property ‘sourceCompatibility’

Add id 'java' plugin and use the java { … } block or JavaVersion.VERSION_21.

---

HATEOAS classes not found (EntityModel, CollectionModel)

Add implementation 'org.springframework.boot:spring-boot-starter-hateoas'.

---

Windows “The input line is too long” with .bat

Use runDist with JavaExec (already configured) instead of calling the batch script.

---

Integration tests not discovered

Ensure file path matches package, class and method are public, and useJUnitPlatform() is set.

### Useful Commands
.\gradlew clean build

.\gradlew bootRun

.\gradlew runDist

.\gradlew zipJavadoc

.\gradlew deployToDev

.\gradlew integrationTest

## Alternative to Gradle

### Alternatives Study

Gradle is one of many build automation tools that can be utilized for Java projects.
Apache Maven, Apache Ant, and Bazel are some other alternatives being considered.
All of them aim to automate software compilation, testing, packaging, and release but are different in structure, extensibility, and simplicity.

### Apache Maven

Maven is a highly used build automation and dependency management tool.
It uses a declarative XML-based configuration file (pom.xml) where the developers define the project structure, dependencies, plugins, and goals.

Comparison to Gradle:

Configuration Language: XML (static, verbose) vs. Gradle's Groovy/Kotlin DSL (dynamic, expressive).
Dependency Management: Both use Maven Central repositories, but Gradle resolves dependencies faster with incremental caching.
Extensibility: Maven can support plugins but is less extensible; Gradle supports fully programmable logic.
Performance: Gradle incremental build and build cache do better on large projects.
Learning Curve: Maven has a simpler start but is weaker in terms of advanced automation.

Example of equivalent Maven configuration:
"
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>org.example</groupId>
  <artifactId>demo</artifactId>
  <version>1.0.0</version>
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.11.0</version>
        <configuration>
          <source>17</source>
          <target>17</target>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
"

This pom.xml accomplishes the exact same thing as Gradle's build.gradle, but is less compact and more challenging to add dynamic logic to extend.

### Apache Ant

Ant is an extremely ancient build tool that is procedural task-based in XML only.
It does not have built-in dependency management; the authors must configure it explicitly by installing libraries or using Ivy.

Comparison with Gradle:

Configuration Style: Imperative task-based (rather than declarative as in Maven or Gradle).
Dependency Management: Manual (via Ivy), as opposed to Gradle's automatic resolution of dependencies.
Flexibility: Highly customizable but verbose and repetitive.
Performance: Unreliable and slower, with no incremental build caching.

Ant is suitable for extremely tiny or vintage projects but not suitable for contemporary dependency-based software.

### Bazel

Bazel (by Google) is a next-generation, high-performance build tool that is language-agnostic (Java, C++, Python, etc.).
All about reproducibility and parallelism.

What makes it different from Gradle:

Performance: Ultra-high-performance, faster, and very scalable, most suitable for monorepos.
Configuration Language: It has its own Starlark language (similar to Python).
Ecosystem: More complex and less traditional in Java development.
Integration: Gradle is more integrated in the Java and Spring Boot ecosystem.

Bazel is good but overkill for smaller to medium Java projects such as this assignment.

### Comparison Summary

Overall, Maven is simple and trustworthy but verbose and inflexible.
Ant is manually initiated and adaptable but ancient and lacks contemporary dependency management.
Bazel is extremely powerful and scalable but too complicated for typical Java development.
Gradle, on the other hand, borrows the best of all these tools: Maven's lifecycle-based model, Ant's programmability, and Bazel's incremental performance — in a concise and readable Groovy or Kotlin DSL.

Gradle is quicker thanks to its incremental build engine and cache, easily scriptable by scripting, and IDE-friendly, CI/CD pipeline-friendly, and frameworks such as Spring Boot-friendly.
This makes it the most effective and well-rounded solution for the majority of contemporary Java projects.



### Why Gradle is the Best Opion

Gradle combines the best of both worlds — convenience of Maven and flexibility of Ant — and brings with it the advantages of performance optimization of recent times.
Its Groovy/Kotlin DSL enables developers to script multi-step procedures like automated backups, zipping, deployment, and testing in just a few lines.
Gradle Wrapper ensures that all developers use the same Gradle version to build the project, which gives more uniformity among environments.
Also, Gradle integrates very well with IDEs (IntelliJ IDEA, VS Code, Eclipse) and DevOps tools and thus is the de facto standard for Spring Boot and Android projects.

In short:

Gradle is faster (caching and incremental builds).
Gradle is more expressive (DSL scripting instead of XML).
Gradle is more integrated in newer systems like Spring Boot and CI/CD pipelines.
Due to these, Gradle was selected to be utilized as the major build automation tool for this project.

# Grade Division

Rafael Ferreira - 50%
Xavier Ricarte - 50%