FROM eclipse-temurin:21-jdk AS build
RUN apt-get update && apt-get install -y git
WORKDIR /app
RUN git clone https://github.com/spring-guides/gs-rest-service.git .
WORKDIR /app/complete
RUN ./gradlew clean build
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
