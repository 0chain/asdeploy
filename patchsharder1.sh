#!/bin/bash

sed -i "s|0chaindev/sharder:staging-02e43b7b|0chaindev/sharder:pr-1926-1a9bf524|g" ~/sharder_deploy/docker.local/build.sharder/p0docker-compose.yaml
cd ~/sharder_deploy/docker.local/sharder1
../bin/start.p0sharder.sh
