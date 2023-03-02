# Kong Migration Journey: Phase 3

The `make kong.phase3` created:

* Kong Mesh `Cloud Zone` using the Kubernetes Mode deployment strategy
* Deployed the disputes micro-service and Kong Mesh data-planes for any pods in the namespace

## Objective

The purpose of Phase 3 is to further our understanding of the Multi-Zone cross platform features of Kong Mesh and how it can be leveraged to maintain connectivity between on-premise and cloud ecosystems.

The high level `activities` that will take place are:

* Review the Cloud Zone Setup of Kong Mesh.

* Apply the mesh traffic policy that will re-direct disputes to the micro-service.

## Architecture

In phase 3, the Amazon EKS cluster was integrated as a cloud zone into the mesh network, and the disputes micro-service was automatically onboarded to the mesh due to the benefits of running in Kubernetes.

<p align="center">
    <img src="../img/phase_3/1_reference_arch.png" width="1400" /></div>
</p>

## Activities - Using Kong Mesh, Re-direct Disputes Traffic to the Cloud Micro-service

Finally we've arrived at the last step in our cloud migration journey. Let's actually re-direct the traffic.

From within the demo_facts file `~/.kmj/ansible/demo_facts.json`, copy the SSH command for the Kong Mesh Global Control Plane `ssh_global_cp` and run the command like so:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@35.85.31.178
```

Let's apply the first policy by running:

```console
sudo kumactl apply -f /home/kuma/mesh-policies/phase3/1-kong-reroute.yaml
```

The traffic route will use L7 capabilities to re-route traffic from the monolith to the disputes micro-services. Specifically it states:

When traffic from the source `kong` is intended for the service `monolith`, if there is a URL prefix match `/monolith/resources/card/dispute` direct that traffic to the `microservice`, anything else should go to the `monolith`.

```yaml
type: TrafficRoute
name: kong-reroute
mesh: default
sources:
  - match:
      kuma.io/service: kong
destinations:
  - match:
      kuma.io/service: monolith-service_svc_5000
conf:
  http:
    - match:
        path:
          prefix: "/monolith/resources/card/dispute"
      destination:
        kuma.io/service: microservice_microservice_svc_8080
  destination:
    kuma.io/service: monolith-service_svc_5000
```

Now that the policy is applied, lets validate using `Insomnia`.

Open the `Migration Journey Collection` &#8594; Open the `Phase 2 and 3 - Mesh` sub-folder &#8594;
Execute the Disputes Request.

We received a `404`, that doesn't seem right, what happened?

This did not work because the new disputes micro-service doesn't have a rest endpoint  `/monolith/resources/card/dispute`, it exposes a new API endpoint of `/disputes`.

<p align="center">
    <img src="../img/phase_3/4_insomnia_1.png" /></div>
</p>

Let's go back to our SSH session on the Global Control Plane and fix this. Apply the updated policy `2-kong-reroute.yaml` by running:

```console
sudo kumactl apply -f /home/kuma/mesh-policies/phase3/2-kong-reroute.yaml
```

The updated kong-reroute policy now reads - when a request hits the `kong` service, and is intended for the `monolith`, if there is a url prefix match `/monolith/resources/card/dispute`, first modify the path to `/disputes` (because this is REST endpoint of the new disputes micro-service), and then direct the request to the micro-service running on EKS.  All other requests for the monolith's APIs will otherwise go to the monolith.

```yaml
type: TrafficRoute
name: kong-reroute
mesh: default
sources:
  - match:
      kuma.io/service: kong
destinations:
  - match:
      kuma.io/service: monolith-service_svc_5000
conf:
  http:
    - match:
        path:
          prefix: "/monolith/resources/card/dispute"
      modify:
        path:
          rewritePrefix: /disputes
      destination:
        kuma.io/service: microservice_microservice_svc_8080
  destination:
    kuma.io/service: monolith-service_svc_5000
```

Now when we make the API call from Insomnia, we can see disputes is returning with a `200` status code.

<p align="center">
    <img src="../img/phase_3/5_insomnia_2.png" /></div>
</p>

## Recap of the Migration

Through our cloud migration journey tutorial we demonstrated the power of Kong Mesh with its Universal Mode, and multi-zone capabilities can offer during a migration and modernization effort.

Throughout the tutorial we stepped through one of the countless ways that Kong can support API Modernization:

* **First** - Leveraging Kong Konnect as our gateway in the simulated on-premise environment.
* **Second** - Understanding and deploying the Kong Mesh component on premise in Universal Mode with Multi-Zone enabled.
* **Third** - Integrated an EKS Cluster with the Mesh network by leveraging the Multi-zone capabilities.
* **Fourth** - Leveraging the traffic management capabilities of Kong Mesh to deprecate a service from a monolith.

Essentially, what we did was created a distributed mesh network that supported the monolith and micro-services simultaneously, even though they were separated by both cloud (on premise vs cloud) providers and runtimes (VM-based monolith vs Kubernetes micro-service). What works well with this solution is the simplicity of the cut-over. When the cut-over to the new micro-service was executed, that work was centralized from the Global Control Plane.  Additionally, if something went wrong with the new micro-service, we could simply remove the mesh policy and resume our previous operations with the monolith until the new service is functional and ready for production.

**We hope you have learned and are inspired to go forth with Kong Mesh**

To remove any infrastructure that was created in your AWS account throughout this tutorial, please visit the [Clean Up section of the README](../../README.md#clean-up).
