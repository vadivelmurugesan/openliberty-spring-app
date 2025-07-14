# Project Documentation

## Build and Test the Application

To build and test this application, follow these steps:

1. Ensure you have **Java 17** installed. Verify using:
   ```bash
   java -version
   ```

2. Use the included `build.sh` script to build and test the application:
   ```bash
   ./build.sh
   ```

   This script will:
   - Build the project using Maven.
   - Run unit and integration tests.
   - Create a runnable artifact (e.g., JAR or WAR file).

3. To run the application locally after building:
   ```bash
   java -jar target/<your-app-name>.jar
   ```

---

## Accessing the Application
By default, the application will be accessible at:

- **HTTP**: [http://localhost:9080](http://localhost:9080)
- **HTTPS**: [https://localhost:9443](https://localhost:9443) (self-signed certificate)

If running in a container, expose ports `9080` and `9443` correctly.

---

## Running the Application in Docker
This project includes a `Dockerfile` to containerize the application.

### Build the Docker Image:

```bash
docker build -t <your-image-name>: .
```

### Run the Docker Container:

```bash
docker run -p 9080:9080 -p 9443:9443 <your-image-name>:
```
After starting the container, the application will be accessible at the same endpoints as mentioned above.

---

## Kubernetes Deployment
To deploy the application to Kubernetes:

1. Create a `Deployment` and `Service` YAML file, exposing the HTTP port (9080).
2. Use the `/actuator/health` endpoint for readiness and liveness probes.

Example Health Check Configuration:

```yaml 

readinessProbe: httpGet: path: /actuator/health port: 9080 initialDelaySeconds: 10 periodSeconds: 30
livenessProbe: httpGet: path: /actuator/health port: 9080 initialDelaySeconds: 20 periodSeconds: 30

```
## Resources for Development

- **Dev Mode**: Open Liberty provides development mode for faster iterations. Learn more [here](https://openliberty.io/docs/latest/development-mode.html).
- **Maven Commands**:
  - Build: `mvn clean package`
  - Dev Mode: `mvn liberty:dev`
- **IDE Integration**:
  For IntelliJ IDEA, import the project as a Maven/Gradle project for better build and dependency management.

---

## Troubleshooting

Here are common issues and resolutions:

1. **Java Version Mismatch**  
   Ensure the installed JDK matches the required version (Java 17). Verify with:
   ```bash
   java -version
   ```
   Download the correct version [here](https://adoptium.net/).

2. **Dependency Issues**  
   If the build fails, confirm:
   - All required dependencies are present in `pom.xml` or `build.gradle`.
   - Network connectivity is stable to fetch dependencies.

3. **Port Conflicts**  
   Ensure ports `9080` and `9443` are not in use by other applications. Identify conflicts using:
   ```bash
   lsof -i :9080
   ```

4. **Docker Image Issues**  
   When errors occur during Docker builds:
   - Ensure proper permissions for Docker.
   - Clean previous staged artifacts:
     ```bash
     docker system prune -f
     ```

---

## Building a Thin JAR with Open Liberty
This project uses Open Liberty to generate a thin JAR. For detailed steps, check the provided `Dockerfile`.

For example:

- **Stage 1**: Converts a fat Spring Boot JAR into a thin JAR.
- **Stage 2**: Deploys the thin JAR in a lightweight image.

---

### Additional Notes

- **Integration Testing**: Use `8080` and `9443` for external integrations during testing.
- **Logging**: All logs are written to `logs/` or streamlined to Docker logging in containerized environments.

If additional tools or steps are required, feel free to extend this documentation!