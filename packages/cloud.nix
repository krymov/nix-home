# Cloud, containers, and infrastructure tools.
{ pkgs }:

with pkgs; [
  # Kubernetes
  kubectl
  kubectx
  stern
  kubernetes-helm
  cdk8s

  # Cloud providers
  awscli2
  google-cloud-sdk
  terraform
  doctl

  # Networking / tunnels
  tailscale
  cloudflared
  ngrok

  # Secrets
  vault
  age
  gnupg
]
