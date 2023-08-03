#!/usr/bin/env bash

# Deploy the configuration to the nodes
talosctl apply-config -n 10.28.28.71 -f ./clusterconfig/virtops-master-pve1.nickeson.net.yaml
talosctl apply-config -n 10.28.28.72 -f ./clusterconfig/virtops-master-pve1.nickeson.net.yaml
talosctl apply-config -n 10.28.28.73 -f ./clusterconfig/virtops-master-pve1.nickeson.net.yaml

talosctl apply-config -n 10.28.28.61 -f ./clusterconfig/virtops-node-pve1.nickeson.net.yaml
talosctl apply-config -n 10.28.28.62 -f ./clusterconfig/virtops-node-pve1.nickeson.net.yaml
talosctl apply-config -n 10.28.28.63 -f ./clusterconfig/virtops-node-pve1.nickeson.net.yaml
