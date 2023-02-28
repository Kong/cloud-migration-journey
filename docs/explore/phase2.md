# Kong Migration Journey: Phase 2

The `make kong.phase2` created:

* Kong Mesh `Global Control Plane`
* Kong Mesh `On-Prem Zone` using the Universal Mode deployment strategy
* Deployed Kong Mesh *data-planes* to the monolith and Konnect Runtime Instance

## Objective

The purpose of Phase 2 is to begin exploring Kong Mesh and reconfigure Konnect so that traffic from the runtime instance to the monolith flows over the mesh network, adding additional protection via MTLS encryption.

The high level `activities` that will take place are:

* Review the Kong Mesh Global Control Plane and Zone setup.

* Review the Kong Mesh Data-plane (also known as a Sidecar Proxy) deployed beside the monolith and runtime instance.

* Reconfigure Konnect for traffic between the monolith and the runtime instance to move over the mesh network.

## Architecture

<p align="center">
    <img src="../img/phase_2/1_reference_arch.png" width="800" /></div>
</p>

**Kong Mesh Global Control Plane**

The Kong Mesh `Global Control Plane` is deployed into an EC2 instance in Kong Mesh `multi-zone mode`, but it could equally have been deployed on a Kubernetes cluster. The Global Control Plane is responsible for:

* administrative activities, such as creating/changing/deleting any mesh policies
* synchronizing mesh configuration changes to the zone control planes

**Kong Mesh Zone Services**

There are several types of Kong Mesh zone services: `Zone Control Plane`, `Zone Ingress` and `Zone Egress`.

`Zone Control Plane` has 2 major functions:

1. `Interact with the Global Control Plane` - Register itself to the global control plane. The global control plane will propagate all polices to the zone control plane, and vice versa the zone control plane sends data back to the global control plane.

2. `Interact with Dataplanes` - Within a zone, data-planes will join or be rejected by the zone control plane, and the zone control plane will propagate policies from the global to each data-plane proxy.

`Zone Ingress and Egresses` have the responsibility of proxying traffic between mesh data-plane proxies existing in other zones. Inbound traffic (Ingress) goes into the local data-plane proxy for a particular zone. Outbound traffic (Egress) goes out of its local zone to another zone's ingress and also supports reaching external services.

**Data-plane Proxies**

Any application that is intended to be a part of the mesh network requires a data-plane proxy (sidecar).

In this case, the `monolith` and Konnect `runtime instance` were each provisioned mesh data-planes. The mesh data-planes register with the mesh zone control plane, and will communicate through mesh data-planes running in the local zone when communicating between the monolith and Konnnect runtime-instance.  The mesh data-planes will also communicate with a zone's ingress/egress to send traffic across zones within the mesh.

**Universal Mode**

All these services were deployed as processes onto VMs: `global control plane`, `zone cp`, `zone ingress`, `zone egress`, `dataplane`, which are referred to as Universal Mode in the Kong Mesh Documentation.

## Explore Infrastructure

### Global Control Plane

**Global Control Plane GUI**

Within the demo_facts `~/.kmj/ansible/demo_facts.json` file, copy the `global_cp_url` and open it up in the browser.

Today the GUI behaves in `READ-ONLY` mode.

The GUI is informative, because it provides the general state of the Mesh Infrastructure: number of zones, data-planes, deployment strategies. You can observe any resource's configuration or services recognized as part of the mesh such as the health of the zone control planes, ingresses, egresses, and data-planes.

`In Summary`

You should be able to see:

1. The global control plane is running in `Multi-Zone Mode`.

2. We created an `On-Prem` zone.

3. We have a zone ingress and zone egress deployed in the "On-Prem" zone.

4. We have `2 Dataplanes` deployed in the "On-Prem" zone.

**Global Control Plane VM**

Each of the Kong Mesh processes are configured and running as `systemd` processes on the EC2 instance. We will inspect this within this section.

From within the demo_facts file `~/.kmj/ansible/demo_facts.json`, copy the SSH command to reach the global control plane (`ssh_global_cp`), and run the command like so:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@35.85.31.178
```

Observe the state of the kuma-cp service:

```console
sudo systemctl status kuma-cp
```

Example output:

```console
● kuma-cp.service - Kuma Global Control Plane
     Loaded: loaded (/etc/systemd/system/kuma-cp.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2022-10-04 21:21:37 UTC; 15h ago
   Main PID: 9676 (kuma-cp)
      Tasks: 6 (limit: 2351)
     Memory: 31.3M
        CPU: 2min 16.109s
     CGroup: /system.slice/kuma-cp.service
             └─9676 /home/kuma/mesh/kong-mesh-1.8.1/bin/kuma-cp --log-output-path=/tmp/kuma-cp.log run --license-path=/home/kuma/license.json

Oct 04 21:21:37 ip-10-0-0-47 systemd[1]: Started Kuma Global Control Plane.
Oct 04 21:21:37 ip-10-0-0-47 bash[9676]: kuma-cp: logs will be stored in "/tmp/kuma-cp.log"
```

**On-Prem Zone Control Plane**

Now we will observe the setup of the zone's services.

From within the demo_facts file `~/.kmj/ansible/demo_facts.json`, copy the SSH command to reach the runtime instance `ssh_runtime_instance`, and run the command like so:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@18.237.252.125
```

`Kuma-Zone-CP`

Again, the zone is the same binary as the global control plane, and can be observed as shown in the example below:

```console
sudo systemctl status kuma-zone-cp
```

Example output:

```console
● kuma-zone-cp.service - Kuma Zone Control Plane
     Loaded: loaded (/etc/systemd/system/kuma-zone-cp.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2022-10-04 21:21:57 UTC; 17h ago
   Main PID: 221050 (kuma-cp)
      Tasks: 6 (limit: 2351)
     Memory: 38.9M
        CPU: 5min 50.429s
     CGroup: /system.slice/kuma-zone-cp.service
             └─221050 /home/kuma/mesh/kong-mesh-1.8.1/bin/kuma-cp --log-output-path=/tmp/kuma-cp.log run --license-path=/home/kuma/license.json
```

However, setup of the zone control-plane requires a couple of extra environment variables configured withing the systemd service: `KUMA_MODE`, `ZONE_NAME`, `GLOBAL_ADDRESS`. These are articulated in the systemd unit/service file:

```console
cat /etc/systemd/system/kuma-zone-cp.service
```


Example output:
```console
ExecStart = /bin/bash -c 'KUMA_MODE=zone \
  KUMA_MULTIZONE_ZONE_NAME=on_prem \
  KUMA_MULTIZONE_ZONE_GLOBAL_ADDRESS=grpcs://35.85.31.178:5685 \
 /home/kuma/mesh/kong-mesh-1.8.1/bin/kuma-cp --log-output-path=/tmp/kuma-cp.log run --license-path=/home/kuma/license.json'
```

`Zone Ingress`

Zone ingresses and egresses are actually data-planes and require a manifest that describes how the ingress can be reached.

Run the following:

```console
sudo cat /home/kuma/dataplane-ingress.yaml
```

The output will look similar to below:

```yaml
type: ZoneIngress
name: universal-zone-ingress-on_prem
networking:
  address: 10.0.0.36  # address that is routable within the zone
  port: 10001 
  advertisedAddress: 10.0.0.36 # relevant if zone ingress resides behind a load balancer
  advertisedPort: 10001 # relevant if zone ingress resides behind a load balancer
  admin:
    port: 30002 
```

Looking at the `kuma-ingress` service we can confirm that the process is `kuma-dp` used for dataplanes, and the ingress manifest is referenced.

Run the following:

```console
cat /etc/systemd/system/kuma-ingress.service
```

The output will look similar to below:

```console
ExecStart = /usr/bin/bash -c '/home/kuma/mesh/kong-mesh-1.8.1/bin/kuma-dp \
    --log-output-path=/tmp/kuma-ingress.log run \
    --cp-address=https://10.0.0.36:5678 \   
    --dataplane-token-file=/home/kuma/ingress.token \
    --dataplane-file=/home/kuma/dataplane-ingress.yaml \
    --proxy-type ingress > /tmp/kuma-ingress.stdout 2> /tmp/kuma-ingress.stderr'
```

**On Prem Data-planes**

Last, let's explore the runtime instance and monolith dataplanes.

`Runtime Instance Dataplane`

From within the demo_facts file `~/.kmj/ansible/demo_facts.json`, copy the SSH command to reach the runtime instance `ssh_runtime_instance` and run the command like so:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@18.237.252.125
```

Take a look at the `Dataplane Manifest` for the runtime instance by running:

```console
cat /home/kuma/dataplane-nontransparent.yaml
```

The output will look similar to:

```yaml
type: Dataplane
mesh: default
name: kong
networking:
  address: 10.0.0.36
  gateway:
    type: DELEGATED
    tags:
      kuma.io/service: kong
  outbound:
    - port: 33033
      tags: 
        kuma.io/service: monolith-service_svc_5000
    - port: 33034
      tags: 
        kuma.io/service: microservice_microservice_svc_8080
```

There are a number of interesting attributes in the manifest:

* **mesh** - the mesh that the dataplane should join.

* **gateway** - defines the type of data-plane as `gateway`, and type `delegated`, which means we are using an external gateway i.e. not using the Kong Mesh [Kubernetes Gateway API](https://docs.konghq.com/mesh/latest/explore/gateway-api/).

* **outbound** - this defines how the gateway can reach services on the mesh.  Please note the tags here, as they are very important. This manifest specifically states, all traffic going out port `33033` will go to the service labeled `monolith-service_svc_5000`. This section is required when universal mode data-planes are not run with `transparent-proxy` mode. We will not be exploring the pros/cons of transparent proxying here, but in the next exercise it will impact how the Runtime Instance is reconfigured.  Read up on [transparent proxying](https://docs.konghq.com/mesh/latest/networking/transparent-proxying/) if desired.

`Monolith Dataplane`

From within the demo_facts file `~/.kmj/ansible/demo_facts.json`, copy the SSH command to reach the monolith `ssh_monolith`, and run the command like so:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@54.212.56.119
```

Read the dataplane manifest for the monolith:

```console
cat /home/kuma/dataplane-nontransparent.yaml
```

The output will look similar to:

```yaml
type: Dataplane
mesh: default
name: monolith
networking: 
  address: 10.0.0.55
  inbound:
    - port: 5000
      servicePort: 8080
      tags: 
        kuma.io/service: monolith-service_svc_5000
```

This is the `Standard` Dataplane, used for all services except gateways. The key takeaways from this manifest are:

* **mesh** - the mesh that the data-plane should join is still configurable.
* **inbound** - describes how to reach this proxy and the tags that are associated to it:
      * **port** - The port the mesh data-plane will listen on for incoming requests.
      * **servicePort** - the port the application is running on, and how the data-plane will proxy requests to the monolith.
      * **tags** - how the monolith will be referenced by other applications within the mesh network.

**Summary**

We just took a deep dive on the infrastructure of Kong Mesh running in a multi-zone configuration with a Univeral Mode Zone to manage an On Premise Environment.

Let's recap what just happened:

1. `Global Control Plane` - The global control plane is running in `Universal Mode`, in contrast it could have run on a Kubernetes cluster.

2. `Zone Control Plane` - There is 1 per zone, and in this case the `on-prem` zone. It is running in Universal Mode, and must be connected to the global control plane.

3. `Zone Ingress and Egress` - There is one of each present in the `on-prem` zone.

4. `Dataplanes` - There are 2 types:

    * `Gateway`: for the runtime instance so there is North/South traffic into the mesh.
    * `Standard`: for the monolith so it can be a part of a mesh.

## Activities - Enable the Mesh with mTLS and Re-Configure Konnect

### Enable mTLS on the Mesh

**It is important to understand that for cross zone communication to be successful, mTLS needs to be enabled, as well as for permitting zone egress traffic.**

For all resources creations/updates/deletions are executed on the global control plane.  From within the demo_facts file `~/.kmj/ansible/demo_facts.json`, copy the command to SSH into the global control plane `ssh_global_cp` and run the command like so:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@35.85.31.178
```

Update the `Mesh` manifest:

```console
sudo kumactl apply -f /home/kuma/mesh-policies/phase2/mesh-default.yaml
```

From the global control plane console you will now see that mTLS is enabled, and using the built-in CA.

### Re-Configure Konnect

Next, we are ready to configure Konnect.

Login into Konnect and navigate back to the list of gateway services:

1. From the Runtime Manager menu, select the `Runtime Group` where you deployed the runtime instance &#8594; in the left hand panel navigate to `Gateway Services`

2. `Create Gateway Service` - Select the `+ New gateway service` button in the menu.

3. `Add a new gateway service` - To configure the Gateway Service.

    * Select the `Add using Protocol, Host and Path` radio button.
    
    * Fill in the following information regarding how to reach the backend Monolith Application:
        * **Gateway Service Name** = `Mesh`
        * **Protocol** = `http`
        * **Host** = `127.0.0.1`
        >**NOTE:** *`localhost` is defined because we are not using transparent proxy mode on the mesh*
        * **Path** = `/monolith/resources/`
        >**NOTE:** *the base url of the Monolith Web Service*
        * **Port** = `33033`
        >**NOTE:** *this is the outbound port listed on the Gateway data-plane manifest*

    * Save the Gateway Service

<p align="center">
    <img src="../img/phase_2/5_gatewayservice.png"/></div>
</p>

5. `Create Route` for the new Gateway Service - Navigate into the newly create Gateway Service `Mesh` &#8594; scroll down &#8594; Add Route:

    * Fill in the following information regarding how to expose the Monolith through the Runtime Instance:
        * **Route Name** = `Mesh`
        * **Protocols** = `http`
        * **Method(s)** = `GET`
        * **Path(s)** = `/mesh`

    * Save the Route

An example Route is shown below.

<p align="center">
    <img src="../img/phase_2/6_route.png"/></div>
</p>

With that, we are now ready to validate the setup.

### Validation

Just to clarify what to expect - `From the perspective of the API Consumer nothing should have changed.`

Onboarding and exposing the monolith through the mesh network should have no affect to the consumer. An API Consumer will call the same Runtime Instance as phase 1 and expect the same responses.

1. Open Insomnia &#8594; Navigate into the `Migration Journey` Collection &#8594; Open `Phase 2 and 3 - Mesh` subfolder.

2. For each request hit `Send`, you will be prompted for the Runtime Instance IP (this can be obtained from the `~/.kmj/ansible/demo_facts.json` file, and will be the IP address associated with the `ssh_runtime_instance` command).

You will see nothing has changed from the client's perspective. Which is the expectation!

## Closing and Recap

**This is the end of Phase 2**

Just to Recap.

The `objective of phase 2` was to create an `on-prem` mesh zone, onboard the monolith and runtime instance to the mesh, and reconfigure Konnect so traffic destined to the monolith flows over the Mesh.

We reviewed:

* The installation of Kong Mesh in `Universal Mode` for the Global Control Plane, Zone Control Plane, Zone Ingresses, Zone Egresses, and Data-planes.

* The difference between `Gateway` and `Standard` Data-planes.

* Re-configured Konnect to have traffic flow through the mesh.

* Validated we can still successfully call the monolith.  We observed no changes to the existing `disputes` feature of the monolith, as expected.

Because we are not using transparent proxy, the gateway was setup to reach the upstream monolith on `127.0.0.1:33033`, which is the `outbound` defined in the Data-plane manifest of the gateway.

In phase 3, the cloud zone will be configured in the mesh, and with the mesh networking capabilities, we will be able to deprecate only the disputes feature of the monolith and send that traffic to a new micro-service running in Amazon EKS.

Let's proceed with [Tutorial: Step 7 - Run Migration Journey Phase 3](../../README.md#step-7---run-migration-journey-phase-3).