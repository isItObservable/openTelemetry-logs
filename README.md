# Is it Observable
<p align="center"><img src="/image/logo.png" width="40%" alt="Is It observable Logo" /></p>

## Episode : Collecting logs with the OpenTelemetry Logs
<p align="center"><img src="/image/kuma_logo.jpg" width="40%" alt="Is It observable Logo" /></p>
This repository contains the files utilized during the tutorial presented in the dedicated IsItObservable episode related to the episode explaining how to collect logs with the OpenTelemtry collector.
this tutorial will also utilize the OpenTelemetry Transformation Language.

This repository showcase the usage of the openTelemetry collector with :
* The OpenTelemetry demo
* Dynatrace

We will send all Telemetry data produced by otel-demo to Dynatrace.

## Prerequisite
The following tools need to be install on your machine :
- jq
- kubectl
- git
- gcloud ( if you are using GKE)
- Helm


### 1.Create a Google Cloud Platform Project
```shell
PROJECT_ID="<your-project-id>"
gcloud services enable container.googleapis.com --project ${PROJECT_ID}
gcloud services enable monitoring.googleapis.com \
cloudtrace.googleapis.com \
clouddebugger.googleapis.com \
cloudprofiler.googleapis.com \
--project ${PROJECT_ID}
```
### 2.Create a GKE cluster
```shell
ZONE=europe-west3-a
NAME=isitobservable-otel-logs
gcloud container clusters create ${NAME} --zone=${ZONE} --machine-type=e2-standard-4 --num-nodes=2
```

## Getting started
### Dynatrace Tenant
#### 1. Dynatrace Tenant - start a trial
If you don't have any Dynatrace tenant , then i suggest to create a trial using the following link : [Dynatrace Trial](https://bit.ly/3KxWDvY)
Once you have your Tenant save the Dynatrace tenant url in the variable `DT_TENANT_URL` (for example : https://dedededfrf.live.dynatrace.com)
```
DT_TENANT_URL=<YOUR TENANT Host>
```

#### 2. Create the Dynatrace API Tokens
Create a Dynatrace token with the following scope ( left menu Acces Token):
* ingest metrics
* ingest OpenTelemetry traces
* ingest logs
<p align="center"><img src="/image/data_ingest.png" width="40%" alt="data token" /></p>
Save the value of the token . We will use it later to store in a k8S secret

```
DATA_INGEST_TOKEN=<YOUR TOKEN VALUE>
```
### Kuma

1. Download kumactl
```shell
curl -L https://kuma.io/installer.sh | VERSION=2.5.0 sh -
```
This command download the latest version of kuma ( in our case kuma 2.4.3) compatible with our operating system.
2. Add kumactl to your PATH
```shell
cd kuma-2.5.0/bin
```
this directory contains samples with addons . We will refer to it later.
```shell
export PATH=$PWD/bin:$PATH
```

### Clone the Github Repository
```shell
https://github.com/isItObservable/openTelemetry-logs
cd openTelemetry-logs
```

### Deploy most of the components
The application will deploy the entire environment:
```shell
chmod 777 deployment.sh
./deployment.sh   --dthost "${DT_TENANT_URL}" --dttoken "${DATA_INGEST_TOKEN}" 
```
