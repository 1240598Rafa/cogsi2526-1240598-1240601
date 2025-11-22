FROM eclipse-temurin:21-jdk

WORKDIR /app

RUN apt-get update -y && \
    apt-get install -y git gradle wget unzip && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/1240598Rafa/cogsi2526-1240598-1240601.git /app/repo

WORKDIR /app/repo/CA2/Part2

RUN chmod +x gradlew

RUN ./gradlew clean build -x test

EXPOSE 8080

CMD ["sh", "-c", "java -jar build/libs/*0.0.jar"]
