# ==========================================
# Stage 1: Build the JAR file
# ==========================================
FROM maven:3.9.6-eclipse-temurin-21-alpine AS builder
WORKDIR /build

# Copy pom.xml and pre-fetch dependencies (efficient caching)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy src directory and build the application jar
COPY src ./src
RUN mvn package -DskipTests -B

# ==========================================
# Stage 2: Runtime Environment (Lean & Secure)
# ==========================================
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Create a non-root system group and user for security hardening
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Copy the executable jar from builder stage
COPY --from=builder /build/target/back2kasi-backend-0.0.1-SNAPSHOT.jar app.jar

# Standard environment variables with production defaults
ENV PORT=8080
ENV SPRING_PROFILES_ACTIVE=prod

EXPOSE 8080

# Configure JVM tuning flags for container memory awareness
ENTRYPOINT ["java", "-XX:+UseG1GC", "-XX:+ExitOnOutOfMemoryError", "-jar", "app.jar"]
