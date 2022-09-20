all:
  children:
    gateway:
      hosts:
%{ for node in aws_nodes ~}
%{if node.tags["Name"] == "runtime-instance" }
        ${node.public_ip}:
          service_name: "gateway"
%{ endif }
%{ endfor ~}
    monolith:
      hosts:
%{ for node in aws_nodes ~}
%{if node.tags["Name"] == "monolith" }
        ${node.public_ip}:
          service_name: "monolith"
          monolith_image_tag: "djfreese/monolith:latest"
%{ endif }
%{ endfor ~}
    kuma-global-cp:
      hosts:
%{ for node in aws_nodes ~}
%{if node.tags["Name"] == "kuma-global-cp" }
        ${node.public_ip}:
%{ endif }
%{ endfor ~}
    kuma-zone-cp:
      hosts:
%{ for node in aws_nodes ~}
%{if node.tags["Name"] == "runtime-instance"}
        ${node.public_ip}:
%{ endif }
%{ endfor ~}
    kuma-zone-ingress:
      hosts:
%{ for node in aws_nodes ~}
%{if node.tags["Name"] == "runtime-instance" }
        ${node.public_ip}:
%{ endif }
%{ endfor ~}
    kuma-zone-egress:
      hosts:
%{ for node in aws_nodes ~}
%{if node.tags["Name"] == "runtime-instance" }
        ${node.public_ip}:
%{ endif }
%{ endfor ~}