#!/bin/bash

# ==============================================================================
# build.sh — Production-grade Docker build and test script
# ------------------------------------------------------------------------------
# This script builds a Spring Boot thin JAR Docker image using Open Liberty,
# tags it dynamically from Maven project metadata, and runs a local test.
#
# Prerequisites:
#   - Java 17+ and Maven installed
#   - Docker installed and running
#   - Optional: jq for JSON formatting (used in health check)
#
# Usage:
#   chmod +x build.sh
#   ./build.sh
# ==============================================================================

set -e  # Exit on first error
set -o pipefail  # Catch errors in pipelines

# ------------------------------------------------------------------------------
# STEP 1: Extract app metadata from Maven pom.xml
# ------------------------------------------------------------------------------
echo "Extracting app metadata from pom.xml..."

APP_NAME=$(./mvnw help:evaluate -Dexpression=project.artifactId -q -DforceStdout)
APP_VERSION=$(./mvnw help:evaluate -Dexpression=project.version -q -DforceStdout)
IMAGE_TAG="${APP_NAME}:${APP_VERSION}"

echo "App Name:      ${APP_NAME}"
echo "App Version:   ${APP_VERSION}"
echo "Docker Tag:    ${IMAGE_TAG}"

# ------------------------------------------------------------------------------
# STEP 2: Build the Spring Boot JAR using Maven
# ------------------------------------------------------------------------------
echo "Building application with Maven..."
./mvnw clean package -DskipTests

# ------------------------------------------------------------------------------
# STEP 3: Build the Docker image with dynamic app name and version
# ------------------------------------------------------------------------------
echo "Building Docker image..."
docker build \
  --build-arg APP_NAME=$APP_NAME \
  --build-arg APP_VERSION=$APP_VERSION \
  -t $IMAGE_TAG .

# ------------------------------------------------------------------------------
# STEP 4: Run the container locally for testing
# ------------------------------------------------------------------------------
echo "Starting Docker container..."
docker run -d --name $APP_NAME -p 9080:9080 $IMAGE_TAG

# Wait a few seconds for Liberty to start
echo "Waiting for app to initialize..."
sleep 8

# ------------------------------------------------------------------------------
# STEP 5: Check health endpoint
# ------------------------------------------------------------------------------
echo "Checking /actuator/health..."

if command -v jq > /dev/null; then
  curl -s http://localhost:9080/actuator/health | jq
else
  curl -s http://localhost:9080/actuator/health
fi

# ------------------------------------------------------------------------------
# STEP 6: Cleanup container after test
# ------------------------------------------------------------------------------
echo "Cleaning up test container..."
docker stop $APP_NAME >/dev/null && docker rm $APP_NAME >/dev/null

echo "Build and test completed successfully!"