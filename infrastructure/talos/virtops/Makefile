.ONESHELL:
.SHELLFLAGS += -e -o pipefail

#export TALOSCONFIG := ${HOME}/repos/infrastructure/talos/virtops/clusterconfig/talosconfig
export TALOSCONFIG := /Users/brian/repos/virt-ops/infrastructure/talos/virtops/clusterconfig/talosconfig
export KUBECONFIG := /Users/brian/repos/virt-ops/infrastructure/talos/virtops/kubeconfig
export BASEDIR := /Users/brian/repos/virt-ops/



TC := talosctl --talosconfig ${TALOSCONFIG}
KC := kubectl

reset:
	${TC} reset --endpoints 10.28.28.71 --graceful=false -n 10.28.28.71 -n 10.28.28.72 -n 10.28.28.73 -n 10.28.28.61 -n 10.28.28.62 -n 10.28.28.63 --reboot --wait=false
	rm -rf clusterconfig/*.yaml clusterconfig/talosconfig kubeconfig talsecret.sops.yaml

gen:
	talhelper gensecret > talsecret.sops.yaml
	sops -e -i talsecret.sops.yaml
	talhelper genconfig

apply-talos-first:
	${TC} apply-config --insecure --nodes 10.28.28.71 --file clusterconfig/virtops-delta.nickeson.net.yaml
	${TC} apply-config --insecure --nodes 10.28.28.72 --file clusterconfig/virtops-enigma.nickeson.net.yaml
	${TC} apply-config --insecure --nodes 10.28.28.73 --file clusterconfig/virtops-felix.nickeson.net.yaml
	${TC} apply-config --insecure --nodes 10.28.28.61 --file clusterconfig/virtops-node-pve1.nickeson.net.yaml
	${TC} apply-config --insecure --nodes 10.28.28.62 --file clusterconfig/virtops-node-pve2.nickeson.net.yaml
	${TC} apply-config --insecure --nodes 10.28.28.63 --file clusterconfig/virtops-node-pve3.nickeson.net.yaml

bootstrap:
	${TC} bootstrap --nodes 10.28.28.71

extras:
	
	${KC} kustomize --enable-helm ./cni | kubectl apply -f -
	${KC} kustomize --enable-helm ./kubelet-csr-approver | kubectl apply -f -

apply-talos:
	${TC} apply-config --nodes 10.28.28.71 --file clusterconfig/virtops-delta.nickeson.net.yaml
	${TC} apply-config --nodes 10.28.28.72 --file clusterconfig/virtops-enigma.nickeson.net.yaml
	${TC} apply-config --nodes 10.28.28.73 --file clusterconfig/virtops-felix.nickeson.net.yaml
	${TC} apply-config --nodes 10.28.28.61 --file clusterconfig/virtops-node-pve1.nickeson.net.yaml
	${TC} apply-config --nodes 10.28.28.62 --file clusterconfig/virtops-node-pve2.nickeson.net.yaml
	${TC} apply-config --nodes 10.28.28.63 --file clusterconfig/virtops-node-pve3.nickeson.net.yaml

reboot:
	${TC} reboot --nodes 10.28.28.71 --wait
	${TC} reboot --nodes 10.28.28.72 --wait
	${TC} reboot --nodes 10.28.28.73 --wait
	${TC} reboot --nodes 10.28.28.61 --wait
	${TC} reboot --nodes 10.28.28.62 --wait
	${TC} reboot --nodes 10.28.28.63 --wait

kubeconf:
	${TC} kubeconfig --nodes 10.28.28.71 -f .


nuke-and-pave:
	$(MAKE) reset
	$(MAKE) gen
	sleep 120
	$(MAKE) apply-talos-first
	sleep 60
	$(MAKE) bootstrap
	sleep 150
	$(MAKE) kubeconf
	kubectl get no
	talosctl --nodes 10.28.28.71 get members
    
##	kubectl apply -f ${BASEDIR}/infrastructure/talos/virtops/cni/install.yaml
##	$(MAKE) extras
	sleep 20
	talhelper genconfig -c talconfig.yaml
	$(MAKE) apply-talos
	kubectl get no
	sleep 20
	kubectl get no
	talosctl --nodes 10.28.28.71 get members
	cilium status
###	cilium connectivity test


bootstrap-flux:
###	cd ~/repos/virt-ops/
	kubectl label nodes delta node-role.kubernetes.io/master=master
	kubectl label nodes enigma node-role.kubernetes.io/master=master
	kubectl label nodes felix node-role.kubernetes.io/master=master
	kubectl label nodes node-pve1 node-role.kubernetes.io/worker=worker
	kubectl label nodes node-pve2 node-role.kubernetes.io/worker=worker
	kubectl label nodes node-pve3 node-role.kubernetes.io/worker=worker
	kubectl apply --server-side --kustomize ${BASEDIR}/kubernetes/virtops/bootstrap
	sops -d ${BASEDIR}/kubernetes/virtops/bootstrap/age-key.sops.yaml | kubectl apply -f -
	sops -d ${BASEDIR}/kubernetes/virtops/bootstrap/github-deploy-key.sops.yaml | kubectl apply -f -
	sops -d ${BASEDIR}/kubernetes/virtops/flux/vars/cluster-secrets.sops.yaml  | kubectl apply -f -
	kubectl apply -f ${BASEDIR}/kubernetes/virtops/flux/vars/cluster-settings.yaml
	kubectl get pods -n flux-system
	sleep 10
	kubectl get pods -n flux-system
	kubectl apply --server-side --kustomize ${BASEDIR}/kubernetes/virtops/flux/config
	sleep 10
	#task cl:reconcile
	flux reconcile -n flux-system source git home-ops-kubernetes
	sleep 15
	flux reconcile -n flux-system kustomization cluster
	kubectl get kustomizations -A
	
