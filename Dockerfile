FROM maven:3.9-eclips-tumurin-17 as builder
WORKDIR /app
COPY ..
RUN mvn clean package

# runtime
FROM  eclips-tumurin:17-jre
WORKDIR /app
COPY --target=builder /app/target/app.jar app.jar
CMD ["java", '-jar', "app.jar"]

