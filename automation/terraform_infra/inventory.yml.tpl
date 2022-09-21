all:
  children:
    gateway:
      hosts:
        ${gateway_node.public_ip}:
          service_name: "gateway"
    monolith:
      hosts:
        ${monolith_node.public_ip}:
          service_name: "monolith"
          monolith_image_tag: "djfreese/monolith:latest"
    kuma-global-cp:
      hosts:
        ${global_cp_node.public_ip}
    kuma-zone-cp:
      hosts:
        ${zone_node.public_ip}
    kuma-zone-ingress:
      hosts:
        ${zone_node.public_ip}
    kuma-zone-egress:
      hosts:
        ${zone_node.public_ip}