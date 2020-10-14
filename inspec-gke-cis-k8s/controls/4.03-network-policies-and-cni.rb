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
control_id = '4.3'
control_abbrev = 'network-policies-and-cni'

# 4.3.2
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

  namespaces = []
  k8sobjects(api: 'v1', type: 'namespaces').items.each do |namespace_k8s|
    namespaces.push(namespace_k8s.name) unless ["kube-node-lease", "kube-public", "kube-system"].include?(namespace_k8s.name) 
  end

  has_network_policy = true
  namespaces.each do |namespace|
    if k8sobjects(api: 'networking.k8s.io/v1', type: 'networkpolicies', namespace: namespace).items.count.zero?
      has_network_policy = false
      break
    end
  end
  
  describe "[#{gcp_project_id}] Network Policies" do
    subject { has_network_policy }
    it 'exist for each Namespace in the cluster' do
      expect(subject).to be true
    end
  end
end
