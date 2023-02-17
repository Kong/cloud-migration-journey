# Kong Migration Journey: Phase 3

The `make kong.phase3` created:

* Kong Mesh `Cloud Zone` using the Kubernetes Mode deployment strategy
* Deployed the disputes microservice and dataplanes for any pods in the namespace

## Objective

The purpose of Phase 3 is to further our understanding of Multi-Zone cross platform features of Kong Mesh and how it can be leveraged to maintain connectivity on-premise and cloud ecosystems.

The high level `activities` that will take place are:

* Review the Cloud Zone Setup of Kong Mesh.

* Apply the mesh traffic policy that will re-direct disputes to the microservice.

## Architecture

In phase 3, the Amazon EKS cluster was integrated as a cloud zone into the mesh, and the diputes microservice was automatically onboarded to the mesh due to the benefits of running in Kubernetes.

<p align="center">
    <img src="../img/phase_3/1_reference_arch.png" width="1400" /></div>
</p>

## Activities - With Mesh, Re-direct Disputes Traffic to Cloud Microservice

Ok! Finally, the last step. Let's actually re-direct the traffic.

SSH into the `Global Control Plane`:

```console
ssh -i ~/.kmj/ec2/ec2.key ubuntu@35.85.31.178
```

Let's apply the first policy:

```console
sudo kumactl apply -f /home/kuma/mesh-policies/phase3/1-kong-reroute.yaml
```

The traffic route will use L7 capabilities to reroute traffic from the monolith to the disputes microservices. Specifically it states:

When traffic from the source `kong` is intended for the service `monolith`, if there is a url prefix match `/monolith/resources/card/dispute` direct that traffic to the `microservice`, anything else should go to the `monolith`.

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

Now that the policy is applied, lets validate with `Insomnia`.

Open the `Migration Journey Collection` &#8594; Open the `Phase 2 and 3 - Mesh` sub-folder &#8594;
Execute the Disputes Request.

We received a `404`, that doesn't seem right, what happened?

This did not work because the new disputes microservice doesn't have a rest endpoint  `/monolith/resources/card/dispute`, it exposes an new endpoint `/disputes`.

<p align="center">
    <img src="../img/phase_3/4_insomnia_1.png" /></div>
</p>

Let's go back to the Global Control Plane and fix this. Apply the updated policy `2-kong-reroute.yaml`

```console
sudo kumactl apply -f /home/kuma/mesh-policies/phase3/2-kong-reroute.yaml
```

When the updated kong-reroute policy now reads - when a request hits the `kong` service, and is intended for the `monolith`, if there is a url prefix match `/monolith/resources/card/dispute`, first modify the path to `/disputes` (because this is rest endpoint of the microservice) and then direct the request to the microservice, everything else should go to the monolith.

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

Now when make the API call from Insomnia, we can see disputes is returning with a 200 status code.

<p align="center">
    <img src="../img/phase_3/5_insomnia_2.png" /></div>
</p>

## Recap of the Migration

Through this tutorialized migration journey we wanted to demonstrate the power that Kong Mesh with its Universal Mode, and multi-zone capabilities can offer.

Throughout the tutorial we stepped through one of the countless ways that Kong can support API Modernization. High level this is what we stepped through:

* **First** - Leveraging Kong Konnect as out gateway in the simulated on-premise environment.

* **Second** - Understanding and deploy Kong Mesh component on premise in Universal Mode with Multi-Zone enabled.

* **Third** - Integrate an EKS Cluster with the Mesh by leveraging the Multi-zone capabilities.

* **Fourth** - Leveraging the traffic management capabilities of Kong Mesh deprecate a monolith service.

Essentially, we what we did was created distributed mesh network that supported the monolith and microservices together, even though they were seperated by both cloud (on premise vs cloud) providers and runtimes (monolith vs kubernetes). What we enjoy about this solution is the simplicity in the cutover. When the cutover to the microservice was executed, it that work was centralized  with the Global Control Plane.

**We hope you have learned and are inspired to go forth with Kong Mesh**

If you would like to tear down the infrastructure, navigate back to the [Clean Up section Home Page](../../README.md#cleanup).
