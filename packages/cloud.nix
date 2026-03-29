# Cloud, containers, and infrastructure tools.
{ pkgs }:

with pkgs; [
  # Kubernetes
  kubectl
  kubectx
  k9s               # terminal UI for K8s
  stern
  kustomize
  kubernetes-helm
  cdk8s-cli

  # GitOps
  argocd            # ArgoCD CLI

  # Cilium / networking
  cilium-cli        # Cilium status, connectivity tests
  hubble            # Cilium network observability

  # Infra
  talosctl          # Talos node management
  omnictl           # Sidero Omni

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
  kubeseal          # SealedSecrets
  sops              # encrypted secrets in git
  age
  gnupg

  # Containers / registries
  dive              # Docker image layer inspection
  trivy             # container vulnerability scanning
  harbor-cli        # Harbor container registry CLI

  # Storage
  minio-client      # S3-compatible object storage CLI (mc)

  # Caches / registries
  attic-client      # Nix binary cache client
  devpi-client      # PyPI index client

  # Auth
  keycloak          # includes kcadm.sh CLI
  kanidm_1_8        # identity management CLI (ships zsh completions)
  zitadel           # identity management
  zitadel-tools     # helper tools for zitadel
]
