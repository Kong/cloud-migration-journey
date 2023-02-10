# Cloud Migration Journey: Infrastructure Deployment

## Architecture

_**Note:** Before diving into the tutorial, there are 2 items to highlight. This guide is not intended to reflect best practices for either the AWS Infrastructure nor the Kong Components. All infrastructure and Kong components are intentionally kept minimal to enable as many individuals as possible to test, play, and learn about how Kong can enable cloud migrations._

![Cloud Migration Tutorial AWS Infrastructure](/docs/img/AWS_infra.png)

### Description

We want to brief describe all the Konnect and Kong Mesh resources that will be deployed into the AWS infrastructure.

All AWS resources are spun up in 1 VPC for simplicity, but the objective of the infra is to simulate on-prem and cloud environments.

**On-Prem Environment**

The on premise environment will be contained within public subnets. Several ubuntu EC2s are created in the public subnet:

* **Runtime-Instance + Kong Zone CP:** This EC2 will have the Konnect `runtime instance` process running and Kong Mesh `Universal Zone Services (Zone Control Plane, Zone Ingress, and Zone Egress)` will be deployed on this VM.

* **Kong Mesh Global CP:** Kong Mesh requires a global control plane, the control plane will be deployed on an EC2 to demonstrate the flexibility of Universal Mode deployment strategy Kong Mesh offers.

* **Monolith:** The sample `monolith` application will be deployed on this EC2.

The diagram also depictse a AWS Aurora Postgres DB. In Universal Mode, it is best practice to connect the **Kong Mesh Zone Control Plane** to a database.

**Cloud Environment**

An AWS EKS cluster will be used to represent the cloud environment. The EKS cluster deployed is kept as minimal as possible, 2 nodes that span at least 2 availability zones, and any required infratructure including public + private subnetting, NAT Gateways etc required by EKS.
