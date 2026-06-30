#!/bin/bash

LAN_IP="192.168.1.178"

echo "Starting hugo server in ${LAN_IP}"
hugo server -D --bind=${LAN_IP} --baseURL http://${LAN_IP}
