kong_mesh_version: 1.8.1
global_cp:
%{ for node in aws_nodes ~}
%{if node.tags["Name"] == "kuma-global-cp" }addr:${node.public_ip}%{ endif ~}
%{ endfor ~}

zones:
  - name: "on_prem"
    type: "universal"
    host: <runtime-instance public_ip>
    zone_addr: <runtime-instance private ip>
    ingress:
      host: <runtime instance public ip>
      install: true
      dp_addr: <runtime instance private ip>
      dp_advertised_ip: <runtime instance public ip>
    egress: 
      install: true
      host: <runtime instance public ip>
      dp_addr: <runtime instance private ip>

dataplanes:
  - name: "gateway"
    dp_type: "gateway"
    zone_type: "universal"
    zone_addr: <runtime-instance private ip>
    dp_manifest:
      outbound:
        tags: 
          kuma_service: monolith-service_default_svc_5000
  - name: "monolith"
    dp_type: "standard"
    zone_type: "universal"
    zone_addr: <runtime-instance private ip>
    dp_manifest:
      inbound:
        port: 5000
        svc_port: 8080
        tags:
          kuma_service: monolith-service_default_svc_5000