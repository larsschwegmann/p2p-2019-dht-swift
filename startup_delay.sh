#!/bin/sh

sleep ${NODEID}
.build/x86_64-unknown-linux/release/DHTSwiftExecutable dht-module -c docker_configs/node${NODEID}.conf.ini
