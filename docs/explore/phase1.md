# Kong Migration Journey: Phase 1

## Objective

The `objective` of phase 1 is to focus on the on-premise environment and familiarize ourselves with Konnect, Kong's managed API Gateway Platform, and configure the Konnect Runtime Group to expose the Monolith through the Runtime Instance.

The high level `activities` that will take place in this phase are:

* Configure Konnect Runtime Group to expose the Monolith Application.

* Verify the configuration and connectivity to the Monolith through the Runtime Instance.

At the end of phase 1 you should be `comfortable` with the following:

* Understand how the Konnect Runtime Instance is deploy on the "on-premise" VM.

* How to configure Gateway Services and Routes in a Konnect Runtime Group.

* How to reach an API exposed by the the Runtime Instance.

## Architecture

![Cloud Migration Tutorial - Phase 1](/docs/img/Phase_1.png)

Konnect, is Kong's SAAS API Platform, that gives us a singly managed control plane to deploy and manage our APIs in any environment. In this case of our Cloud Migration, we deployed our Konnect Runtime Instance to a VM in the subnet we designated as our `On-Premise Environment`. Using ansible, the deployment of the runtime instance and the monolith app were automated away.

## Explore

Here we will review through the ansible inventory, ssh into the ec2-instances to quickly explore the setup, and end with configuring the Konnect Runtime Instance and validation by consuming the monolith through.

### On Prem Env

First, let's open the ansible inventory file and grab the gateway and monolith host IPs.

```console
cat ~/.kmj/ansible/inventory.yml
```

Grab the public IPs of the gateway (runtime instance) and monolith. An example of yaml is below:

```yaml
    gateway:
      hosts:
        18.237.252.125:
    ...
    monolith:
      hosts:
        35.92.105.241:
```

**Monolith**

Let's ssh into the monolith to validate it is running:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@35.92.105.241
```

```console
$ docker ps 
CONTAINER ID   IMAGE                      COMMAND                  CREATED         STATUS         PORTS                                        NAMES
b6c23c5bbfb5   djfreese/monolith:latest   "/opt/eap/bin/opensh…"   4 minutes ago   Up 4 minutes   8443/tcp, 0.0.0.0:8080->8080/tcp, 8778/tcp   monolith
```

You should see a docker container, monolith, running.

**Runtime Instance**

Now from your host machine ssh into the gateway (runtime instance) to check out how it is running.

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@18.237.252.125
```

With Konnect it is possible to host Runtime Instances (Kong Gateway Dataplanes) with Docker, VMs, or Kubernetes. For the purpose of this demo and simplicity we deployed our dataplane with docker. This can be validated by checking the docker containers running on the server.

```console
$ docker ps 
CONTAINER ID   IMAGE                       COMMAND                  CREATED              STATUS                        PORTS     NAMES
ec967d53cd63   kong/kong-gateway:2.8.1.2   "/docker-entrypoint.…"   About a minute ago   Up About a minute (healthy)             kong-dp
```

You should be able to see a docker container, kong-dp, running on the VM.

Now, let's navigate up to the Konnect console to review and configure the Runtime Group.

### Configure Konnect Runtime Group

### Validation
