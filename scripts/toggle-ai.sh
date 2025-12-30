#!/bin/bash

# ClusterEye AI Features - Toggle Script
# Usage: ./toggle-ai.sh [namespace] [enable|disable|status]

set -e

NAMESPACE="${1:-clustereye}"
ACTION="${2:-status}"
DEPLOYMENT="clustereye-clustereye-api"
CONFIGMAP="clustereye-clustereye-api-ai-config"

# Check current status
check_status() {
    if ! kubectl get deployment $DEPLOYMENT -n $NAMESPACE &>/dev/null; then
        echo "❌ Error: Deployment $DEPLOYMENT not found in namespace $NAMESPACE"
        return 1
    fi

    POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=clustereye-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

    if [ -z "$POD" ]; then
        echo "❌ No pods found for deployment $DEPLOYMENT"
        return 1
    fi

    if kubectl exec -n $NAMESPACE $POD -- env 2>/dev/null | grep -q "ENABLE_AI_FEATURES=true"; then
        echo "✅ AI features: ENABLED"
        return 0
    else
        echo "❌ AI features: DISABLED"
        return 1
    fi
}

# Main logic
case "$ACTION" in
    status)
        echo "🔍 Checking AI status in namespace: $NAMESPACE"
        check_status
        ;;

    enable)
        echo "🤖 Enabling AI features..."
        $(dirname "$0")/enable-ai.sh "$NAMESPACE"
        ;;

    disable)
        echo "🤖 Disabling AI features..."
        $(dirname "$0")/disable-ai.sh "$NAMESPACE"
        ;;

    toggle)
        echo "🔄 Toggling AI features..."
        if check_status &>/dev/null; then
            echo "Currently enabled - disabling..."
            $(dirname "$0")/disable-ai.sh "$NAMESPACE"
        else
            echo "Currently disabled - enabling..."
            $(dirname "$0")/enable-ai.sh "$NAMESPACE"
        fi
        ;;

    *)
        echo "Usage: $0 [namespace] [enable|disable|status|toggle]"
        echo ""
        echo "Examples:"
        echo "  $0                           # Check status (default namespace: clustereye)"
        echo "  $0 clustereye status         # Check status"
        echo "  $0 clustereye enable         # Enable AI features"
        echo "  $0 clustereye disable        # Disable AI features"
        echo "  $0 clustereye toggle         # Toggle current state"
        exit 1
        ;;
esac
