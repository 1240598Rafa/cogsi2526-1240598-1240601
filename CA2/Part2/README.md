# CA2 – Part 2: Gradle Build Tools (Spring Boot “links” → Gradle)

# Overview

This Part2 converts the Spring Guides “Building REST Services with Spring” (tut-rest/links) sample from Maven to Gradle, then adds custom Gradle tasks:

deployToDev – prepares a development deployment directory.

runDist – runs the app through a Gradle task (no Maven).

zipJavadoc – generates and zips Javadoc.

integrationTest – separate source set and task for integration tests.

The project name is cogsi and it runs on port 8080.

# Step 1 — Get the source and verify (Maven)

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

## Java and Application Setup

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

## Task: runDist
task runDist(type: JavaExec) {

    dependsOn installDist
    group = "application"
    description = "Run the app from the generated distribution"
    mainClass = 'payroll.PayrollApplication'
    classpath = sourceSets.main.runtimeClasspath
    
}


What it does:

Runs the Spring Boot app through Gradle directly, avoiding Windows long-path issues with the .bat file.

## Task: deployToDev

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

## Task: zipJavadoc
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

## Integration Tests
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

## Task integrationTest

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

## Example Integration Test:
src/integrationTest/java/com/example/IntegrationTest.java

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

# Useful Commands
.\gradlew clean build

.\gradlew bootRun

.\gradlew runDist

.\gradlew zipJavadoc

.\gradlew deployToDev

.\gradlew integrationTest

### Implementation Design Using Maven

If Maven were used instead of Gradle, the same results could be achieved through a pom.xml configuration file that defines the project’s structure, dependencies, plugins, 
and lifecycle phases.

1. Project Structure

The Maven project would follow the standard directory layout:

/src
 ├── main/java          → application source code
 ├── test/java          → unit tests (JUnit)
 └── resources           → configuration and data files
/pom.xml                 → build and dependency configuration

This structure is enforced automatically by Maven, and most IDEs (IntelliJ, Eclipse, VS Code) recognize it without needing extra setup.

2. Declaring Dependencies

Inside the pom.xml, dependencies would be added under the <dependencies> section.
For example, to include Log4J and JUnit 5 (they are showned bellowed respectively) as used in the Gradle project:

<dependencies>
  <dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-core</artifactId>
    <version>2.11.2</version>
  </dependency>
  <dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-api</artifactId>
    <version>2.11.2</version>
  </dependency>

  <dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter-api</artifactId>
    <version>5.10.0</version>
    <scope>test</scope>
  </dependency>
  <dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter-engine</artifactId>
    <version>5.10.0</version>
    <scope>test</scope>
  </dependency>
</dependencies>

This will automatically download all libraries from Maven Central during the build.

3. Configuring the Build and Java Version

To ensure the same JDK version is used, Maven uses the maven-compiler-plugin:

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

This is the equivalent of the java { toolchain { languageVersion = 17 } } block in Gradle.

4. Automating Custom Tasks

Gradle enables defining tasks such as backup and zipBackup using Groovy code.
In Maven, this is accomplished with plugins, since Maven does not have a way of directly executing Groovy logic.

To copy files (like a backup), the maven-antrun-plugin or maven-resources-plugin can be utilized.

To create a .zip file, to utilize maven-assembly-plugin is the most straightforward approach.

Example configuration:

<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-assembly-plugin</artifactId>
  <version>3.6.0</version>
  <configuration>
    <descriptorRefs>
      <descriptorRef>jar-with-dependencies</descriptorRef>
    </descriptorRefs>
    <finalName>backup</finalName>
    <appendAssemblyId>false</appendAssemblyId>
    <archive>
      <manifest>
        <mainClass>basic_demo.App</mainClass>
      </manifest>
    </archive>
  </configuration>
  <executions>
    <execution>
      <id>make-assembly</id>
      <phase>package</phase>
      <goals>
        <goal>single</goal>
      </goals>
    </execution>
  </executions>
</plugin>

This configuration would package the entire project and its dependencies into a single zip or jar archive — the same goal as the Gradle zipBackup task.

5. Running and Testing the Application

To run and test the project, Maven uses predefined lifecycle phases and plugins:

Compile the code:

mvn compile

Run unit tests:

mvn test

Package the project into a JAR or ZIP:

mvn package

Run the application: (using the exec-maven-plugin)

mvn exec:java -Dexec.mainClass="basic_demo.ChatServerApp"

These commands correspond directly to the Gradle commands:

.\gradlew.bat build
.\gradlew.bat test
.\gradlew.bat runServer
.\gradlew.bat zipBackup

6. Version Control Integration

The same Git workflow could be used as Gradle:

git add .
git commit -m "Add pom.xml with Maven build configuration"
git tag ca2-maven-alternative
git push origin main
git push origin ca2-maven-alternative

This would mark the Maven-based implementation as an alternative version in the repository.

7. Summary

If Maven were used:

The build logic would be specified in pom.xml.
Dependencies and plugins would reflect the Gradle setup.
Plugins would replace Gradle tasks (assembly for bundling, exec for running).
The workflow (compile - test - package) would be the same, but only the syntax and extensibility would differ.

While the same results are attainable, Maven's XML structure makes it harder to maintain and extend compared to Gradle's short, programmatic DSL.
Because of this, Gradle remains the superior choice for this purpose - but Maven demonstrates how precisely the same functional goals can be met more conventionally.