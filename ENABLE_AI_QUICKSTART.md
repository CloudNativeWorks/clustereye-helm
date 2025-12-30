# ClusterEye AI Features - Quick Start Guide

## Enable AI in 3 Steps

### Step 1: Edit Values

```bash
cd /path/to/clustereye-helm
```

Edit `values.yaml` or create `ai-override.yaml`:

```yaml
clustereye-api:
  config:
    ai:
      enabled: true
```

### Step 2: Upgrade Release

```bash
helm upgrade clustereye . -n clustereye -f ai-override.yaml
```

Or use command line:

```bash
helm upgrade clustereye . -n clustereye \
  --set clustereye-api.config.ai.enabled=true
```

### Step 3: Verify

```bash
# Wait for new pod
kubectl rollout status deployment/clustereye-clustereye-api -n clustereye

# Check logs
kubectl logs -n clustereye -l app.kubernetes.io/name=clustereye-api --tail=20 | grep "AI"

# Expected output:
# "AI features enabled - initializing AI service components"
# "AI cache initialized (max_size=100, default_ttl=24h)"
# "AI request processor worker initialized (interval=30s, batch_size=3)"
# "AI threshold monitor worker initialized (interval=5m)"
```

## Verify AI is Working

```bash
# Port forward
kubectl port-forward -n clustereye svc/clustereye-clustereye-api 8080:8080 &

# Test AI endpoint
curl http://localhost:8080/api/v1/ai/cache/stats

# Kill port forward
kill %1
```

If working, you'll see:
```json
{
  "memory_cache_size": 0,
  "memory_cache_max_size": 100,
  "memory_usage_mb": 0,
  "hit_rate": 0,
  "hit_count": 0,
  "miss_count": 0,
  "db_cache_size": 0
}
```

If AI is disabled, you'll see:
```
AI features are not enabled. Set ENABLE_AI_FEATURES=true to enable.
```

## Disable AI

```bash
helm upgrade clustereye . -n clustereye \
  --set clustereye-api.config.ai.enabled=false
```

## Troubleshooting

**Pod not starting?**
```bash
kubectl describe pod -n clustereye -l app.kubernetes.io/name=clustereye-api
kubectl logs -n clustereye -l app.kubernetes.io/name=clustereye-api
```

**AI ConfigMap not found?**
```bash
kubectl get configmap -n clustereye | grep ai-config

# If missing, check values:
helm get values clustereye -n clustereye
```

**Still not working?**
See detailed documentation: [AI Configuration Guide](charts/clustereye-api/AI_CONFIGURATION.md)

## Cost & Resource Impact

- **Memory**: +1-2 MB per pod
- **CPU**: Minimal (<1%)
- **Cost**: ~$5-15/month (with 70-80% cache hit rate)
- **API calls**: 10-15/day (after caching)

## What You Get

✅ **Smart Caching**: 70-80% of AI requests served from cache
✅ **Auto-Triggers**: Automatic analysis on threshold breaches
✅ **Priority Queue**: Batch processing with retry logic
✅ **API Endpoints**: 5 new REST endpoints for AI features
✅ **Cost Savings**: 60-70% reduction in AI costs

## Next Steps

- Review [Full AI Documentation](charts/clustereye-api/AI_CONFIGURATION.md)
- Check [AI Features Guide](../clustereye-api/AI_FEATURES.md)
- Configure [Advanced Options](charts/clustereye-api/AI_CONFIGURATION.md#advanced-configuration)
