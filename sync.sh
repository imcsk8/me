#!/bin/bash

ME="imcsk8"

if [[ $1 == "" ]]; then
    echo "Need hostname"
    exit 1
fi

HOST=$1

rsync -avz -e ssh public/* vps@${HOST}:${ME}/.
