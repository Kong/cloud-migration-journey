# Kong Migration Journey: Phase 2

The `make kong.phase2` created:

* Kong Mesh `Global Control Plane`
* Kong Mesh `On-Prem Zone` using the Universal Mode deployment strategy
* Deployed `Dataplanes` to the monolith and Konnect Runtime Instance

## Objective

The purpose of Phase 2 is to begin exploring Kong Mesh and reconfigure Konnect so that traffic from the runtime instance to the monolith flows over the mesh network.

The high level `activities` that will take place are:

* Review Kong Mesh Global Control Plane and Zone setup.

* Review the Dataplane (Sidecar Proxy) deployed beside the monolith and runtime instance.

* Reconfigure Konnect for traffic between monolith and the runtime instance to move over the mesh network.

## Architecture

<p align="center">
    <img src="../img/phase_2/1_reference_arch.png" width="800" /></div>
</p>

**Global Control Plane**

The Kong Mesh `Global Control Plane` in is deployed into an EC2 in `mulit-zone mode`, but it could equally have been setup in a Kubernetes cluster. The Global Control Plane is responsible for:

* creating/changing/deleting any mesh policies
* sending configuration changes to zone control planes

**Zone Services**

There several type of zone services: `Zone Control Plane`, `Zone Ingress` and `Zone Egress`.

`Zone Control Plane` has 2 major functions:

1. `Interact with the Global Control Plane` - Register itself to the global. The global control plane will propogate all polices to the zone control plane, and vice versa send data back to the global control plane.

2. `Interact with Dataplanes` - Within a zone, dataplanes will join or be rejected by the zone control plane, and the zone control plane will translate policies from the global to each dataplane proxy.

`Zone Ingress and Egresses` have the responsiblity of proxying traffic between dataplane proxies existing in other zones. Ingress goes into local dataplane proxy of that zone. and Egress goes out its local zone to another zone or support reaching external services.

**Dataplane Proxies**

Any application that intended to be a part of the mesh requires a dataplane proxy (sidecar).

In this case, the `monolith` and `runtime instance` were each provisioned dataplanes. The dataplanes register with the zone control plane, and will communicate with dataplanes running in the local zone as well as communicate with zones ingress/egresses to send traffic across zones.

**Universal Mode**

All these services were deployed as processes onto VMs, `global control plane`, `zone cp`, `zone ingress`, `zone egress`, `dataplane`, which is referred to as Universal Mode in the Kuma Documentation.

## Explore Infrastructure

### Global Control Plane

**Global Control Plane GUI**

Go into the demo_facts `~/.kmj/ansible/demo_facts.json`, copy the `global_cp_url` and open it up in the browser.

Today the GUI behaves in `READ-ONLY` mode.

The UI is really informative. It provides the general state of the Mesh Infrastructure: number of zones, dataplanes, deployment strategies. From there you can dive into any resource configuration or services recognized as part of the mesh such as the health of zone cp, ingresses, and dataplanes.

`In Summary`

You should be able to see:

1. The global control plane is running in `Multi-Zone Mode`.

2. We created an `On-Prem` zone.

3. We have a zone ingress and zone egress deployed in the "On-Prem" zone.

4. We have `2 Dataplanes` deployed in the "On-Prem" zone.

**Global Control Plane VM**

Each kong mesh processes is running as systemD processes. We will validate this in this section.

Go into the demo_facts `~/.kmj/ansible/demo_facts.json`, and copy the ssh command to reach the global control plane VM:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@35.85.31.178
```

```console
sudo systemctl status kuma-cp
```

output:

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

Now we will dive into the setup of the zones services.

Go into the demo_facts `~/.kmj/ansible/demo_facts.json`, and copy the ssh command to reach the runtime instance VM:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@18.237.252.125
```

`Kuma-Zone-CP`

Again, the zone is the same binary as the global, as shown below:

```console
sudo systemctl status kuma-zone-cp
```

output:

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

But to setup the zone requires a couple of extra attributes, `KUMA_MODE`, `ZONE_NAME`, `GLOBAL_ADDRESS`: these ENVs are articulated in the systemd file:

```console
cat /etc/systemd/system/kuma-zone-cp.service
```

output:
```console
ExecStart = /bin/bash -c 'KUMA_MODE=zone \
  KUMA_MULTIZONE_ZONE_NAME=on_prem \
  KUMA_MULTIZONE_ZONE_GLOBAL_ADDRESS=grpcs://35.85.31.178:5685 \
 /home/kuma/mesh/kong-mesh-1.8.1/bin/kuma-cp --log-output-path=/tmp/kuma-cp.log run --license-path=/home/kuma/license.json'
```

`Zone Ingress`

Zone ingresses and egresses are actually dataplanes and require data manifest that describes how the ingress can be reached.

```console
sudo cat /home/kuma/dataplane-ingress.yaml
```

The output will look similar to below:

```yaml
type: ZoneIngress
name: universal-zone-ingress-on_prem
networking:
  address: 10.0.0.36  #address that is routable within the zone
  port: 10001 
  advertisedAddress: 10.0.0.36 #relevant if zone ingress resides behind a load balancer
  advertisedPort: 10001 #relevant if zone ingress resides behind a load balancer
  admin:
    port: 30002 
```

Looking at the `kuma-ingress` service we can confirm that the process is `kuma-dp` used for dataplanes, and the ingress manifest is referenced.

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

**On Prem Dataplanes**

Last, let's explore the runtime instance and monolith dataplanes.

`Runtime Instance Dataplane`

Go into the demo_facts `~/.kmj/ansible/demo_facts.json`, and copy the ssh command to reach the runtime instance VM:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@18.237.252.125
```

Take a look at the `Dataplane Manifest` for the runtime instance:

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

* **gateway** - defines the type of dataplane as `gateway`, and type `delegated` means we are using an external gateway i.e. not the built-in one the mesh can deploy.

* **outbound** - this defines how the gateway can reach services on the mesh, and the tags are very important. This manifest specifically states, all traffic going out port 33033 will go to the service labeled monolith-service_svc_5000. This section is required when universal mode dataplanes are not run with `transparent-proxy`. We will not be diving into the pros/cons of transparent proxy here but in the next exercise it will impact how the Runtime Instance is reconfigured.

Then the systemD service looks identical to the ingress/egress services.

`Monolith Dataplane`

Go into the demo_facts `~/.kmj/ansible/demo_facts.json`, and copy the ssh command to reach the monolith VM:

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

* **mesh** - the mesh that the dp should join is still configurable.

* **inbound** - describes how to reach this proxy and the tags are associated to it:
      * **port** - The port the DP will listen on for incoming requests.
      * **servicePort** - the port the application is running on, and how the dataplane will proxy requests to the monolith.
      * **tags** - how the monolith will be referenced by other applications in the mesh.

**Summary**

We just took a deep dive on the infrastructure of Kong Mesh running in Multi-zone with a Univeral Mode Zone to manage an On Premise Environment.

Let's recap what just happened:

1. `Global Control Plane` - The global control plane is running in `Universal Mode`, in contrast it could have run in Kubernetes.

2. `Zone Control Plane` - There is 1 on-prem zone. It is running in Univeral Mode, and connected to the global control plane.

3. `Zone Ingress and Egress` - There is one of each present in the on-prem zone.

4. `Dataplanes` - There are 2 types:

    * `Gateway`: for the runtime instance so there is North/South traffic into the mesh.
    * `Standard`: for the monolith so it can be a part of a mesh.

## Activities - Enable the Mesh with mTLS and Re-Configure Konnect

### Enable mLTS on the Mesh

**It is important to understand that for cross zone communication to be successful, mTLS needs to be enabled, along with permitting zone egress traffic.**

For all resources creations/updates/deletions are executed on the global control plane, so go into the demo_facts `~/.kmj/ansible/demo_facts.json`, and copy the command to ssh into the global control plane:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@35.85.31.178
```

Update the `Mesh` manifest:

```console
sudo kumactl apply -f /home/kuma/mesh-policies/phase2/mesh-default.yaml
```

From the global control plane console you should see that mtls is enabled, and using the built-in CA.

### Re-Configure Konnect

Next, we are ready to configure Konnect.

Login into Konnect and navigate back to the list of gateway services:

1. From the Runtime Manager menu, select the `Runtime Group` where you deployed the runtime instance &#8594; in the left hand panel navigate to `Gateway Services`

2. `Create Gateway Service` - Select the `+ New gateway service` button in the menu.

3. `Add a new gateway service` - To configure the Gateway Service.

    * Select the `Add using Protocol,Host and Path` radio button.
    
    * Fill in the following information regarding how to reach the backend Monolith Application:
        * **Gateway Service Name** = Mesh
        * **Protocol** = http
        * **Host** = 127.0.0.1 _note: (localhost is defined because the we are not using transparent proxy on the mesh)_
        * **Path** = /monolith/resources/ , _note: (the base url of the Monolith Web Service)_
        * **Port** = 33033, _note: (this is the outbout port listed on the Gateway Dataplane Manifest)_

    * Save the Gateway Service

<p align="center">
    <img src="../img/phase_2/5_gatewayservice.png"/></div>
</p>

5. `Create Route` for the new Gateway Service - Navigate into newly create Gateway Service `Mesh` &#8594; scroll down &#8594; Add Route:

    * Fill in the following information regarding how to expose the Monolith through the Runtime Instance:
        * **Route Name** = Mesh
        * **Protocols** = http
        * **Method(s)** = GET
        * **Path(s)** = /mesh

    * Save the Route

An example Route is shown below.

<p align="center">
    <img src="../img/phase_2/6_route.png"/></div>
</p>

With that we are ready to validate the setup.

### Validation

Just to clarify what to expect - `From the perspective of the API Consumer nothing should have changed.`

Onboarding and exposing the monolith through the mesh network should have no affect to the consumer. An API Consumer will call the same Runtime Instance as phase 1 and expect the same responses.

1. Open Insomnia &#8594; Navigate into the `Migration Journey` Collection &#8594; Open `Phase 2 and 3 - Mesh` subfolder.

2. For each request hit `Send`, you will be prompted for the Runtime Instance IP (you can get this from the demo_facts.json file).

You will see nothing has changed from the client's perspective. Which is the expectation!

## Closing and Recap

**This is the end of Phase 2**

Just to Recap.

The `objective of phase 2` was create an on-prem mesh zone, onboard the monolith and runtime instance to the mesh, and reconfigure the Konnect so traffic flows over the Mesh.

We reviewed through:

* The installation of Kong Mesh in `Universal Mode` for the Global Control Plane, Zone Control Plane, Zone Ingresses, Zone Egresses, and Dataplanes.

* The difference between `Gateway` and `Standard` Dataplanes.

* Re-configured Konnect to have traffic flow through the mesh.

* Validate we can still successfull call the monolith, no changes, and still no microservice.

Because we are not using transparent proxy, the gateway was setup to reach the upstream monolith on `127.0.0.1:33033`, which is the `outbound` defined in the Dataplane manifest of the gateway.

In phase 3, the cloud zone will be integrated, and with the mesh networking capabilities deprecate only the disputes functionality of the monolith and send that traffic to the microservice running in Amazon EKS.

Please Navigate to the Home Page to proceed with [Deploy Phase 3 of the Migration](../../README.md#step-7---execute-the-cloud-migration-journey-phase-3).