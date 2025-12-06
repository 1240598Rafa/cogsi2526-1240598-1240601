FROM eclipse-temurin:21-jdk as builder

WORKDIR /app

RUN apt-get update && apt-get install -y git

RUN git clone https://github.com/1240598Rafa/cogsi2526-1240598-1240601.git repo

WORKDIR /app/repo/CA2/Part2

RUN chmod +x gradlew
RUN ./gradlew clean build -x test

# Runtime image
FROM eclipse-temurin:21-jre

WORKDIR /app

# Copy only the final JAR
COPY --from=builder /app/repo/CA2/Part2/build/libs/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
