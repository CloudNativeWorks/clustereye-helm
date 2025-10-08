# ClusterEye Stack Helm Chart

ClusterEye Stack is a comprehensive Kubernetes monitoring solution that provides database monitoring, metrics collection, and visualization capabilities.

## Overview

This Helm chart deploys the complete ClusterEye monitoring stack including:

- **ClusterEye Frontend**: React-based monitoring dashboard
- **ClusterEye API**: Go-based backend service for data collection and API endpoints
- **PostgreSQL**: Database for storing application data and configurations (optional)
- **InfluxDB**: Time-series database for metrics storage (optional)

## Prerequisites

- Kubernetes 1.19+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure (if persistence is enabled)

## Installation

### Quick Start

```bash
# Add the repository (if using a Helm repository)
helm repo add clustereye https://your-helm-repo.com

# Install with default values
helm install my-clustereye clustereye/clustereye-stack
```

### Local Installation

```bash
# Clone and install from local files
git clone https://github.com/your-org/clustereye-helm
cd clustereye-helm
helm install my-clustereye ./clustereye-stack
```

### Custom Installation

```bash
# Install with custom values
helm install my-clustereye ./clustereye-stack \
  --set frontend.enabled=true \
  --set api.enabled=true \
  --set postgresql.enabled=false \
  --set externalPostgreSQL.enabled=true \
  --set externalPostgreSQL.host=your-postgres-host
```

## Configuration

### Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Target namespace | `clustereye` |
| `global.storageClass` | Storage class for persistent volumes | `""` |
| `global.imagePullSecrets` | Global image pull secrets | `[]` |

### Global Secrets Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.secrets.jwtSecretKey` | JWT secret key for authentication | `your-jwt-secret-key-here` |
| `global.secrets.apiSecretKey` | API secret key | `your-api-secret-key-here` |
| `global.secrets.encryptionKey` | Encryption key for sensitive data | `your-encryption-key-here` |

### Global Database Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.database.host` | Database host | `clustereye-stack-postgresql` |
| `global.database.port` | Database port | `5432` |
| `global.database.username` | Database username | `postgres` |
| `global.database.password` | Database password | `postgres` |
| `global.database.database` | Database name | `clustereye` |
| `global.database.sslMode` | SSL mode | `disable` |

### Global InfluxDB Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.influxdb.url` | InfluxDB URL | `http://clustereye-stack-influxdb:8086` |
| `global.influxdb.token` | InfluxDB access token | `clustereye-token` |
| `global.influxdb.organization` | InfluxDB organization | `clustereye` |
| `global.influxdb.bucket` | InfluxDB bucket | `clustereye` |

### Frontend Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.enabled` | Enable frontend deployment | `true` |
| `clustereye-frontend.replicaCount` | Number of frontend replicas | `2` |
| `clustereye-frontend.image.repository` | Frontend image repository | `johnblack77/clustereye` |
| `clustereye-frontend.image.tag` | Frontend image tag | `latest` |
| `clustereye-frontend.service.type` | Frontend service type | `ClusterIP` |
| `clustereye-frontend.service.port` | Frontend service port | `80` |
| `clustereye-frontend.ingress.enabled` | Enable ingress | `false` |
| `clustereye-frontend.resources.limits.cpu` | CPU limit | `500m` |
| `clustereye-frontend.resources.limits.memory` | Memory limit | `512Mi` |

### API Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `api.enabled` | Enable API deployment | `true` |
| `clustereye-api.replicaCount` | Number of API replicas | `2` |
| `clustereye-api.image.repository` | API image repository | `johnblack77/clustereye-api` |
| `clustereye-api.image.tag` | API image tag | `latest` |
| `clustereye-api.service.port` | HTTP service port | `8080` |
| `clustereye-api.service.grpcPort` | gRPC service port | `50051` |
| `clustereye-api.resources.limits.cpu` | CPU limit | `1000m` |
| `clustereye-api.resources.limits.memory` | Memory limit | `1Gi` |

### PostgreSQL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Enable internal PostgreSQL | `true` |
| `postgresql.auth.postgresPassword` | PostgreSQL admin password | `postgres` |
| `postgresql.auth.username` | PostgreSQL username | `postgres` |
| `postgresql.auth.password` | PostgreSQL user password | `postgres` |
| `postgresql.auth.database` | PostgreSQL database name | `clustereye` |
| `postgresql.primary.persistence.enabled` | Enable persistence | `true` |
| `postgresql.primary.persistence.size` | Storage size | `8Gi` |

### External PostgreSQL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `externalPostgreSQL.enabled` | Use external PostgreSQL | `false` |
| `externalPostgreSQL.host` | External PostgreSQL host | `""` |
| `externalPostgreSQL.port` | External PostgreSQL port | `5432` |
| `externalPostgreSQL.username` | External PostgreSQL username | `postgres` |
| `externalPostgreSQL.password` | External PostgreSQL password | `""` |
| `externalPostgreSQL.database` | External PostgreSQL database | `clustereye` |

### InfluxDB Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `influxdb.enabled` | Enable internal InfluxDB | `true` |
| `influxdb.auth.admin.username` | InfluxDB admin username | `admin` |
| `influxdb.auth.admin.password` | InfluxDB admin password | `clustereye-admin-password` |
| `influxdb.auth.admin.token` | InfluxDB access token | `clustereye-token` |
| `influxdb.auth.admin.org` | InfluxDB organization | `clustereye` |
| `influxdb.auth.admin.bucket` | InfluxDB bucket | `clustereye` |
| `influxdb.persistence.enabled` | Enable persistence | `true` |
| `influxdb.persistence.size` | Storage size | `8Gi` |

### External InfluxDB Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `externalInfluxDB.enabled` | Use external InfluxDB | `false` |
| `externalInfluxDB.url` | External InfluxDB URL | `""` |
| `externalInfluxDB.token` | External InfluxDB token | `""` |
| `externalInfluxDB.organization` | External InfluxDB organization | `""` |
| `externalInfluxDB.bucket` | External InfluxDB bucket | `""` |

## Usage Examples

### Example 1: Full Stack Deployment

```bash
helm install clustereye ./clustereye-stack \
  --set frontend.enabled=true \
  --set api.enabled=true \
  --set postgresql.enabled=true \
  --set influxdb.enabled=true
```

### Example 2: Using External Databases

```bash
helm install clustereye ./clustereye-stack \
  --set postgresql.enabled=false \
  --set influxdb.enabled=false \
  --set externalPostgreSQL.enabled=true \
  --set externalPostgreSQL.host=my-postgres.example.com \
  --set externalPostgreSQL.password=my-password \
  --set externalInfluxDB.enabled=true \
  --set externalInfluxDB.url=https://my-influx.example.com:8086 \
  --set externalInfluxDB.token=my-influx-token \
  --set externalInfluxDB.organization=my-org \
  --set externalInfluxDB.bucket=my-bucket
```

### Example 3: Frontend Only with External Services

```bash
helm install clustereye ./clustereye-stack \
  --set api.enabled=false \
  --set postgresql.enabled=false \
  --set influxdb.enabled=false \
  --set clustereye-frontend.ingress.enabled=true \
  --set clustereye-frontend.ingress.hosts[0].host=clustereye.mydomain.com
```

### Example 4: Production Installation with Custom Secrets

```bash
# Generate secure secrets
JWT_SECRET=$(openssl rand -base64 32)
API_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -base64 32)

helm install clustereye ./clustereye-stack \
  --set global.secrets.jwtSecretKey="$JWT_SECRET" \
  --set global.secrets.apiSecretKey="$API_SECRET" \
  --set global.secrets.encryptionKey="$ENCRYPTION_KEY" \
  --set global.database.password="$(openssl rand -base64 16)" \
  --set global.influxdb.token="$(openssl rand -base64 32)"
```

### Example 5: Using Values File for Production

Create a `production-values.yaml` file:

```yaml
global:
  secrets:
    jwtSecretKey: "your-secure-jwt-secret"
    apiSecretKey: "your-secure-api-secret"
    encryptionKey: "your-secure-encryption-key"
  database:
    password: "your-secure-db-password"
  influxdb:
    token: "your-secure-influx-token"

clustereye-frontend:
  ingress:
    enabled: true
    hosts:
      - host: clustereye.yourdomain.com
        paths:
          - path: /
            pathType: Prefix

postgresql:
  auth:
    postgresPassword: "your-secure-db-password"
```

Then install:

```bash
helm install clustereye ./clustereye-stack -f production-values.yaml
```

## Accessing the Application

After installation, you can access ClusterEye using the methods described in the NOTES output. The most common methods are:

1. **Port Forward** (for ClusterIP services):
   ```bash
   kubectl port-forward service/[RELEASE-NAME]-clustereye-frontend 8080:80
   ```

2. **Ingress** (if enabled):
   Configure your ingress controller and DNS to point to the specified hosts.

3. **LoadBalancer** (if using cloud provider):
   Wait for the external IP and access via browser.

## Upgrading

```bash
# Upgrade to a new version
helm upgrade my-clustereye ./clustereye-stack

# Upgrade with new values
helm upgrade my-clustereye ./clustereye-stack --values my-values.yaml
```

## Uninstalling

```bash
# Uninstall the release
helm uninstall my-clustereye

# Delete PVCs if needed (data will be lost)
kubectl delete pvc -l app.kubernetes.io/instance=my-clustereye
```

## Troubleshooting

### Common Issues

1. **Pods in Pending State**: Check if PVC can be bound and if resource requests can be satisfied.
2. **Database Connection Issues**: Verify database credentials and network connectivity.
3. **Frontend Cannot Reach API**: Check service names and ports in the configuration.

### Useful Commands

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/instance=my-clustereye

# Check logs
kubectl logs -l app.kubernetes.io/name=clustereye-api
kubectl logs -l app.kubernetes.io/name=clustereye-frontend

# Check services
kubectl get svc -l app.kubernetes.io/instance=my-clustereye

# Check configuration
kubectl get configmap -l app.kubernetes.io/instance=my-clustereye
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the changes
5. Submit a pull request

## Support

- GitHub Issues: [https://github.com/your-org/clustereye-helm/issues](https://github.com/your-org/clustereye-helm/issues)
- Documentation: [https://docs.clustereye.io](https://docs.clustereye.io)

## License

This project is licensed under the MIT License - see the LICENSE file for details.