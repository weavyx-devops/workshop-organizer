# Build stage: JDK and Gradle wrapper
FROM eclipse-temurin:21-jdk-noble AS build
WORKDIR /workspace

# Build files first: this layer stays cached while only the code changes
COPY gradlew settings.gradle build.gradle ./
COPY gradle/ gradle/
RUN ./gradlew --no-daemon -q dependencies > /dev/null

# Sources, then the executable war (tests run in CI, not here)
COPY . .
RUN ./gradlew --no-daemon bootWar

# Runtime stage: JRE only, non-root user
FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S spring && adduser -S -G spring spring
WORKDIR /app
COPY --from=build /workspace/build/libs/*.war app.war
USER spring:spring
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.war"]
