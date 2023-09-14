#!/bin/bash

# Reset the worker nodes first since the path to them is through the control plane nodes
talosctl reset --graceful=false --reboot -n node-pve1. -e node-pve1.
talosctl reset --graceful=false --reboot -n node-pve2. -e node-pve2.
talosctl reset --graceful=false --reboot -n node-pve3. -e node-pve3.

echo "Waiting for workers to reset... ^C to stop here"
sleep 5

# Reset the control plane nodes
talosctl reset --graceful=false --reboot -n master-pve1. -e master-pve1.
talosctl reset --graceful=false --reboot -n master-pve2. -e master-pve2.
talosctl reset --graceful=false --reboot -n master-pve3. -e master-pve3.

echo "Waiting for workers to reset... ^C to stop here"
sleep 5
echo "Waiting 10 more seconds... ^C to stop here"
sleep 5
echo "Waiting 5 more seconds... ^C to stop here"
sleep 5

echo "Removing old config files"
rm -rf clusterconfig/*.yaml clusterconfig/talosconfig kubeconfig talsecret.sops.yaml

echo "Complete. Run apply-clusterconfig.sh commands"