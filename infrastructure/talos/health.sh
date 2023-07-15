#!/bin/bash

# Usage: ./health.sh 10.28.28.71 (or another node ip)
talosctl health --control-plane-nodes 10.28.28.71,10.28.28.72,10.28.28.73 --worker-nodes 10.28.28.61,10.28.28.62,10.28.28.63 -n $*
