FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY basic_demo-0.1.0.jar app.jar
EXPOSE 59001
CMD ["java", "-cp", "app.jar", "basic_demo.ChatServerApp", "59001"]