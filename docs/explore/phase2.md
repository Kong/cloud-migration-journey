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

SSH into the global control plane:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@35.85.31.178
```

Change to root user for ease of use: `sudo su`

Now we will navigate the VM and investigate the setup of the global control process (kuma-cp).

**Kuma CP System Process**

The kumap-cp binary is running as a SystemD process on the vm.

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

From the SystemD output we can see that a /home/kuma directory was created to house, the binaries, license and any needed configuration.

**Global Control Plane GUI**

The GUI is available on: `http://<Global CP IP>:5681/gui`.

Today the GUI behaves in READ-ONLY mode. In the overview panel you can get the general state of the Mesh Infrastructure: Number of Zones, Dataplanes, Deployment Strategies, License Limitations.

<p align="center">
    <img src="../img/phase_2/2_global_cp_overview.png"/></div>
</p>

**Zone Control Plane**

