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
