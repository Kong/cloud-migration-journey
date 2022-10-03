# Kong Migration Journey: Infrastructure Deployment

## Architecture

![Cloud Migration Tutorial AWS Infrastructure](/docs/img/AWS_infra.png)

### Description

_**Note:** Before diving into the AWS infrastructure deployed by the cloud migration terraform scripts we should highlight 2 items. This guide is not intended to reflect best practices for either the AWS Infrastructure nor the Kong Components. All infrastructure and Kong components are intentionally kept minimal to enable as many individuals as possible to test, play, and learn about how Kong can enable cloud migrations._

All AWS resources are spun up in 1 VPC for simplicitity. The objective of the AWS Infrastructure is to simulate an on-prem and cloud environments. The public subnet containing the ec2-instances and postgres DB will behave as the On-Premise Zone and the Amazon EKS cluster will serve as the cloud zone.

**On-Prem Environment**

The on premise environment simulation will be contained within public subnets. For ubunut ec2-instances are created in the public subnet:

* **Runtime-Instance + Kong Zone CP:** Konnect Dataplane and Kong Mesh Universal Zone Services (Zone Control Plane, Zone Ingress, and Zone Egress) will be deployed on this VM.

* **Kong Mesh Global CP:** Kong Mesh requires a Global Control Plane, the Control Plane will be deployed on an ec2-instance to demonstrate the flexibility of Kong Mesh Universal Mode.

* **Monolith:** The sample monolith application will be deployed on this ec2 instance

The diagram also demonstrates a AWS Aurora Postgres DB. In Universal Mode, the Kong Mesh _Zone_ Control Plane requires a Database to allow traffic to continue to flow through the mesh incase it is disconnected from the Global Control Plane.

**Cloud Environment**


## Explore

do this, do that, look at this, look at that