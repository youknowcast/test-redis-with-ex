#!/bin/bash

count=$(docker compose exec redis_cluster bash -c "echo 'cluster nodes' | redis-cli" | wc -l)
if [ $((count)) -gt 1 ]; then
  echo "cluster is already created."
  exit 0
fi

NODES=`docker network inspect test-redis-with-ex_cluster_network | jq -r  ".[].Containers[].IPv4Address" | sed -e "s/\/[0-9]*/:6379 /" | sed -e ':a' -e 'N' -e '$!ba' -e "s/\n//g"`
docker compose exec redis_cluster bash -c "yes yes | redis-cli --cluster create ${NODES}"

echo "cluster is created"

