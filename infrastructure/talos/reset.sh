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
