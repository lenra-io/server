# Environment Variables

This document provides a list of the environment variables that need to be set for the application to function correctly. Default values are provided where applicable.

## General Configuration

- `PORT`: The port on which the application will run.
- `SECRET_KEY_BASE`: The secret key base for the application.
- `API_ENDPOINT`: The endpoint for the application's API.
- `APP_HOST`: The host of the application.
- `ENVIRONMENT`: The environment in which the application is running (e.g., production, development, etc.).

## Database Configuration

- `POSTGRES_USER`: The username for the PostgreSQL database.
- `POSTGRES_PASSWORD`: The password for the PostgreSQL database.
- `POSTGRES_DB`: The name of the PostgreSQL database.
- `POSTGRES_HOST`: The hostname of the PostgreSQL server.

## FaaS Configuration

- `FAAS_URL`: The URL for the FaaS service.
- `FAAS_AUTH`: The authentication for the FaaS service.
- `FAAS_REGISTRY`: The registry for the FaaS service.

## Pipeline Configuration

- `PIPELINE_RUNNER`: The pipeline runner to use. Default is "gitlab". Depending on the value of this variable, you should configure either the GitLab or Kubernetes section below.

### GitLab Configuration

- `GITLAB_API_URL`: The URL for the GitLab API.
- `GITLAB_API_TOKEN`: The token for the GitLab API.
- `GITLAB_PROJECT_ID`: The ID of the GitLab project.

### Kubernetes Configuration

- `KUBERNETES_API_URL`: The URL for the Kubernetes API. Default is "https://KUBERNETES_SERVICE_HOST".
- `KUBERNETES_SERVICE_HOST`: The service host for Kubernetes.
- `KUBERNETES_API_CERT`: The certificate for the Kubernetes API. Default is "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt".
- `KUBERNETES_API_TOKEN`: The token for the Kubernetes API. If not set, the value is read from the path specified in `KUBERNETES_API_TOKEN_PATH`.
- `KUBERNETES_API_TOKEN_PATH`: The path to the Kubernetes API token. Default is "/var/run/secrets/kubernetes.io/serviceaccount/token".
- `KUBERNETES_BUILD_NAMESPACE`: The namespace for Kubernetes builds. Default is "lenra-build".
- `KUBERNETES_BUILD_SCRIPTS`: The scripts for Kubernetes builds. Default is "lenra-build-scripts".
- `KUBERNETES_BUILD_SECRET`: The secret for Kubernetes builds. Default is "lenra-build-secret".

## Template Configuration

- `TEMPLATE_URL`: The URL for the template.

## Email Configuration

- `LENRA_EMAIL`: The email for Lenra.
- `LENRA_APP_URL`: The URL for the Lenra app.

## Application Runner Configuration

- `LISTENERS_TIMEOUT`: The timeout for listeners in the application runner. Must be converted to an integer.
- `VIEW_TIMEOUT`: The timeout for views in the application runner. Must be converted to an integer.
- `MANIFEST_TIMEOUT`: The timeout for manifests in the application runner. Must be converted to an integer.

## MongoDB Configuration

- `MONGO_HOSTNAME`: The hostname for the MongoDB server.
- `MONGO_PORT`: The port for the MongoDB server. Default is "27017".
- `MONGO_USERNAME`: The username for the MongoDB server.
- `MONGO_PASSWORD`: The password for the MongoDB server.
- `MONGO_SSL`: Whether SSL is enabled for the MongoDB server. Default is "false".
- `MONGO_AUTH_SOURCE`: The auth source for the MongoDB server.

## Logging Configuration

- `LOG_LEVEL`: The level of logging (e.g., info, debug, etc.). Default is "info".

## Cluster Configuration

- `SERVICE_NAME`: The name of the service for clustering.

## Mailer Configuration

- `SENDGRID_API_KEY`: The API key for SendGrid.

## Guardian Configuration

- `GUARDIAN_SECRET_KEY`: The secret key for Guardian.

## Sentry Configuration

- `SENTRY_DSN`: The DSN for Sentry.
