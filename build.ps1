# ==============================================================================
# build.ps1 — Production-grade Docker build and test script
# ------------------------------------------------------------------------------
# Builds a Spring Boot thin JAR Docker image using Open Liberty.
#
# Prerequisites:
#   - Java 17+ and Maven installed
#   - Docker installed and running
#   - PowerShell version 5.1 or later
#
# Usage:
#   .\build.ps1
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "Starting the build and test process..." -ForegroundColor Green

# ------------------------------------------------------------------------------
# STEP 1: Validate prerequisites (Java, Maven, Docker)
# ------------------------------------------------------------------------------
Write-Host "Validating prerequisites..." -ForegroundColor Yellow

if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Error "Java is not installed or not found in the PATH. Please install Java 17."
    exit 1
} else {
    try {
        $javaVersion = & java -version 2>&1 | Out-String
        Write-Host "Java is installed. Version details:" -ForegroundColor Green
        Write-Host $javaVersion -ForegroundColor Cyan
    } catch {
        Write-Error "Failed to fetch Java version. Ensure it's installed correctly."
        exit 1
    }
}

if (-not ((Test-Path "./mvnw.cmd") -or (Test-Path "./mvnw") -or (Get-Command mvn -ErrorAction SilentlyContinue))) {
    Write-Error "Maven or Maven wrapper is not available. Please install Maven or include the wrapper."
    exit 1
}

try {
    docker version | Out-Null
    Write-Host "Docker is installed and running." -ForegroundColor Green
} catch {
    Write-Error "Docker is not running or accessible. Please start the Docker daemon."
    exit 1
}

# ------------------------------------------------------------------------------
# STEP 2: Extract application metadata from Maven pom.xml
# ------------------------------------------------------------------------------
Write-Host "Extracting application metadata from pom.xml..." -ForegroundColor Yellow

try {
    if (Test-Path "./mvnw.cmd") {
        $APP_NAME = & ./mvnw.cmd help:evaluate -Dexpression=project.artifactId -q -DforceStdout
        $APP_VERSION = & ./mvnw.cmd help:evaluate -Dexpression=project.version -q -DforceStdout
    } elseif (Test-Path "./mvnw") {
        $APP_NAME = & ./mvnw help:evaluate -Dexpression=project.artifactId -q -DforceStdout
        $APP_VERSION = & ./mvnw help:evaluate -Dexpression=project.version -q -DforceStdout
    } else {
        $APP_NAME = & mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout
        $APP_VERSION = & mvn help:evaluate -Dexpression=project.version -q -DforceStdout
    }
    $IMAGE_TAG = "$($APP_NAME):$($APP_VERSION)"
} catch {
    Write-Error "Failed to extract app metadata from pom.xml. Please ensure Maven is configured correctly."
    exit 1
}

Write-Host "App Name:      $APP_NAME" -ForegroundColor Green
Write-Host "App Version:   $APP_VERSION" -ForegroundColor Green
Write-Host "Docker Tag:    $IMAGE_TAG" -ForegroundColor Green

# ------------------------------------------------------------------------------
# STEP 3: Build the Spring Boot JAR using Maven
# ------------------------------------------------------------------------------
Write-Host "Building the application with Maven..." -ForegroundColor Yellow
Write-Host "TIP: This step skips unit tests for faster build. You can remove -DskipTests to include them." -ForegroundColor DarkYellow

if (Test-Path "./mvnw.cmd") {
    & ./mvnw.cmd clean package -DskipTests
} elseif (Test-Path "./mvnw") {
    & ./mvnw clean package -DskipTests
} else {
    & mvn clean package -DskipTests
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Maven build failed. Aborting script."
    exit 1
} else {
    Write-Host "Maven build completed successfully." -ForegroundColor Green
}

$artifactPath = Get-Item -Path ./target/*.jar -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $artifactPath) {
    Write-Error "Build artifact (JAR) was not created. Check the Maven build logs."
    exit 1
}

Write-Host "Build artifact created: $($artifactPath.Name)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# STEP 4: Build the Docker image
# ------------------------------------------------------------------------------
Write-Host "Building the Docker image..." -ForegroundColor Yellow

if (-not (Test-Path "./Dockerfile")) {
    Write-Error "Dockerfile is missing in the current directory."
    exit 1
}

docker build `
  --build-arg APP_NAME=$APP_NAME `
  --build-arg APP_VERSION=$APP_VERSION `
  -t "$IMAGE_TAG" .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker image build failed. Aborting script."
    exit 1
} else {
    Write-Host "Docker image built and tagged as $IMAGE_TAG" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# STEP 5: Test the Docker container
# ------------------------------------------------------------------------------
Write-Host "Starting the Docker container for testing..." -ForegroundColor Yellow
Write-Host "TIP: Make sure your Spring Boot app has a health check at /actuator/health" -ForegroundColor DarkYellow
Write-Host "TIP: If port 9080 is in use, change it in the docker run command." -ForegroundColor DarkYellow

if (docker ps -a --format '{{.Names}}' | Select-String -Pattern "^$APP_NAME$") {
    docker rm -f $APP_NAME | Out-Null
}

docker run -d --name $APP_NAME -p 9080:9080 "$IMAGE_TAG"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to start the Docker container."
    exit 1
}

Write-Host "Waiting for the application to initialize..." -ForegroundColor Yellow

$maxRetries = 10
$retryCount = 0
$isHealthy = $false

while (-not $isHealthy -and $retryCount -lt $maxRetries) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:9080/actuator/health" -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $isHealthy = $true
        }
    } catch {
        # Ignore the exception
    }
    Start-Sleep -Seconds 2
    $retryCount++
}

if (-not $isHealthy) {
    Write-Error "Health check failed after multiple attempts. Stopping script."
    docker stop $APP_NAME | Out-Null
    docker rm $APP_NAME | Out-Null
    exit 1
}

Write-Host "The container is healthy and running." -ForegroundColor Green

# ------------------------------------------------------------------------------
# STEP 6: Cleanup resources
# ------------------------------------------------------------------------------
Write-Host "Cleaning up the test container and resources..." -ForegroundColor Yellow

docker stop $APP_NAME | Out-Null
docker rm $APP_NAME | Out-Null

Write-Host "Build and test process completed successfully!" -ForegroundColor Green