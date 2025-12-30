# AI Features Configuration for ClusterEye API

This document explains how to enable and configure AI-powered analysis features in the ClusterEye API Helm chart.

## Overview

AI features are **disabled by default** to give customers control over costs. When enabled, the following components are activated:

- **AI Cache Service**: In-memory + database caching (70-80% hit rate)
- **AI Request Processor**: Priority-based queue processing
- **AI Threshold Monitor**: Auto-triggers on metric breaches
- **AI API Endpoints**: REST API for AI analysis

## Enabling AI Features

### Method 1: values.yaml (Recommended)

Edit your `values.yaml`:

```yaml
config:
  ai:
    enabled: true  # Enable AI features
    endpoint: "https://your-ai-endpoint.com/api/v1/chat/completions"  # Optional
    token: "your-ai-token"  # Optional
```

Then upgrade the release:

```bash
helm upgrade clustereye ./clustereye-helm -n clustereye
```

### Method 2: Command Line Override

```bash
helm upgrade clustereye ./clustereye-helm \
  -n clustereye \
  --set config.ai.enabled=true
```

### Method 3: Custom Values File

Create `ai-values.yaml`:

```yaml
config:
  ai:
    enabled: true
    endpoint: "https://custom-endpoint.com/api/v1/chat/completions"
    token: "custom-token"
```

Apply it:

```bash
helm upgrade clustereye ./clustereye-helm \
  -n clustereye \
  -f ai-values.yaml
```

## Configuration Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `config.ai.enabled` | Enable/disable AI features | `false` | Yes |
| `config.ai.endpoint` | AI service endpoint URL | DigitalOcean AI | No |
| `config.ai.token` | AI service authentication token | Default token | No |

## What Gets Created

When AI is enabled, the following Kubernetes resources are created:

### 1. ConfigMap: `clustereye-api-ai-config`

Contains environment variables:
- `ENABLE_AI_FEATURES=true`
- `AI_ENDPOINT=<endpoint>`
- `AI_TOKEN=<token>`

### 2. Updated Deployment

The API deployment is updated to include:
```yaml
envFrom:
  - configMapRef:
      name: clustereye-api-ai-config
```

## Verification

After enabling AI features, verify the deployment:

### 1. Check Pod Status

```bash
kubectl get pods -n clustereye -l app.kubernetes.io/name=clustereye-api
```

Wait for the new pod to be `Running`.

### 2. Check Logs

```bash
kubectl logs -n clustereye -l app.kubernetes.io/name=clustereye-api --tail=50 | grep -i "AI"
```

Expected output:
```
AI features enabled - initializing AI service components
AI cache initialized (max_size=100, default_ttl=24h)
AI request processor worker initialized (interval=30s, batch_size=3)
AI threshold monitor worker initialized (interval=5m)
```

### 3. Verify Environment Variables

```bash
kubectl exec -n clustereye deployment/clustereye-api -- env | grep ENABLE_AI_FEATURES
```

Expected output:
```
ENABLE_AI_FEATURES=true
```

### 4. Test AI Endpoint

```bash
# Port forward
kubectl port-forward -n clustereye svc/clustereye-api 8080:8080

# Test (in another terminal)
curl http://localhost:8080/api/v1/ai/cache/stats
```

If AI is enabled, you'll get cache statistics. If disabled, you'll get:
```json
{"error": "AI features are not enabled. Set ENABLE_AI_FEATURES=true to enable."}
```

## Disabling AI Features

To disable AI features:

```bash
helm upgrade clustereye ./clustereye-helm \
  -n clustereye \
  --set config.ai.enabled=false
```

Or edit `values.yaml`:

```yaml
config:
  ai:
    enabled: false
```

The AI ConfigMap will be removed and the deployment will restart without AI environment variables.

## Resource Impact

When AI features are enabled:

- **Memory**: +1-2 MB per pod (AI cache)
- **CPU**: Minimal (<1% increase)
- **Storage**: 6 additional database tables (~100-500 KB per day)
- **Network**: AI API calls (10-15 per day after caching)

## Cost Estimation

**With AI Enabled:**
- User-triggered analyses: 20/day (frontend limit)
- Auto-triggered analyses: ~10-30/day (threshold-based)
- Cache hit rate: 70-80%
- **Effective API calls: 10-15/day**
- **Estimated cost: $5-15/month per customer**

**With AI Disabled:**
- No AI-related costs
- Zero memory/CPU overhead
- Database tables still created (for future use)

## Troubleshooting

### AI Endpoints Return 503

**Symptom:**
```bash
curl http://localhost:8080/api/v1/ai/cache/stats
# Returns: 503 Service Unavailable
```

**Cause:** AI features are disabled

**Solution:**
```bash
helm upgrade clustereye ./clustereye-helm -n clustereye --set config.ai.enabled=true
```

### Pod Not Starting After Enabling AI

**Check logs:**
```bash
kubectl logs -n clustereye -l app.kubernetes.io/name=clustereye-api
```

**Common issues:**
1. Invalid AI endpoint or token
2. Database connection issues
3. InfluxDB connection issues (required for threshold monitoring)

### AI Features Enabled But Not Working

**Verify:**
```bash
# 1. Check ConfigMap exists
kubectl get configmap -n clustereye | grep ai-config

# 2. Check ConfigMap content
kubectl get configmap clustereye-api-ai-config -n clustereye -o yaml

# 3. Check environment variables in pod
kubectl exec -n clustereye deployment/clustereye-api -- env | grep AI
```

## Migration Path

### Scenario 1: Existing Deployment Without AI

1. Current state: AI disabled (default)
2. Database tables: Created automatically via migration
3. Enable AI: `helm upgrade` with `config.ai.enabled=true`
4. Result: AI features active, no data loss

### Scenario 2: Testing AI Features

1. Enable AI: Test with `config.ai.enabled=true`
2. Test period: Evaluate costs and usage
3. Disable if needed: `config.ai.enabled=false`
4. Result: AI features disabled, historical data preserved in database

## Advanced Configuration

For advanced users, additional environment variables can be added to `ai-configmap.yaml`:

```yaml
data:
  ENABLE_AI_FEATURES: "true"
  AI_ENDPOINT: {{ .Values.config.ai.endpoint | quote }}
  AI_TOKEN: {{ .Values.config.ai.token | quote }}

  # Advanced options (uncomment to use)
  # AI_CACHE_MAX_SIZE: "100"           # Max entries in memory cache
  # AI_CACHE_TTL_HOURS: "24"           # Default cache TTL
  # AI_REQUEST_PROCESSOR_INTERVAL: "30s"  # Queue processing interval
  # AI_THRESHOLD_MONITOR_INTERVAL: "5m"   # Threshold check interval
```

## Support

For issues or questions:

1. Check logs: `kubectl logs -n clustereye -l app.kubernetes.io/name=clustereye-api`
2. Verify configuration: Review this document
3. Test with AI disabled to isolate the issue
4. Contact support with logs and Helm values

## Related Documentation

- [Main AI Features Documentation](../../../clustereye-api/AI_FEATURES.md)
- [Helm Chart README](../../README.md)
- [ClusterEye API Documentation](../../../clustereye-api/README.md)
