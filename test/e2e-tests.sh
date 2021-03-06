#!/usr/bin/env bash

# Copyright 2018 The Knative Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script calls out to scripts in knative/test-infra to setup a cluster
# and deploy the Pipeline CRD to it for running integration tests.

source $(dirname $0)/e2e-common.sh

# Script entry point.

initialize $@

header "Setting up environment"

# Handle failures ourselves, so we can dump useful info.
set +o errexit
set +o pipefail

echo ">> Deploying Pipeline CRD"
ko apply -f config/ || fail_test "Build pipeline installation failed"

# Wait for pods to be running in the namespaces we are deploying to
wait_until_pods_running knative-build-pipeline || fail_test "Pipeline CRD did not come up"

failed=0

# Run the integration tests
header "Running Go e2e tests"
go_test_e2e -timeout=20m ./test || failed=1

# Run these _after_ the integration tests b/c they don't quite work all the way
# and they cause a lot of noise in the logs, making it harder to debug integration
# test failures.
${REPO_ROOT_DIR}/test/e2e-tests-yaml.sh --run-tests || failed=1

(( failed )) && fail_test
success
