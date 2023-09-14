#!/usr/bin/env bash

kubectl label nodes master-pve1 node-role.kubernetes.io/master=master
kubectl label nodes master-pve2 node-role.kubernetes.io/master=master
kubectl label nodes master-pve3 node-role.kubernetes.io/master=master
kubectl label nodes node-pve1 node-role.kubernetes.io/worker=worker
kubectl label nodes node-pve2 node-role.kubernetes.io/worker=worker
kubectl label nodes node-pve3 node-role.kubernetes.io/worker=worker