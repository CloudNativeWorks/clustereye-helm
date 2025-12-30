# ClusterEye AI Toggle Scripts

Quick scripts to enable/disable AI features without Helm upgrade.

## Quick Start

```bash
# Check current status
./scripts/toggle-ai.sh

# Enable AI
./scripts/enable-ai.sh

# Disable AI
./scripts/disable-ai.sh

# Toggle (enable if disabled, disable if enabled)
./scripts/toggle-ai.sh clustereye toggle
```

## Scripts

### 1. enable-ai.sh

Enables AI features on-the-fly without Helm upgrade.

**Usage:**
```bash
./scripts/enable-ai.sh [namespace]

# Examples:
./scripts/enable-ai.sh                 # Uses 'clustereye' namespace
./scripts/enable-ai.sh production      # Uses 'production' namespace
```

**What it does:**
1. Creates `clustereye-clustereye-api-ai-config` ConfigMap
2. Patches deployment to add `envFrom` reference
3. Waits for pod restart
4. Verifies AI is enabled

**Duration:** ~30-60 seconds (includes pod restart)

### 2. disable-ai.sh

Disables AI features on-the-fly.

**Usage:**
```bash
./scripts/disable-ai.sh [namespace]

# Examples:
./scripts/disable-ai.sh                # Uses 'clustereye' namespace
./scripts/disable-ai.sh production     # Uses 'production' namespace
```

**What it does:**
1. Removes `envFrom` from deployment
2. Optionally deletes ConfigMap (prompts user)
3. Waits for pod restart
4. Verifies AI is disabled

**Duration:** ~30-60 seconds (includes pod restart)

### 3. toggle-ai.sh

Universal script - check status, enable, disable, or toggle.

**Usage:**
```bash
./scripts/toggle-ai.sh [namespace] [action]

# Actions: status (default), enable, disable, toggle

# Examples:
./scripts/toggle-ai.sh                      # Check status
./scripts/toggle-ai.sh clustereye status    # Check status
./scripts/toggle-ai.sh clustereye enable    # Enable AI
./scripts/toggle-ai.sh clustereye disable   # Disable AI
./scripts/toggle-ai.sh clustereye toggle    # Smart toggle
```

## Manual Commands (No Scripts)

### Enable AI

```bash
# Create ConfigMap
kubectl create configmap clustereye-clustereye-api-ai-config \
  -n clustereye \
  --from-literal=ENABLE_AI_FEATURES=true \
  --from-literal=AI_ENDPOINT="https://o4szcpxekyj6hvcdx5ktqy2c.agents.do-ai.run/api/v1/chat/completions" \
  --from-literal=AI_TOKEN="cifsE4HtBVWFEzyXrh5E5vbU-v66wK6I" \
  --dry-run=client -o yaml | kubectl apply -f -

# Patch deployment
kubectl patch deployment clustereye-clustereye-api -n clustereye --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/envFrom",
    "value": [{"configMapRef": {"name": "clustereye-clustereye-api-ai-config"}}]
  }
]'

# Wait
kubectl rollout status deployment/clustereye-clustereye-api -n clustereye
```

### Disable AI

```bash
# Remove envFrom
kubectl patch deployment clustereye-clustereye-api -n clustereye --type=json -p='[
  {
    "op": "remove",
    "path": "/spec/template/spec/containers/0/envFrom"
  }
]'

# Delete ConfigMap (optional)
kubectl delete configmap clustereye-clustereye-api-ai-config -n clustereye

# Wait
kubectl rollout status deployment/clustereye-clustereye-api -n clustereye
```

### Check Status

```bash
# Check environment variable
POD=$(kubectl get pods -n clustereye -l app.kubernetes.io/name=clustereye-api -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n clustereye $POD -- env | grep ENABLE_AI_FEATURES

# Check logs
kubectl logs -n clustereye $POD --tail=20 | grep -i "AI"

# Test API
kubectl port-forward -n clustereye svc/clustereye-clustereye-api 8080:8080 &
curl http://localhost:8080/api/v1/ai/cache/stats
kill %1
```

## Comparison: Scripts vs Helm

| Method | Enable Time | Disable Time | Requires Helm | Persistent |
|--------|------------|--------------|---------------|------------|
| **Scripts** | ~30s | ~30s | ❌ No | ⚠️ Until next Helm upgrade |
| **Helm upgrade** | ~60s | ~60s | ✅ Yes | ✅ Permanent |

**Use Scripts When:**
- Testing AI features temporarily
- Quick enable/disable for troubleshooting
- Don't have access to Helm charts
- Need immediate toggle

**Use Helm When:**
- Permanent configuration change
- Deploying to new environment
- Managing multiple customers
- Version controlling configuration

## Important Notes

### Pod Restart Required

Both enable and disable require pod restart (happens automatically).

**Impact:**
- ~10-30 seconds downtime per pod
- Active connections will be terminated
- Plan during maintenance window if possible

### Persistence

Script changes are **temporary**:
- Survive pod restart: ✅ Yes
- Survive deployment edit: ✅ Yes
- Survive Helm upgrade: ❌ **No** (will be overwritten)

To make changes permanent:
```bash
# Update Helm values
helm upgrade clustereye . -n clustereye \
  --set clustereye-api.config.ai.enabled=true
```

### Rollback

If something goes wrong:

```bash
# Quick rollback
kubectl rollout undo deployment/clustereye-clustereye-api -n clustereye

# Or disable AI
./scripts/disable-ai.sh
```

## Verification

After enabling/disabling, verify:

```bash
# 1. Check pod status
kubectl get pods -n clustereye -l app.kubernetes.io/name=clustereye-api

# 2. Check environment variable
POD=$(kubectl get pods -n clustereye -l app.kubernetes.io/name=clustereye-api -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n clustereye $POD -- env | grep ENABLE_AI_FEATURES

# 3. Check logs
kubectl logs -n clustereye $POD | grep -i "AI"

# Expected if enabled:
# "AI features enabled - initializing AI service components"
# "AI cache initialized"
# "AI request processor worker initialized"
# "AI threshold monitor worker initialized"

# Expected if disabled:
# "AI features disabled (set ENABLE_AI_FEATURES=true to enable)"

# 4. Test API endpoint
kubectl port-forward -n clustereye svc/clustereye-clustereye-api 8080:8080 &
curl http://localhost:8080/api/v1/ai/cache/stats

# Enabled: Returns cache stats JSON
# Disabled: Returns 503 "AI features are not enabled"

kill %1
```

## Troubleshooting

### Script Fails: "Deployment not found"

**Cause:** Deployment name mismatch

**Solution:**
```bash
# List deployments
kubectl get deployments -n clustereye

# Edit script to use correct name
vim scripts/enable-ai.sh
# Change DEPLOYMENT="correct-name"
```

### AI Still Disabled After Enable

**Cause:** Pod not restarted or envFrom not applied

**Solution:**
```bash
# Force pod restart
kubectl delete pod -n clustereye -l app.kubernetes.io/name=clustereye-api

# Wait for new pod
kubectl get pods -n clustereye -l app.kubernetes.io/name=clustereye-api -w
```

### ConfigMap Not Found

**Cause:** ConfigMap creation failed

**Solution:**
```bash
# Manually create ConfigMap
kubectl create configmap clustereye-clustereye-api-ai-config \
  -n clustereye \
  --from-literal=ENABLE_AI_FEATURES=true \
  --from-literal=AI_ENDPOINT="https://o4szcpxekyj6hvcdx5ktqy2c.agents.do-ai.run/api/v1/chat/completions" \
  --from-literal=AI_TOKEN="cifsE4HtBVWFEzyXrh5E5vbU-v66wK6I"

# Then run script again
./scripts/enable-ai.sh
```

## Support

For issues:
1. Check script output for error messages
2. Verify kubectl access: `kubectl get pods -n clustereye`
3. Check pod logs: `kubectl logs -n clustereye <pod-name>`
4. Review [Main Documentation](../ENABLE_AI_QUICKSTART.md)
