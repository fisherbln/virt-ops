This repo has good info:
https://github.com/JJGadgets/Biohazard/tree/main/kube/3-deploy/1-core/01-networking/cilium/bootstrap-install


Generate Cilium install YAML that is Flux HelmRelease compatible: 

```bash
kustomize build --enable-helm > ./install.yaml
```

install:
```bash
kubectl apply -f -
```