#!/usr/bin/env bats
#
# Copyright (c) 2019 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

load "${BATS_TEST_DIRNAME}/../../.ci/lib.sh"
load "${BATS_TEST_DIRNAME}/../../lib/common.bash"
source "/etc/os-release" || source "/usr/lib/os-release"

issue="https://github.com/kata-containers/tests/issues/1731"

setup() {
	[ "$ID" == "centos" ] || [ "$ID" == "fedora" ] && skip "test not working see: ${issue}"
	export KUBECONFIG="$HOME/.kube/config"
	get_pod_config_dir
}

@test "Port forwarding" {
	[ "$ID" == "centos" ] || [ "$ID" == "fedora" ] && skip "test not working see: ${issue}"
	deployment_name="redis-master"

	# Create deployment
	kubectl apply -f "${pod_config_dir}/redis-master-deployment.yaml"

	# Check deployment
	kubectl wait --for=condition=Available deployment/"$deployment_name"
	kubectl expose deployment/"$deployment_name"

	# Get pod name
	pod_name=$(kubectl get pods --output=jsonpath={.items..metadata.name})
	kubectl wait --for=condition=Ready pod "$pod_name"

	# View replicaset
	kubectl get rs

	# Create service
	kubectl apply -f "${pod_config_dir}/redis-master-service.yaml"

	# Check service
	kubectl get svc | grep redis

	# Check redis service
	port_redis=$(kubectl get pods $pod_name --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}')

	# Verify that redis is running in the pod and listening on port
	port=6379
	[ "$port_redis" -eq "$port" ]

	# Forward a local port to a port on the pod
	(2&>1 kubectl port-forward "$pod_name" 7000:"$port"> /dev/null) &

	# Run redis-cli
	retries="10"
	ok="0"

	for _ in $(seq 1 "$retries"); do
		if sudo -E redis-cli ping | grep -q "PONG" ; then
			ok="1"
			break;
		fi
		sleep 1
	done

	[ "$ok" -eq "1" ]
}

teardown() {
	[ "$ID" == "centos" ] || [ "$ID" == "fedora" ] && skip "test not working see: ${issue}"
	kubectl delete -f "${pod_config_dir}/redis-master-deployment.yaml"
	kubectl delete -f "${pod_config_dir}/redis-master-service.yaml"
}