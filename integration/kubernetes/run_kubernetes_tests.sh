#!/bin/bash
#
# Copyright (c) 2018 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

source /etc/os-release || source /usr/lib/os-release
kubernetes_dir=$(dirname "$(readlink -f "$0")")
cidir="${kubernetes_dir}/../../.ci/"
source "${cidir}/lib.sh"

KATA_HYPERVISOR="${KATA_HYPERVISOR:-qemu}"

# Currently, Kubernetes tests only work on Ubuntu, Centos and Fedora.
# We should delete this condition, when it works for other Distros.
if [ "$ID" != "ubuntu" ] && [ "$ID" != "centos" ] && [ "$ID" != "fedora" ]; then
	echo "Skip Kubernetes tests on $ID"
	echo "kubernetes tests on $ID aren't supported yet"
	exit 0
fi

if [ "$KATA_HYPERVISOR" == "firecracker" ]; then
	die "Kubernetes tests will not run with $KATA_HYPERVISOR"
fi

# Docker is required to initialize kubeadm, even if we are
# using cri-o as the runtime.
systemctl is-active --quiet docker || sudo systemctl start docker

pushd "$kubernetes_dir"
./init.sh
bats k8s-replication.bats
bats nginx.bats
bats k8s-uts+ipc-ns.bats
bats k8s-env.bats
bats k8s-port-forward.bats
bats k8s-empty-dirs.bats
bats k8s-limit-range.bats
bats k8s-credentials-secrets.bats
bats k8s-configmap.bats
bats k8s-custom-dns.bats
bats k8s-pid-ns.bats
bats k8s-cpu-ns.bats
bats k8s-parallel.bats
bats k8s-security-context.bats
bats k8s-liveness-probes.bats
bats k8s-attach-handlers.bats
bats k8s-qos-pods.bats
bats k8s-pod-quota.bats
bats k8s-sysctls.bats
bats k8s-volume.bats
bats k8s-projected-volume.bats
bats k8s-job.bats
bats k8s-memory.bats
bats k8s-block-volume.bats
bats k8s-shared-volume.bats
bats k8s-expose-ip.bats
./cleanup_env.sh
popd
