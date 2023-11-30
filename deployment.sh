#!/usr/bin/env bash

################################################################################
### Script deploying the Observ-K8s environment
### Parameters:
### dttoken: Dynatrace api token with ingest metrics and otlp ingest scope
### dturl : url of your DT tenant wihtout any / at the end for example: https://dedede.live.dynatrace.com
################################################################################


### Pre-flight checks for dependencies
if ! command -v jq >/dev/null 2>&1; then
    echo "Please install jq before continuing"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Please install git before continuing"
    exit 1
fi


if ! command -v helm >/dev/null 2>&1; then
    echo "Please install helm before continuing"
    exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
    echo "Please install kubectl before continuing"
    exit 1
fi
echo "parsing arguments"
while [ $# -gt 0 ]; do
  case "$1" in
  --dttoken)
    DTTOKEN="$2"
   shift 2
    ;;
  --dthost)
    DTURL="$2"
   shift 2
    ;;
  *)
    echo "Warning: skipping unsupported option: $1"
    shift
    ;;
  esac
done
echo "Checking arguments"

if [ -z "$DTURL" ]; then
  echo "Error: Dt hostname not set!"
  exit 1
fi

if [ -z "$DTTOKEN" ]; then
  echo "Error: api-token not set!"
  exit 1
fi



#### Deploy the cert-manager
echo "Deploying Cert Manager ( for OpenTelemetry Operator)"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.0/cert-manager.yaml
# Wait for pod webhook started
kubectl wait pod -l app.kubernetes.io/component=webhook -n cert-manager --for=condition=Ready --timeout=2m
# Deploy the opentelemetry operator
sleep 10
echo "Deploying the OpenTelemetry Operator"
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
sleep 10

kubectl create secret generic dynatrace  --from-literal=dynatrace_oltp_url="$DTURL" --from-literal=dt_api_token="$DTTOKEN"
kubectl apply -f openTelemetry-demo/rbac.yaml
kubectl apply -f openTelemetry-demo/openTelemetry-manifest_debut.yaml

kumactl install control-plane \
  --set "controlPlane.mode=standalone" \
  --set "controlPlane.tracing.openTelemetry.endpoint=oteld-collector.default.svc.cluster.local:4317" \
  | kubectl apply -f -

#deploy demo application
kubectl create ns otel-demo
kubectl label ns otel-demo kuma.io/sidecar-injection=enabled

kubectl apply -f openTelemetry/gatewayinstance.yaml -n otel-demo

### get the ip adress of ingress ####
IP=""
while [ -z $IP ]; do
  echo "Waiting for external IP"
  IP=$(kubectl get svc -n otel-demo edge-gateway -ojson | jq -j '.status.loadBalancer.ingress[].ip')
  [ -z "$IP" ] && sleep 10
done
echo 'Found external IP: '$IP
sed -i "s,IP_TO_REPLACE,$IP," openTelemetry-demo/deployment.yaml
sed -i "s,IP_TO_REPLACE,$IP," openTelemetry-demo/gateway.yaml

kubectl apply -f openTelemetry/deployment.yaml -n otel-demo
kubectl apply -f kuma/gateway.yaml
kubectl apply -f kuma/MeshAccesslog.yaml
kubectl apply -f kuma/meshtrace.yaml


