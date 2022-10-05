# Kong Migration Journey: Phase 2

The `make kong.phase2` step built out the `Kong Mesh Global Control Plane`, created a Kong Mesh `On-Premise Zone` using the Universal Mode deployment strategy, and deployed Dataplanes (also referred to as SidecarProxies) to the Monolith and Runtime Instance.

## Objective

The `objective` of Phase 2 is to being the journey with Kong Mesh by exploring the infrastructure and reconfigure Konnect so that traffic from the Runtime Instance to the Monolith flows over the mesh network.

The high level `activities` that will take place in this phase are:

* Review Kong Mesh Global Control Plane and Zone Setup.

* Review the Dataplane (Sidecar Proxy) deployed beside the Monolith and Runtime Instance.

* Reconfigure Konnect for traffic between Monolith and the Runtime Instance to move over the mesh network.

At the end of phase 2 you should be `comfortable` with the following:

* Grasp fundamentals of Universal Mode Deployments.

* How to reconfigure Konnect so traffic flows over the mesh network.

## Architecture

<p align="center">
    <img src="../img/phase_2/1_reference_arch.png" width="800" /></div>
</p>

Lets review through the infrastructure.

**Global Control Plane**

First Kong Mesh `Global Control Plane` was deployed into an ec2-instance, but it could equally run in a Kubernetes cluster. The Global Control Plane will be responsible for:

* accepting traffic from zones
* creating/changing/deleting any mesh policies
* sending data to zone control planes
* keeping an eye on all dataplanes running

**Zone Services**

Once, the global control plane is ready, we can deploy the Kong Mesh `Zone Control Plane`, `Zone Ingress` and `Zone Egress`.

`Zone Control Plane` has 2 major functions:

1. `Interact with the Global Control Plane` - Register itself to the global. The global control plane will propogate all polices to the zone control plane, and vice versa send data back to the global control plane.

2. `Interact with Dataplanes` - Within a zone, dataplanes will join or be rejected by the zone control plane, and the zone control plane will translate policies from the global to each dataplane proxy.

`Zone Ingress and Egresses` have the responsiblity of proxying traffic between dataplane proxies existing in other zones. Ingress goes into local dataplane proxy of that zone. and Egress goes out its local zone to another zone or support reaching external services.

**Dataplane Proxies**

Once the zone is up an running dataplanes can be provisioned.

Any application that intended to be a part of a mesh requires a dataplane proxy (sidecar). In this case, the monolith and Runtime Instance were provisioned dataplanes. The dataplanes register with the zone control plane, and will communicate with dataplanes running in the local zone as well as communicate with zones ingress/egresses to send traffic across zones.

**Universal Mode**
All these services were deployed as processes onto the VMs, `global control plane`, `zone cp`, `zone ingress`, `zone egress`, `dataplane`, which is referred to as Universal Mode in the Kuma Documentation. In the next section, we will explore the configuration of each component more closely.

## Explore

First, open the ansible inventory file

```console
cat ~/.kmj/ansible/inventory.yml
```

Grab the host IPs of the kuma labelled hosts, an example is below:

```yaml
    kuma-global-cp:
      hosts:
        35.85.31.178
    kuma-zone-cp:
      hosts:
        18.237.252.125
    kuma-zone-ingress:
      hosts:
        18.237.252.125
    kuma-zone-egress:
      hosts:
        18.237.252.125
```

### Global Control Plane

**Global Control Plane GUI**

The GUI is available on: `http://<Global CP IP>:5681/gui`.

Today the GUI behaves in `READ-ONLY` mode.

The `Overview` Page is really informative. It provides the the general state of the Mesh Infrastructure: Number of Zones, Dataplanes, Deployment Strategies, License Limitations. From there you can dive into any resource configuration or services recognized as part of the mesh such as the health of Zone CP, Ingresses, and Dataplanes. 

<p align="center">
    <img src="../img/phase_2/2_global_cp_overview.png"/></div>
</p>

`Zone Sevices`

For the zones, from the GUI we can see we have 1 "On-Prem" Zone, and in that Zone we have 1 Zone Ingress and 1 Zone Egress.

<p align="center">
    <img src="../img/phase_2/3_zones.png" width="1000"/></div>
</p>


`Dataplanes`

First - You'll notice from the GUI that Dataplanes are categorized as either `Standard` or `Gateway`. The type Gateway infers that that Mesh will allow the designated service to recieve traffic outside the Mesh, which is exactly what we need for our Runtime Instance.

Second - We can see what Zone the DPP is associated with within the Name of the DPP.

Third - Tags are important. The tags are used to select the mesh behavior: deployment strategy for a new microservice release, load balancing, observability, any mesh functionality is backed by the tags.

<p align="center">
    <img src="../img/phase_2/4_dataplanes.png" width="1000"/></div>
</p>

`In Summary`

The GUI is extremely informative on the state of all resources and services. The take away messages are the following:

1. The Global Control Plane is running in Multi-Zone Mode.

2. We created an "On-Prem" Zone.

3. We have a Zone Ingress and Zone Egress deployed in the "On-Prem" Zone.

4. We have 2 Dataplanes deployed in the "On-Prem" Zone. `Standard` Dataplane is our Monolith, `Gateway` Dataplane is our Runtime Instance.

**Global Control Plane VM**

SSH into the global control plane:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@35.85.31.178
```

Change to root user for ease of use: `sudo su`

Check on how the Global Control Plane Process is running:

```bash
$ systemctl status kuma-cp

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

From the SystemD output we can see that the setup for the Global Control Plane is simple. There is a /home/kuma directory and the control plane is just running as a binary `kuma-cp`.

**Zone Control Plane**

