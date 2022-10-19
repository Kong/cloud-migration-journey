# Kong Migration Journey: Infrastructure Deployment

## Architecture

_**Note:** Before diving into the AWS infrastructure deployed by the cloud migration terraform scripts we should highlight 2 items. This guide is not intended to reflect best practices for either the AWS Infrastructure nor the Kong Components. All infrastructure and Kong components are intentionally kept minimal to enable as many individuals as possible to test, play, and learn about how Kong can enable cloud migrations._

![Cloud Migration Tutorial AWS Infrastructure](/docs/img/AWS_infra.png)

### Description

All AWS resources are spun up in 1 VPC for simplicity. The objective of the AWS Infrastructure is to simulate on-prem and cloud environments. The public subnet containing the ec2-instances and postgres DB will behave as the On-Premise Zone and the Amazon EKS cluster will serve as the Cloud Zone.

**On-Prem Environment**

The on premise environment simulation will be contained within public subnets. For ubuntu ec2-instances are created in the public subnet:

* **Runtime-Instance + Kong Zone CP:** Konnect Dataplane and Kong Mesh Universal Zone Services (Zone Control Plane, Zone Ingress, and Zone Egress) will be deployed on this VM.

* **Kong Mesh Global CP:** Kong Mesh requires a Global Control Plane, the Control Plane will be deployed on an ec2-instance to demonstrate the flexibility of Kong Mesh Universal Mode.

* **Monolith:** The sample monolith application will be deployed on this ec2-instance.

The diagram also demonstrates a AWS Aurora Postgres DB. In Universal Mode, the **Kong Mesh Zone Control Plane** requires a Database to allow traffic to continue to flow through the mesh incase it is disconnected from the Global Control Plane.

**Cloud Environment**

An Amazon EKS cluster will be used to represent the Cloud Environment. The EKS cluster was deployed is kept as minimal as possible, 2 nodes that span at least 2 availability zones, and any required infratructure including public + private subnetting, NAT Gateways etc required by EKS.
