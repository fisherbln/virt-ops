#!/usr/bin/env bash
# shellcheck disable=2312
pushd integrations >/dev/null 2>&1 || exit 1

if test -d cni/charts; then
  rm -rf cni/charts
fi
envsubst < ../../../../kubernetes/virtops/apps/kube-system/cilium/app/values.yaml > cni/values.yaml
kustomize build --enable-helm cni | kubectl apply -f -
rm cni/values.yaml
rm -rf cni/charts

if test -d kubelet-csr-approver/charts; then
  rm -rf kubelet-csr-approver/charts
fi
envsubst < ../../../../kubernetes/virtops/apps/kube-system/kubelet-csr-approver/app/values.yaml > kubelet-csr-approver/values.yaml
#if ! kubectl get ns kube-system >/dev/null 2>&1; then
#  kubectl create ns kube-system
#fi
kustomize build --enable-helm kubelet-csr-approver | kubectl apply -f -
rm kubelet-csr-approver/values.yaml
rm -rf kubelet-csr-approver/charts
