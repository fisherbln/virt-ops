Starting to research basic structure of new homelab git-ops setup

Operating on Proxmox, would like to build all base infrastructure as code.

Existing repos that do this on proxmox:
https://github.com/angelnu/k8s-gitops


<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My home operations repository :octocat:

_... managed with Flux, Renovate and GitHub Actions_ 🤖

</div>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/k8s-at-home)&nbsp;&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/badge/v1.26-blue?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k3s.io/)&nbsp;&nbsp;&nbsp;
[![Renovate](https://img.shields.io/github/actions/workflow/status/onedr0p/home-ops/renovate.yaml?branch=main&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/onedr0p/home-ops/actions/workflows/renovate.yaml)

[![Home-Internet](https://img.shields.io/uptimerobot/status/m793494864-dfc695db066960233ac70f45?color=brightgreeen&label=Home%20Internet&style=for-the-badge&logo=v&logoColor=white)](https://status.devbu.io)&nbsp;&nbsp;&nbsp;
[![Status-Page](https://img.shields.io/uptimerobot/status/m793599155-ba1b18e51c9f8653acd0f5c1?color=brightgreeen&label=Status%20Page&style=for-the-badge&logo=statuspage&logoColor=white)](https://status.devbu.io)&nbsp;&nbsp;&nbsp;
[![Alertmanager](https://img.shields.io/uptimerobot/status/m793494864-dfc695db066960233ac70f45?color=brightgreeen&label=Alertmanager&style=for-the-badge&logo=prometheus&logoColor=white)](https://status.devbu.io)

</div>

---

## 📖 Overview

This is a mono repository for my home infrastructure and Kubernetes cluster. I try to adhere to Infrastructure as Code (IaC) and GitOps practices using the tools like [Ansible](https://www.ansible.com/), [Terraform](https://www.terraform.io/), [Kubernetes](https://kubernetes.io/), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions).

---

## ⛵ Kubernetes

There is a template over at [onedr0p/flux-cluster-template](https://github.com/onedr0p/flux-cluster-template) if you wanted to try and follow along with some of the practices I use here.

### Installation

My cluster is [k3s](https://k3s.io/) provisioned overtop bare-metal Ubuntu Server using the [Ansible](https://www.ansible.com/) galaxy role [ansible-role-k3s](https://github.com/PyratLabs/ansible-role-k3s). This is a semi hyper-converged cluster, workloads and block storage are sharing the same available resources on my nodes while I have a separate server for (NFS) file storage.

🔸 _[Click here](./infrastructure/kubernetes/servers/) to see my Ansible playbooks and roles._

### Core Components

- [actions-runner-controller](https://github.com/actions/actions-runner-controller): Self-hosted Github runners.
- [calico](https://github.com/projectcalico/calico): Internal Kubernetes networking plugin.
- [cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in a cloud DNS provider.
- [external-secrets](https://github.com/external-secrets/external-secrets/): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx/): Ingress controller to expose HTTP traffic to pods over DNS.
- [rook](https://github.com/rook/rook): Distributed block storage for peristent storage.
- [sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): Managed secrets for Kubernetes, Ansible and Terraform which are commited to Git.
- [tf-controller](https://github.com/weaveworks/tf-controller): Additional Flux component used to run Terraform from within a Kubernetes cluster.
- [volsync](https://github.com/backube/volsync) and [snapscheduler](https://github.com/backube/snapscheduler): Backup and recovery of persistent volume claims.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [kubernetes](./kubernetes/) folder (see Directories below) and makes the changes to my cluster based on the YAML manifests.

The way Flux works for me here is it will recursively search the [kubernetes/apps](./kubernetes/apps) folder until it finds the most top level `kustomization.yaml` per directory and then apply all the resources listed in it. That aforementioned `kustomization.yaml` will generally only have a namespace resource and one or many Flux kustomizations. Those Flux kustomizations will generally have a `HelmRelease` or other resources related to the application underneath it which will be applied.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created. When some PRs are merged [Flux](https://github.com/fluxcd/flux2) applies the changes to my cluster.

### Directories

This Git repository contains the following directories under [kubernetes](./kubernetes/).

```sh
📁 kubernetes      # Kubernetes cluster defined as code
├─📁 bootstrap     # Flux installation
├─📁 flux          # Main Flux configuration of repository
└─📁 apps          # Apps deployed into my cluster grouped by namespace (see below)
```

### Cluster layout

Below is a a high level look at the layout of how my directory structure with Flux works. In this brief example you are able to see that `authelia` will not be able to run until `lldap` and  `cloudnative-pg` are running. It also shows that the `Cluster` custom resource depends on the `cloudnative-pg` Helm chart. This is needed because `cloudnative-pg` installs the `Cluster` custom resource definition in the Helm chart.

```python
# Key: <kind> :: <metadata.name>
GitRepository :: home-ops-kubernetes
    Kustomization :: cluster
        Kustomization :: cluster-apps
            Kustomization :: cluster-apps-cloudnative-pg
                HelmRelease :: cloudnative-pg
            Kustomization :: cluster-apps-cloudnative-pg-cluster
                DependsOn:
                    Kustomization :: cluster-apps-cloudnative-pg
                Cluster :: postgres
            Kustomization :: cluster-apps-lldap
                HelmRelease :: lldap
                DependsOn:
                    Kustomization :: cluster-apps-cloudnative-pg-cluster
            Kustomization :: cluster-apps-authelia
                DependsOn:
                    Kustomization :: cluster-apps-lldap
                    Kustomization :: cluster-apps-cloudnative-pg-cluster
                HelmRelease :: authelia
```

### Networking

<details>
  <summary>Click to see a high level network diagram</summary>

  <img src="https://raw.githubusercontent.com/onedr0p/home-ops/main/docs/src/assets/networks.png" align="center" width="600px" alt="dns"/>
</details>


| Name                                          | CIDR              |
|-----------------------------------------------|-------------------|
| Management VLAN                               | `10.28.10.0/24`  |
| Kubernetes Nodes VLAN                         | `10.28.28.0/24` |
| Kubernetes external services (Cilium w/ BGP)  | `10.45.0.0/24` |
| Kubernetes pods (Cilium w/ BGP)               | `172.17.0.0/16`    |
| Kubernetes services (Cilium w/ BGP)           | `172.18.0.0/16`    |

- HAProxy is configured on my `VyOS` router for the Kubernetes Control Plane Load Balancer.
- Cilium is configured with `externalIPs` to expose Kubernetes services with their own IP over BGP which is configured on my router.

---

## ☁️ Cloud Dependencies

While most of my infrastructure and workloads are selfhosted I do rely upon the cloud for certain key parts of my setup. This saves me from having to worry about two things. (1) Dealing with chicken/egg scenarios and (2) services I critically need whether my cluster is online or not.

The alternative solution to these two problems would be to host a Kubernetes cluster in the cloud and deploy applications like [HCVault](https://www.vaultproject.io/), [Vaultwarden](https://github.com/dani-garcia/vaultwarden), [ntfy](https://ntfy.sh/), and [Gatus](https://gatus.io/). However, maintaining another cluster and monitoring another group of workloads is a lot more time and effort than I am willing to put in.

| Service                                         | Use                                                               | Cost           |
|-------------------------------------------------|-------------------------------------------------------------------|----------------|
| [Doppler]([https://1password.com/](https://www.doppler.com/))             | Secrets with [External Secrets](https://external-secrets.io/)     | Free        |
| [Cloudflare](https://www.cloudflare.com/)       | Domain and R2                                                     | ~$30/yr        |
| [Migadu](https://migadu.com/)                   | Email hosting                                                     | ~$20/yr        |
| [GCP](https://cloud.google.com/)                | Voice interactions with Home Assistant over Google Assistant      | Free           |
| [GitHub](https://github.com/)                   | Hosting this repository and continuous integration/deployments    | Free           |
| [Newsgroup Ninja](https://www.newsgroup.ninja/) | Usenet access                                                     | ~$70/yr        |
| [NextDNS](https://nextdns.io/)                  | My routers DNS server which includes AdBlocking                   | ~$20/yr        |
| [Pushover](https://pushover.net/)               | Kubernetes Alerts and application notifications                   | Free           |
| [Terraform Cloud](https://www.terraform.io/)    | Storing Terraform state                                           | Free           |

---

## 🌐 DNS

### Internal DNS

[Bind9](https://github.com/isc-projects/bind9) and [dnsdist](https://dnsdist.org/) are deployed on Vyos as containers. In my cluster [external-dns](https://github.com/kubernetes-sigs/external-dns) is deployed with the RFC2136 provider that populates Bind9 with all my ingresses DNS records.

dnsdist has some downstream DNS servers configured such as Bind9 (above) and [NextDNS](https://nextdns.io/) profiles. All my clients use dnsdist as the upstream DNS server, this allows for more granularity with configuring DNS across my networks. These could be things like giving each of my VLANs a specific NextDNS profile, or having all requests for my domain forward to Bind9 on certain networks, or only using 1.1.1.1 instead of NextDNS on certain networks where adblocking isn't needed.

### External DNS

Another `external-dns` instance is deployed in my cluster and configure to sync DNS records to [Cloudflare](https://www.cloudflare.com/). The only ingresses this `external-dns` instance looks at to gather DNS records to put in `Cloudflare` are ones that have an annotation of `external-dns.alpha.kubernetes.io/target`.

---

## 🔧 Hardware

<details>
  <summary>Click to see da rack!</summary>

  <img src="https://user-images.githubusercontent.com/213795/172947261-65a82dcd-3274-45bd-aabf-140d60a04aa9.png" align="center" width="200px" alt="rack"/>
</details>

| Device                      | Count | OS Disk Size | Data Disk Size              | Ram  | Operating System | Purpose             |
|-----------------------------|-------|--------------|-----------------------------|------|------------------|---------------------|
| Intel NUC8i5BEH             | 3     | 1TB SSD      | 1TB NVMe (rook-ceph)        | 64GB | Debian           | Kubernetes Masters  |
| Intel NUC8i7BEH             | 3     | 1TB SSD      | 1TB NVMe (rook-ceph)        | 64GB | Debian           | Kubernetes Workers  |
| PowerEdge T340              | 1     | 2TB SSD      | 8x12TB ZFS (mirrored vdevs) | 64GB | Ubuntu           | NFS + Backup Server |
| Lenovo SA120                | 1     | -            | 6x12TB (+2 hot spares)      | -    | -                | DAS                 |
| Raspberry Pi 4              | 1     | 32GB (SD)    | -                           | 4GB  | PiKVM (Arch)     | Network KVM         |
| TESmart 8 Port KVM Switch   | 1     | -            | -                           | -    | -                | Network KVM (PiKVM) |
| HP EliteDesk 800 G3 SFF     | 1     | 256GB NVMe   | -                           | 8GB  | Vyos (Debian)    | Router              |
| Unifi US-16-XG              | 1     | -            | -                           | -    | -                | 10Gb Core Switch    |
| Unifi USW-Enterprise-24-PoE | 1     | -            | -                           | -    | -                | 2.5Gb PoE Switch    |
| APC SMT1500RM2U w/ NIC      | 1     | -            | -                           | -    | -                | UPS                 |
| Unifi USP PDU Pro           | 1     | -            | -                           | -    | -                | PDU                 |

---

## ⭐ Stargazers

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=onedr0p/home-ops&type=Date)](https://star-history.com/#onedr0p/home-ops&Date)

</div>

---

## 🤝 Gratitude and Thanks

Thanks to all the people who donate their time to the [Kubernetes @Home](https://discord.gg/k8s-at-home) Discord community. A lot of inspiration for my cluster comes from the people that have shared their clusters using the [k8s-at-home](https://github.com/topics/k8s-at-home) GitHub topic. Be sure to check out the [Kubernetes @Home search](https://nanne.dev/k8s-at-home-search/) for ideas on how to deploy applications or get ideas on what you can deploy.

---

## 📜 Changelog

See my _awful_ [commit history](https://github.com/onedr0p/home-ops/commits/main)

---

## 🔏 License

See [LICENSE](./LICENSE)
