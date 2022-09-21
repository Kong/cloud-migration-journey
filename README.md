# Kong Migration Journey Demo

<p align="center">
  <img src="https://2tjosk2rxzc21medji3nfn1g-wpengine.netdna-ssl.com/wp-content/uploads/2018/08/kong-combination-mark-color-256px.png" /></div>
</p>


## Table of Contents


<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=6 orderedList=true} -->

<!-- code_chunk_output -->

1. [Table of Contents](#table-of-contents)
2. [Description and purpose](#description-and-purpose)
    1. [Migration Journey Phases](#migration-journey-phases)
3. [Using this repository](#using-this-repository)
    1. [Prerequisites](#prerequisites)
    2. [Getting Started](#getting-started)
    3. [Cleanup](#cleanup)
4. [License](#license)

<!-- /code_chunk_output -->


## Description and purpose

This demo will provide you with an understanding of how Kong Gateway and Kong Mesh can be leveraged to de-risk and lift-and-shift connections during a migration to the cloud.  We will deploy an example monolithic application (in the cloud) to simulate an on-premise environment.  We will also deploy a Kubernetes environment where services migrated from the monolith will be moved to.  


### Migration Journey Phases

In phase 1 we will ...  (high level descriptions please)

In phase 2 we will ...  

In phase 3 we will ...


## Using this repository

This repository uses a `Makefile` as the main entry-point for the demo.  We are using `AWS` for our demo infrastructure, `Terraform` to deploy the AWS infrastructure, and `Ansible` to deploy the Kong services to the environments.  In addition, we are using `Docker` to package up the code found in this repository and any tooling required to simplify the locally installed prerequisites for the user of this project.


### Prerequisites

The following is required to use this demo repository:

1. Linux or MacOS
1. AWS account with permissions to create VPCs, Subnets, EC2 instances, EKS Clusters, Keys, etc.
1. A [Kong Konnect](https://cloud.konghq.com/login) account and instance group
1. A Kong Enterprise license (optional)
1. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
1. [Docker](https://docs.docker.com/engine/install/) or [Docker Desktop](https://docs.docker.com/engine/install/#desktop)
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

Once the prerequisites have been met, you can start using this project.

From your shell:
1. Clone the repo to your computer:
    > `git clone git@github.com:Kong/migration-journey.git`

1. Change directory to your cloned repo from the previous step

1. View the available `make` targets for the project:
    > `make`

1. Build the utility containers required to run the demo:
    > `make build`

1. Prepare your computer to run the demo:
    > `make prep`

    This will create a `.kmj` directory in your `$HOME`, as well as ensure you have your AWS CLI credentials configured.  This will also open up the Kong Migration Journey configuration file, where you populate the Kong Konnect information, as well as make changes to your AWS deployment settings.

1. Deploy the cloud infrastructure:
    > `make infra.deploy`

    This will create all the required cloud infrastructure, as well as generate an Ansible inventory file and other variables files for the demo in your `~/.kmj` directory (created by `make prep`).  It will also generate a `kubeconfig`, and EC2 keys for accessing your cloud infrastructure.  
    > **NOTE:** It is extremely important that you do not remove your `~/.kmj` directory, or any of its contents at this point.  You will have a hard time cleaning up later.

    [Explore: infrastructure deployment](docs/explore/infra_deploy.md).

1. Deploy the Kong Migration Journey phase 1:
    > `make kong.phase1`

    [Explore: Phase 1](docs/explore/phase1.md).

1. Deploy the Kong Migration Journey phase 2:
    > `make kong.phase2`

    [Explore: Phase 2](docs/explore/phase2.md).

1. Deploy the Kong Migration Journey phase 3:
    > `make kong.phase3`

    [Explore: Phase 3](docs/explore/phase3.md).


### Cleanup

1. Remove the cloud infrastructure and everything on it:
    > `make infra.destroy`

    This will remove everything that was created in AWS, along with your EC2 keys, kubeconfig, Ansible inventory, and variables.  Once this process has completed successfully, you can comfortably remove your configuration directory if desired, or retain it to run the demo again later:
    
    > `rm -rf ~/.kmj`


## License

[Apache 2.0](LICENSE)