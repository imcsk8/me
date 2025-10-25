#!/bin/bash

# This script connects to the main lxc vserver host using the vps user,
# this user has a symlink to the vserver directoy that contains the blog:
# imcsk8 -> /home/vservers/OCI-Image-Bundles/sotolitolabs/home/imcsk8.chavero.com.mx/docs

ME="imcsk8"

if [[ $1 == "" ]]; then
    echo "Need hostname"
    exit 1
fi

HOST=$1

echo "Building website"
hugo build

echo "Synching website"
rsync -avz -e ssh public/* vps@${HOST}:${ME}/.
