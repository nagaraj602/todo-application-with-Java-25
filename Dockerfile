# Stage 1: Build the application
FROM amazoncorretto:25-alpine AS builder
# Install maven for the build stage
RUN apk add --no-cache maven
WORKDIR /build

# Copy pom and source code
COPY pom.xml .
COPY src ./src

# Build the application, skipping tests to speed up the pipeline
RUN mvn clean package -DskipTests

# Stage 2: Minimal Runtime
FROM amazoncorretto:25-alpine
ENV APP_HOME=/usr/src/app
WORKDIR $APP_HOME

# Copy the compiled JAR from the builder stage
COPY --from=builder /build/target/*.jar app.jar

EXPOSE 3004

CMD ["java", "-jar", "app.jar"]
