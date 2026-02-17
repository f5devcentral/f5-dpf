#!/bin/bash
IMAGE=bf-bundle-3.2.1-34_25.11_ubuntu-24.04_64k_prod.bfb
BMCIP=$1
ls -l $IMAGE
bfb-install -b $IMAGE --rshim $BMCIP:rshim0 --config bf.cfg
