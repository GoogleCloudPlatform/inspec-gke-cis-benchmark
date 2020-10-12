# Copyright 2020 The inspec-gke-cis-benchmark Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

gcp_project_id = input('gcp_project_id')
cis_version = input('cis_version')
cis_url = input('cis_url')
control_id = '4.2'
control_abbrev = 'pod-security-policies'

# 4.2.1
sub_control_id = "#{control_id}.2"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Minimize the admission of privileged containers"

  desc 'Do not generally permit containers to be run with the securityContext.privileged flag
  set to true.'
  desc 'rationale', "Privileged containers have access to all Linux Kernel capabilities and devices. A container
  running with full privileges can do almost everything that the host can do. This flag exists
  to allow special use-cases, like manipulating the network stack and accessing devices.
  There should be at least one PodSecurityPolicy (PSP) defined which does not permit
  privileged containers.
  If you need to run privileged containers, this should be defined in a separate PSP and you
  should carefully check RBAC controls to ensure that only limited service accounts and
  users are given permission to access that PSP."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/concepts/policy/pod-security-policy/#enabling-pod-security-policies'

  pod_security_policies = k8sobjects(api: 'extensions/v1beta1', type: 'podsecuritypolicies').items
  if pod_security_policies.zero?
    impact 'none'
    describe 'GKE Cluster does not have any PodSecurityPolicies, this test is Not Applicable.' do
      skip 'GKE Cluster does not have any PodSecurityPolicies.'
    end
  else
    has_non_privileged_policy = false
    pod_security_policies.each do |pod_security_policy_item|
      pod_security_policy = k8sobject(api: 'extensions/v1beta1', type: 'podsecuritypolicies', name: pod_security_policy_item.name)
      has_non_privileged_policy = true if pod_security_policy.item.spec.privileged != true
    end
    describe "[#{gcp_project_id}] Pod Security Policies" do
      subject { has_non_privileged_policy }
      it 'have a non-privileged policy' do
        expect(subject).to be true
      end
    end
  end
end
