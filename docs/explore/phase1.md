# Kong Migration Journey: Phase 1

The `make kong.phase1` created:

* Deployed the Monolith
* Deployed the Konnect Data-plane, also referred to as Runtime Instance or Gateway

## Objective

The purpose of phase 1 is to focus on the on-premise environment setup.  You will configure the Konnect Runtime Group to expose the Monolith through the Runtime Instance.

The high level `activities` that will take place in this phase are:

* Configure Konnect Runtime Group to expose the monolith app.

* Verify the configuration and connectivity to the monolith through the runtime instance.

## Architecture

This is the overview of the architecture used in phase 1.

There are 2 VMs:

1. The monolith is deployed as a docker process.
2. The konnect runtime instance is deployed also as a docker process.

Kong Konnect is where all of the API administration happens.

![Cloud Migration Tutorial - Phase 1](/docs/img/Phase_1.png)

## Explore

Here we will review the Ansible inventory, SSH into the AWS EC2 instances to quickly explore the setup.  We'll finish up by configuring the Konnect runtime group and validating the monolith API can be called through the runtime instance.

### On Premise Environment

**Monolith**

Go into the demo_facts `~/.kmj/ansible/demo_facts.json` and copy the command to SSH into the monolith:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@35.92.105.241
```

```console
$ docker ps 
CONTAINER ID   IMAGE                      COMMAND                  CREATED         STATUS         PORTS                                        NAMES
b6c23c5bbfb5   djfreese/monolith:latest   "/opt/eap/bin/opensh…"   4 minutes ago   Up 4 minutes   8443/tcp, 0.0.0.0:8080->8080/tcp, 8778/tcp   monolith
```

You will see a docker container, monolith, running.

**Runtime Instance**

Now from your host machine, SSH into the runtime instance to observe how it is running.

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@18.237.252.125
```

For the purpose of this demo the Konnect Runtime instance is deployed as a docker container.

```console
docker ps
```

You will see a docker container with the name `kong-dp` running on the EC2 instance. Here's an example:

```console
CONTAINER ID   IMAGE                       COMMAND                  CREATED              STATUS                        PORTS     NAMES
ec967d53cd63   kong/kong-gateway:2.8.1.2   "/docker-entrypoint.…"   About a minute ago   Up About a minute (healthy)             kong-dp
```

### Configure Konnect Runtime Group

**Objective:** Create a `Gateway Service` and `Route` to expose the Monolith through the runtime instance.

1. Login into [Konnect](https://cloud.konghq.com/login) and you will be directed to the Runtime Manager Menu.

![Phase 1 - 1_runtime manager](/docs/img/phase_1/1_runtimeManager.png)

2. From the Runtime Manager Page, select the appropriate `Runtime Group` where you deployed the runtime instance &#8594; in the left hand panel navigate to `Gateway Services`.

3. In the Gateway Services Page Select the `+ New Gateway Service` button in the menu.

4. In the `Add a new gateway service` menu - configure the Gateway Service:

    * Select the `Add using Protocol, Host and Path` radio button.
    
    * Fill in the following information regarding how to reach the backend Monolith Application:
        * **Gateway Service Name** = `Migration`
        * **Protocol** = `http`
        * **Host** = "< *enter your monolith IP address* >"
        >**NOTE:** *This can be obtained from the file `~/.kmj/ansible/demo_facts.json`*
        * **Path** = `/monolith/resources/` 
        >**NOTE:** *the base url of the Monolith Web Service*
        * **Port** = `8080`

    * Save the Gateway Service

An example Gateway Service is depicted below.

<p align="center">
    <img src="../img/phase_1/2_gatewayservice.png" width="500" /></div>
</p>

5. When the Gateway Service is saved - you are dropped into a menu page describing the gateway service details.

6. Next you need to `Add a route` - scroll down the gateway service page until you see the `Routes` module &#8594; select `+ Add Route`:

    * Fill in the following information regarding how to expose the Monolith through the Runtime Instance:
        * **Route Name** = `OnPrem`
        * **Protocols** = `http`
        * **Method(s)** = `GET`
        * **Path(s)** = `/onprem`

    * Save the Route

An example Route is shown below.

<p align="center">
    <img src="../img/phase_1/3_route.png" width="400" /></div>
</p>

Now we are ready to validate that you can consume the monolith application via the Konnect runtime instance.

### Validation

`Objective`: Call `On Prem Route` exposed on the runtime instance and validate all monolith Web Services are reachable. Most importantly, we'll be taking a look at the behavior of the Monolith Disputes API.

1. Open Insomnia &#8594; Navigate to Dashboard &#8594; Select `Create` dropdown in the top left &#8594; Import From `+ File` &#8594; the insomnia collection is located under `cloud-migration-journey/docs/insomnia`

2. Navigate into the `Migration Journey` Collection &#8594; Open `Phase 1 - OnPrem` subfolder

3. For each request hit `Send`, you will be prompted to copy in the Runtime Instance IP (you can get this from the `~/.kmj/demo_facts.json` file, and will be the monolith's IP address).

**Disputes Validation**

We want to take a close look at the functionality of the `Disputes` API. In the monolith it does not offer much functionality at the moment. Take a look at the example output below:

<p align="center">
    <img src="../img/phase_1/4_insomnia_disputes.png" width="800" /></div>
</p>

This is the functionality (or the lack of) that we want to deprecate in favor for a new `Disputes Microservice` which will later offer more functionality to our customers.

## Closing and Recap

**This is the end of Phase 1**

Just to Recap.

The objective of phase 1 was to configure the on-premise environment, and protect the `monolith` with a Konnect `runtime instance`.

In phase 2, Kong Mesh will be introduced.

Let's proceed with [Tutorial: Step 6 - Run Migration Journey Phase 2](../../README.md#step-6---run-migration-journey-phase-2).