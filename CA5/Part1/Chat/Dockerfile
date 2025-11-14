FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY . .
RUN chmod +x ./gradlew
RUN ./gradlew clean build

FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY --from=build /app/build/libs/basic_demo-0.1.0.jar app/app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
