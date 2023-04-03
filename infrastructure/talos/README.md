# Talos configuration as code

These folders contain the definitions of my Talos clusters. I use the awesome `talhelper` tool written by [@budimanjojo](https://github.com/budimanjojo) (https://github.com/budimanjojo/talhelper) to generate the individual node configurations.


# omitted: create cluster vms

talhelper gensecret > talsecret.sops.yaml
sops -e -i talsecret.sops.yaml

talhelper genconfig

```
export TALOSCONFIG=~/src/home-lab/talos/clusterconfig/talosconfig
if using fish shell: set -x TALOSCONFIG ~/repos/virt-ops/infrastructure/talos/virtops/clusterconfig/talosconfig
talosctl apply-config --insecure --nodes 10.28.28.71 --file clusterconfig/virtops-felix.{NET_DOMAIN}.yaml
talosctl apply-config --insecure --nodes 10.28.28.72 --file clusterconfig/virtops-felix.{NET_DOMAIN}.yaml
talosctl apply-config --insecure --nodes 10.28.28.73 --file clusterconfig/virtops-felix.{NET_DOMAIN}.yaml
## wait a few seconds
talosctl bootstrap -n 10.28.28.71 --talosconfig ./clusterconfig/talosconfig
talosctl kubeconfig -f ./ --nodes 10.28.28.71 --talosconfig ./clusterconfig/talosconfig

```
```
export KUBECONFIG=$(pwd)/kubeconfig
if using fish set -x KUBECONFIG $(pwd)/kubeconfig
kubectl get no
# wait until all nodes appear
```
```
kubectl apply -f lb-bgp-test.yaml

kubectl kustomize --enable-helm ./cni | kubectl apply -f -
kubectl kustomize --enable-helm ./kubelet-csr-approver | kubectl apply -f -
```

```
# enable cert rotation
kubectl apply -f https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

re-run talosctl apply-config as above, except remove the --insecure flag