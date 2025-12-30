#!/bin/bash

# ClusterEye AI Features - Enable Script
# Usage: ./enable-ai.sh [namespace]

set -e

NAMESPACE="${1:-clustereye}"
DEPLOYMENT="clustereye-clustereye-api"
CONFIGMAP="clustereye-clustereye-api-ai-config"

echo "🤖 Enabling AI features in namespace: $NAMESPACE"

# Check if deployment exists
if ! kubectl get deployment $DEPLOYMENT -n $NAMESPACE &>/dev/null; then
    echo "❌ Error: Deployment $DEPLOYMENT not found in namespace $NAMESPACE"
    exit 1
fi

# Create or update ConfigMap
echo "📝 Creating AI ConfigMap..."
kubectl create configmap $CONFIGMAP \
  -n $NAMESPACE \
  --from-literal=ENABLE_AI_FEATURES=true \
  --from-literal=AI_ENDPOINT="https://o4szcpxekyj6hvcdx5ktqy2c.agents.do-ai.run/api/v1/chat/completions" \
  --from-literal=AI_TOKEN="cifsE4HtBVWFEzyXrh5E5vbU-v66wK6I" \
  --dry-run=client -o yaml | kubectl apply -f -

# Check if envFrom already exists
if kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].envFrom}' | grep -q "$CONFIGMAP"; then
    echo "✅ AI ConfigMap already linked to deployment"
else
    echo "🔗 Linking AI ConfigMap to deployment..."

    # Get current envFrom (if any)
    CURRENT_ENVFROM=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].envFrom}' 2>/dev/null || echo "[]")

    # Add our ConfigMap to envFrom
    kubectl patch deployment $DEPLOYMENT -n $NAMESPACE --type=json -p="[
      {
        \"op\": \"add\",
        \"path\": \"/spec/template/spec/containers/0/envFrom\",
        \"value\": [
          {
            \"configMapRef\": {
              \"name\": \"$CONFIGMAP\"
            }
          }
        ]
      }
    ]"
fi

# Wait for rollout
echo "⏳ Waiting for deployment rollout..."
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=120s

# Verify AI is enabled
echo "🔍 Verifying AI features..."
sleep 5

POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=clustereye-api -o jsonpath='{.items[0].metadata.name}')

if kubectl exec -n $NAMESPACE $POD -- env | grep -q "ENABLE_AI_FEATURES=true"; then
    echo "✅ AI features successfully enabled!"
    echo ""
    echo "📊 Checking logs..."
    kubectl logs -n $NAMESPACE $POD --tail=20 | grep -i "AI" || echo "No AI logs yet (pod may still be starting)"
    echo ""
    echo "🎉 Done! AI features are now active."
    echo ""
    echo "To verify, run:"
    echo "  kubectl port-forward -n $NAMESPACE svc/$DEPLOYMENT 8080:8080 &"
    echo "  curl http://localhost:8080/api/v1/ai/cache/stats"
else
    echo "⚠️  Warning: ENABLE_AI_FEATURES environment variable not found"
    echo "Check pod logs: kubectl logs -n $NAMESPACE $POD"
fi
