# Cloud Migration Journey Demo

<p align="center">
  <img src="https://2tjosk2rxzc21medji3nfn1g-wpengine.netdna-ssl.com/wp-content/uploads/2018/08/kong-combination-mark-color-256px.png" /></div>
</p>

**Learn how Konnect and Kong Mesh can be leveraged to de-risk and lift-and-shift connections during a migration to the cloud.**

## Table of Contents


<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=6 orderedList=true} -->

<!-- code_chunk_output -->

1. [Table of Contents](#table-of-contents)
2. [Description and purpose](#cloud-migration-journey-overview)
    1. [Migration Journey Phases](#phases)
3. [Using this repository](#using-this-repository)
    1. [Prerequisites](#prerequisites)
    2. [Getting Started](#getting-started)
    3. [Tutorial](#tutorial)
    4. [Cleanup](#cleanup)
4. [License](#license)

<!-- /code_chunk_output -->

## Cloud Migration Journey Overview

You will step through a 3-phased approach to migration and modernization together. In this tutorial we will deprecrate a monolith, running on premise, for a new microservice running a Kuberentes cluster leveraging both Konnect and Kong Mesh to support the effort.

### Monolith to Microservice

The Monolith is a Java Based Application Server that contains 4 features: Card, Balances/Charges, Payments, and Disputes. The Disputes functionality of the monolith will be deprecated for a new disputes microservice.

<p align="center">
    <img src="docs/img/monolith-microservice.png" width="700"/></div>
</p>

### Phases

Each phase has an explicit objective, and will build upon the previous.

**Phase 1 :** During this Phase the Monolith and Konnect Dataplane(also referred to as a runtime instance) will be deployed. The objective of this phase is to familiarize yourself with Konnect and step through how to expose the Monolith through the Konnect.

**Phase 2 :** In Phase 2, we will begin to deploy the Kong Mesh Global Control Plane and the On-Premise Environment. The objective of this phase is to familize ourselves with Kong Mesh Global Control Plane, Universal Mode, the concept of Kong Mesh Zones, and finish with re-configure our Konnect Runtime-instance so that communication flows over the mesh network.

**Phase 3 :** Finally, in Phase 3 it's time to cutover. The objective is to deploy the Kong Mesh Cloud Zone and Microservice to the Amazon EKS, and execute the Traffic Route Policy that will re-direct traffic to the microservice.

## Using this Repository

This repository uses a `Makefile` as the main entry-point for the demo.  We are using `AWS` for our demo infrastructure, `Terraform` to deploy the AWS infrastructure, and `Ansible` to deploy the Kong services to the environments.  In addition, we are using `Docker` to package up the code found in this repository and any tooling required to simplify the locally installed prerequisites for the user of this project.

### Prerequisites

The following is required to use this demo repository:

1. Linux or MacOS
1. AWS account with permissions to create VPCs, Subnets, EC2 instances, EKS Clusters, Keys, etc.
1. A [Kong Konnect](https://cloud.konghq.com/login) account and Runtime Group ID
    * Credentials - email and password
    * Control Plane instance ID - this is described in more detail in the Kong Konnect documentation [Set up a Runtime](https://docs.konghq.com/konnect/getting-started/configure-runtime/#set-up-a-new-runtime-instance)
1. A Kong Enterprise license - optional.
1. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
1. [Docker](https://docs.docker.com/engine/install/) or [Docker Desktop](https://docs.docker.com/engine/install/#desktop)
1. [Insomnia](https://insomnia.rest/download)
1. [Make](https://www.gnu.org/software/make/)

    ```bash
    # MacOS
    brew install make

    # Debian (Ubuntu)
    apt-get install make

    # Enterprise Linux
    yum install make
    ```

### Getting Started

Once the prerequisites have been met, you can start using this project. One each make step of has been completed, navigate to the respective `Explore` documentation to follow through each deep dive.

From your shell:

#### Step 1 - Clone the Demo from GitHub

Clone the repo to your computer:

```sh
git clone git@github.com:Kong/migration-journey.git
```

Change directory to your cloned repo from the previous step:

```sh
cd migration-journey
```

View the available `make` targets for the project:

```sh
make
```

#### Step 2 - Build the utility containers required to run the demo

```sh
make build
```

#### Step 3 - Prep Your Computer to Run the Demo

```sh
make prep
```

This will create a `.kmj` directory in your `$HOME`, and prompt for various inputs:

1. AWS CLI credentials are configured  
2. The path to the kong license
3. Open the Kong Migration Journey configuration file (users.tfvars) where you populate the Kong Konnect information, and can make any changes to your AWS infrastructure settings (AWS Region, VPC, Subnets).

#### Step 4 - Deploy the cloud infrastructure

```sh
make infra.deploy
```

This will create all the required AWS infrastructure, as well as generate an Ansible inventory file and other variables files for the demo in your `~/.kmj` directory (created by `make prep`).  It will also generate the `kubeconfig`, and EC2 keys for accessing your cloud infrastructure.  
> **NOTE:** It is extremely important that you do not remove your `~/.kmj` directory, or any of its contents at this point.  You will have a hard time cleaning up later.

[Explore: infrastructure deployment](docs/explore/infra_deploy.md).

### Tutorial

With the infrastructure successfully deployed, you are ready to start the tutorials. In each phase, first execute the make command that will install the Konnect and Kong Mesh Services in your AWS infrastructure, then proceed to the tutorial.

#### Step 5 - Execute the Cloud Migration Journey Phase 1

```sh
make kong.phase1
```

Navigate to the tutorial [Explore: Phase 1](docs/explore/phase1.md).

#### Step 6 - Execute the Cloud Migration Journey phase 2

```sh
make kong.phase2
```

Navigate to the tutorial [Explore: Phase 2](docs/explore/phase2.md).

#### Step 7 - Execute the Cloud Migration Journey phase 3

```sh
make kong.phase3
```

Navigate to the tutorial [Explore: Phase 3](docs/explore/phase3.md).

### Cleanup

Remove the cloud infrastructure and everything on it:

```sh
make infra.destroy
```

The above command will remove everything that was created in AWS, along with your EC2 keys, kubeconfig, Ansible inventory, and variables.  

Once the above process has completed successfully, you can comfortably remove your configuration directory if desired, or retain it to run the demo again later:

```sh
rm -rf ~/.kmj
```

## License

[Apache 2.0](LICENSE)