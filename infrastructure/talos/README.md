# Talos configuration as code

These folders contain the definitions of my Talos clusters. I use the awesome `talhelper` tool written by [@budimanjojo](https://github.com/budimanjojo) (https://github.com/budimanjojo/talhelper) to generate the individual node configurations.


# omitted: create cluster vms

talhelper gensecret > talsecret.sops.yaml
sops -e -i talsecret.sops.yaml

talhelper genconfig

export TALOSCONFIG=~/src/home-lab/talos/clusterconfig/talosconfig
if using fish shell: set -x TALOSCONFIG ~/repos/virt-ops/infrastructure/talos/cluster-0/clusterconfig/talosconfig
talosctl apply-config --insecure --nodes 10.28.28.71 --file clusterconfig/virtops-felix.{NET_DOMAIN}.yaml
talosctl apply-config --insecure --nodes 10.28.28.72 --file clusterconfig/virtops-felix.{NET_DOMAIN}.yaml
talosctl apply-config --insecure --nodes 10.28.28.73 --file clusterconfig/virtops-felix.{NET_DOMAIN}.yaml
talosctl bootstrap -n 10.28.28.71 --talosconfig ./clusterconfig/talosconfig
talosctl kubeconfig -f --nodes 10.28.28.71 --talosconfig ./clusterconfig/talosconfig
talosctl kubeconfig -f .

export KUBECONFIG=$(pwd)/kubeconfig
if using fish set -x KUBECONFIG $(pwd)/kubeconfig
kubectl get no
# wait until all nodes appear

kubectl kustomize --enable-helm ./cni | kubectl apply -f -
kubectl kustomize --enable-helm ./kubelet-csr-approver | kubectl apply -f -