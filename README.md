### Accessing the Application
By default, the application will be available at:

- HTTP: [http://localhost:9080](http://localhost:9080)
- HTTPS: [https://localhost:9443](https://localhost.9443) (self-signed certificate)

---

## Resources for Development

- **Dev Mode Documentation**: Learn more about Open Liberty's development mode and its capabilities. [Read Here](https://openliberty.io/docs/latest/development-mode.html)

---

## Troubleshooting

Here are some common issues and solutions:

1. **Java Version Mismatch**:  
   Ensure your installed JDK matches the version selected during project generation. Check with:
   ```bash
   java -version
   ```

2. **Dependency Issues**:  
   If the project fails to build, check for missing dependencies and ensure you have a stable internet connection to fetch Maven artifacts.

3. **Server Fails to Start**:  
   Verify the availability of required ports (default: `9080` for HTTP and `9443` for HTTPS) and ensure they are not blocked by firewalls or used by other applications.
