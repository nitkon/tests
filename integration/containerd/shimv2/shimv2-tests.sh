#/bin/bash
#
# Copyright (c) 2018 HyperHQ Inc.
#
# SPDX-License-Identifier: Apache-2.0
#
# This test will perform several tests to validate kata containers with
# shimv2 + containerd + cri

source /etc/os-release || source /usr/lib/os-release

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
${SCRIPT_PATH}/../../../.ci/install_cri_containerd.sh
${SCRIPT_PATH}/../../../.ci/install_cni_plugins.sh

export SHIMV2_TEST=true

echo "========================================"
echo "         start shimv2 testing"
echo "========================================"

if [[ "$ID" =~ ^opensuse.*$ ]] || [ "$ID" == sles ] || [ "$ID" == rhel ]; then
	issue="https://github.com/kata-containers/tests/issues/1251"
	echo "Skip shimv2 on $ID, see: $issue"
	exit
fi

${SCRIPT_PATH}/../cri/integration-tests.sh
