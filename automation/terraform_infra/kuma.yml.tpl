kong_mesh_version: ${kong_mesh_version}
global_cp:
  addr:${global_cp_node.public_ip}

konnect_password: "${konnect_pass}"
konnect_username: "${konnect_user}"
konnect_controlPlane: "${konnect_controlPlane}"

zones:
  - name: "on_prem"
    type: "universal"
    host: ${zone_node.public_ip}
    zone_addr: ${zone_node.private_ip}
    ingress:
      host: ${zone_node.public_ip}
      install: true
      dp_addr: ${zone_node.private_ip}
      dp_advertised_ip: ${zone_node.private_ip}
    egress:
      install: true
      host: ${zone_node.public_ip}
      dp_addr: ${zone_node.private_ip}

dataplanes:
  - name: "gateway"
    dp_type: "gateway"
    zone_type: "universal"
    zone_addr: ${zone_node.private_ip}
    dp_manifest:
      networking:
        addr: ${gateway_node.private_ip}
      outbound:
       - port: 33033
         kuma_service: monolith-service_svc_5000
       - port: 33034
         kuma_service: microservice_microservice_svc_8080
  - name: "monolith"
    dp_type: "standard"
    zone_type: "universal"
    zone_addr: ${zone_node.private_ip}
    dp_manifest:
      networking:
        addr: ${monolith_node.private_ip}
      inbound:
        port: 5000
        svc_port: 8080
        tags:
          kuma_service: monolith-service_svc_5000
      