# CA2 - Part 1: Gradle Basic Demo

## Setup

This part of the assignment dealt with learning Gradle build automation.
The following easy Java project was used as the reference application: gradle_basic_demo
.
Following steps were executed to set up the project and introduce new Gradle tasks:.


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

These commands fetch the demo project officially, copy the contents of this demo to our CA2/Part1 directory, 
and remove any previous Git history (.git) so that this project is ours. 

### Tag initial Version
Then it was asked
"
Use tags to mark the versions of the application
▪ You should use a pattern major.minor.revision (e.g., 1.1.0)
▪ Tag the initial version as ca2-1.1.0 and push the tag to the server
"

git tag ca2-1.1.0
git push origin ca2-1.1.0

### Build and run the base project

.\gradlew.bat build
.\gradlew.bat run

The Gradle Wrapper (gradlew.bat) will download the appropriate Gradle version automatically.
The project builds successfully and shows a message in the terminal window (e.g., "Chat server started" or something similar).

## Gradle Task Extensions

It was asked to:
"
Add a new runServer Gradle task to execute the server
"

So we modified the build.gradle file in order to include Gradle tasks and test configurations

tasks.register('runServer', JavaExec) {
    group = "DevOps"
    description = "Launches the chat server application"
    classpath = sourceSets.main.runtimeClasspath
    mainClass = 'basic_demo.ChatServerApp'
}

.\gradlew.bat runServer

Purpose:
Runs the Java class basic_demo.ChatServerApp directly with Gradle, rather than by hand with java -jar.
Expected output:
Gradle starts the server and prints console messages like Server started on port 59001.

### Add and run a unit test

It was then asked to
"
Add a simple unit test and update the Gradle build script so
that it can execute the test
"
Since the demo project didn’t include any tests, a new one was created on src\test\java\basic_demo\AppTest.java:
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

With this additions we can verify that Gradle correctly compiles and runs JUnit 5 tests

.\gradlew.bat test

Expected Output:
> Task :test
BUILD SUCCESSFUL in 2s
1 test passed

This verifies that the Gradle environment is functional

### Create a backup task

It was then asked to:
"
Add a new task of type Copy to be used to make a backup of
the sources of the application
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

"
Add a new task of type Zip to be used to make an archive (i.e.,
a zip file) of the backup of the application
▪ This tasks should depend on the execution of the backup task
"


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
This code was added to build.gradle in order to automatically compress the backup into a .zip

.\gradlew.bat zipBackup

With this command a file 'backup.zip' is generated under build/archives/backup.zip

## Gradle Wrapper and JDK Toolchain

"
Explain how the Gradle Wrapper and the JDK Toolchain ensure
the correct versions of Gradle and the Java Development Kit
are used without requiring manual installation
▪ In the root directory of the application, run “./gradlew –q
javaToolchain” and explain the output
"

.\gradlew.bat -q javaToolchain

The Gradle Wrapper (gradlew.bat / gradlew) automatically ensures all developers use the same version of Gradle — it downloads Gradle locally if it is not there.
The JDK Toolchain automatically ensures the correct Java version (as defined in the build.gradle, for instance, JavaLanguageVersion.of(17)) is utilized even when multiple JDKs are installed on the machine.

This way we can confirm Gradle selected the correct Java toolchain without manual setup

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

