#!/bin/bash

# ClusterEye AI Features - Disable Script
# Usage: ./disable-ai.sh [namespace]

set -e

NAMESPACE="${1:-clustereye}"
DEPLOYMENT="clustereye-clustereye-api"
CONFIGMAP="clustereye-clustereye-api-ai-config"

echo "🤖 Disabling AI features in namespace: $NAMESPACE"

# Check if deployment exists
if ! kubectl get deployment $DEPLOYMENT -n $NAMESPACE &>/dev/null; then
    echo "❌ Error: Deployment $DEPLOYMENT not found in namespace $NAMESPACE"
    exit 1
fi

# Check if envFrom exists
if ! kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].envFrom}' | grep -q "$CONFIGMAP" 2>/dev/null; then
    echo "ℹ️  AI ConfigMap not linked to deployment (already disabled)"
else
    echo "🔓 Removing AI ConfigMap from deployment..."

    # Remove envFrom
    kubectl patch deployment $DEPLOYMENT -n $NAMESPACE --type=json -p='[
      {
        "op": "remove",
        "path": "/spec/template/spec/containers/0/envFrom"
      }
    ]'
fi

# Delete ConfigMap (optional - keeps data for future use if skipped)
if kubectl get configmap $CONFIGMAP -n $NAMESPACE &>/dev/null; then
    read -p "❓ Delete AI ConfigMap? (keeps config for future use if 'n') [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting AI ConfigMap..."
        kubectl delete configmap $CONFIGMAP -n $NAMESPACE
    else
        echo "ℹ️  Keeping ConfigMap for future use"
    fi
fi

# Wait for rollout
echo "⏳ Waiting for deployment rollout..."
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=120s

# Verify AI is disabled
echo "🔍 Verifying AI features..."
sleep 5

POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=clustereye-api -o jsonpath='{.items[0].metadata.name}')

if kubectl exec -n $NAMESPACE $POD -- env | grep -q "ENABLE_AI_FEATURES=true"; then
    echo "⚠️  Warning: AI features still enabled in pod"
    echo "Try: kubectl delete pod $POD -n $NAMESPACE"
else
    echo "✅ AI features successfully disabled!"
    echo ""
    echo "📊 Checking logs..."
    kubectl logs -n $NAMESPACE $POD --tail=20 | grep -i "AI" || echo "Expected: 'AI features disabled'"
    echo ""
    echo "🎉 Done! AI features are now inactive."
    echo ""
    echo "To verify, run:"
    echo "  kubectl port-forward -n $NAMESPACE svc/$DEPLOYMENT 8080:8080 &"
    echo "  curl http://localhost:8080/api/v1/ai/cache/stats"
    echo "  # Should return: 503 Service Unavailable"
fi
