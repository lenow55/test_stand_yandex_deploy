apiserver_loadbalancer_domain_name: "lb-apiserver.kubernetes.local"
loadbalancer_apiserver:
  address: "${lb_ip}"
  port: ${lb_port}
