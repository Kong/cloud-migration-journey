FROM openjdk:18-jdk-alpine
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar

HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost:8080/actuator/health/ || exit 1

ENTRYPOINT ["java","-jar","/app.jar"]