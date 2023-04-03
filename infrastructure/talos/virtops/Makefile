.ONESHELL:
.SHELLFLAGS += -e -o pipefail

#export TALOSCONFIG := ${HOME}/repos/infrastructure/talos/virtops/clusterconfig/talosconfig
export TALOSCONFIG := /Users/brian/repos/virt-ops/infrastructure/talos/virtops/clusterconfig/talosconfig
export KUBECONFIG := /Users/brian/repos/infrastructure/talos/virtops/kubeconfig



TC := talosctl --talosconfig ${TALOSCONFIG}
KC := kubectl

reset:
	${TC} reset --endpoints 10.28.28.71 --graceful=false -n 10.28.28.71 -n 10.28.28.72 -n 10.28.28.73 --reboot --wait=false
	rm -rf clusterconfig/*.yaml clusterconfig/talosconfig kubeconfig talsecret.sops.yaml

gen:
	talhelper gensecret > talsecret.sops.yaml
	sops -e -i talsecret.sops.yaml
	talhelper genconfig

apply-talos-first:
	${TC} apply-config --insecure --nodes 10.28.28.71 --file clusterconfig/virtops-delta.nickeson.net.yaml
	${TC} apply-config --insecure --nodes 10.28.28.72 --file clusterconfig/virtops-enigma.nickeson.net.yaml
	${TC} apply-config --insecure --nodes 10.28.28.73 --file clusterconfig/virtops-felix.nickeson.net.yaml

bootstrap:
	${TC} bootstrap --nodes 10.28.28.71

extras:
	
	${KC} kustomize --enable-helm ./cni | kubectl apply -f -
	${KC} kustomize --enable-helm ./kubelet-csr-approver | kubectl apply -f -

apply-talos:
	${TC} apply-config --nodes 10.28.28.71 --file clusterconfig/virtops-delta.nickeson.net.yaml
	${TC} apply-config --nodes 10.28.28.72 --file clusterconfig/virtops-enigma.nickeson.net.yaml
	${TC} apply-config --nodes 10.28.28.73 --file clusterconfig/virtops-felix.nickeson.net.yaml

reboot:
	${TC} reboot --nodes 10.28.28.71 --wait
	${TC} reboot --nodes 10.28.28.72 --wait
	${TC} reboot --nodes 10.28.28.73 --wait

kubeconf:
	${TC} kubeconfig --nodes 10.28.28.71 -f .


nuke-and-pave:
	$(MAKE) reset
	$(MAKE) gen
	sleep 120
	$(MAKE) apply-talos-first
	sleep 60
	$(MAKE) bootstrap
	sleep 60
	$(MAKE) kubeconf
	kubectl get no
	talosctl --nodes 10.28.28.71 get members
	$(MAKE) extras
	sleep 60
	talhelper genconfig -c talconfig.yaml-2
	$(MAKE) apply-talos
	kubectl get no
	sleep 60
	kubectl get no
	talosctl --nodes 10.28.28.71 get members
	cilium status
	cilium connectivity test


bootstrap-flux:
	cd ../
	kubectl apply --server-side --kustomize ./kubernetes/virtops/bootstrap
	sops -d kubernetes/virtops/bootstrap/age-key.sops.yaml | kubectl apply -f -
	sops -d kubernetes/virtops/bootstrap/github-deploy-key.sops.yaml | kubectl apply -f -
	sops -d kubernetes/virtops/flux/vars/global-secrets.yaml | kubectl apply -f -
	kubectl apply -f kubernetes/virtops/flux/vars/global-vars.yaml
	kubectl get pods -n flux-system
	sleep 10
	kubectl apply --server-side --kustomize ./kubernetes/virtops/flux/config
	sleep 10
	flux reconcile -n flux-system source git flux-system
	flux reconcile -n flux-system kustomization cluster
