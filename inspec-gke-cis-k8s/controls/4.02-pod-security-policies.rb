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

pod_security_policies_api = 'policy/v1beta1'
pod_security_policies = k8sobjects(api: pod_security_policies_api, type: 'podsecuritypolicies').items

# 4.2.1
sub_control_id = "#{control_id}.1"
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

  if pod_security_policies.count.zero?
    impact 'none'
    describe 'GKE Cluster does not have any PodSecurityPolicies, this test is Not Applicable.' do
      skip 'GKE Cluster does not have any PodSecurityPolicies.'
    end
  else
    has_non_privileged_policy = false
    pod_security_policies.each do |pod_security_policy_item|
      pod_security_policy = k8sobject(api: pod_security_policies_api, type: 'podsecuritypolicies', name: pod_security_policy_item.name)
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

# 4.2.2
sub_control_id = "#{control_id}.2"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Minimize the admission of containers wishing to share the host
  process ID namespace"

  desc 'Do not generally permit containers to be run with the hostPID flag set to true.'
  desc 'rationale', "A container running in the host's PID namespace can inspect processes running outside the
  container. If the container also has access to ptrace capabilities this can be used to escalate
  privileges outside of the container.
  There should be at least one PodSecurityPolicy (PSP) defined which does not permit
  containers to share the host PID namespace.
  If you need to run containers which require hostPID, this should be defined in a separate
  PSP and you should carefully check RBAC controls to ensure that only limited service
  accounts and users are given permission to access that PSP."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/concepts/policy/pod-security-policy'

  if pod_security_policies.count.zero?
    impact 'none'
    describe 'GKE Cluster does not have any PodSecurityPolicies, this test is Not Applicable.' do
      skip 'GKE Cluster does not have any PodSecurityPolicies.'
    end
  else
    has_host_pid_disabled = false
    pod_security_policies.each do |pod_security_policy_item|
      pod_security_policy = k8sobject(api: pod_security_policies_api, type: 'podsecuritypolicies', name: pod_security_policy_item.name)
      has_host_pid_disabled = true if pod_security_policy.item.spec.hostPID != true
    end
    describe "[#{gcp_project_id}] Pod Security Policies" do
      subject { has_host_pid_disabled }
      it 'have a policy with hostPID not enabled' do
        expect(subject).to be true
      end
    end
  end
end

# 4.2.3
sub_control_id = "#{control_id}.3"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Minimize the admission of containers wishing to share the host
  IPC namespace"

  desc 'Do not generally permit containers to be run with the hostIPC flag set to true.'
  desc 'rationale', "A container running in the host's IPC namespace can use IPC to interact with processes
  outside the container.
  There should be at least one PodSecurityPolicy (PSP) defined which does not permit
  containers to share the host IPC namespace.
  If you have a requirement to containers which require hostIPC, this should be defined in a
  separate PSP and you should carefully check RBAC controls to ensure that only limited
  service accounts and users are given permission to access that PSP."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/concepts/policy/pod-security-policy'

  if pod_security_policies.count.zero?
    impact 'none'
    describe 'GKE Cluster does not have any PodSecurityPolicies, this test is Not Applicable.' do
      skip 'GKE Cluster does not have any PodSecurityPolicies.'
    end
  else
    has_host_ipc_disabled = false
    pod_security_policies.each do |pod_security_policy_item|
      pod_security_policy = k8sobject(api: pod_security_policies_api, type: 'podsecuritypolicies', name: pod_security_policy_item.name)
      has_host_ipc_disabled = true if pod_security_policy.item.spec.hostIPC != true
    end
    describe "[#{gcp_project_id}] Pod Security Policies" do
      subject { has_host_ipc_disabled }
      it 'have a policy with hostIPC not enabled' do
        expect(subject).to be true
      end
    end
  end
end

# 4.2.4
sub_control_id = "#{control_id}.4"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Minimize the admission of containers wishing to share the host
  network namespace"

  desc 'Do not generally permit containers to be run with the hostNetwork flag set to true.'
  desc 'rationale', "A container running in the host's network namespace could access the local loopback
  device, and could access network traffic to and from other pods.
  There should be at least one PodSecurityPolicy (PSP) defined which does not permit
  containers to share the host network namespace.
  If you have need to run containers which require hostNetwork, this should be defined in a
  separate PSP and you should carefully check RBAC controls to ensure that only limited
  service accounts and users are given permission to access that PSP."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/concepts/policy/pod-security-policy'

  if pod_security_policies.count.zero?
    impact 'none'
    describe 'GKE Cluster does not have any PodSecurityPolicies, this test is Not Applicable.' do
      skip 'GKE Cluster does not have any PodSecurityPolicies.'
    end
  else
    has_host_network_disabled = false
    pod_security_policies.each do |pod_security_policy_item|
      pod_security_policy = k8sobject(api: pod_security_policies_api, type: 'podsecuritypolicies', name: pod_security_policy_item.name)
      has_host_network_disabled = true if pod_security_policy.item.spec.hostNetwork != true
    end
    describe "[#{gcp_project_id}] Pod Security Policies" do
      subject { has_host_network_disabled }
      it 'have a policy with hostNetwork not enabled' do
        expect(subject).to be true
      end
    end
  end
end

# 4.2.5
sub_control_id = "#{control_id}.5"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Minimize the admission of containers with
  allowPrivilegeEscalation"

  desc 'Do not generally permit containers to be run with the allowPrivilegeEscalation flag set
  to true.'
  desc 'rationale', "A container running with the allowPrivilegeEscalation flag set to true may have
  processes that can gain more privileges than their parent.
  There should be at least one PodSecurityPolicy (PSP) defined which does not permit
  containers to allow privilege escalation. The option exists (and is defaulted to true) to
  permit setuid binaries to run.
  If you have need to run containers which use setuid binaries or require privilege escalation,
  this should be defined in a separate PSP and you should carefully check RBAC controls to
  ensure that only limited service accounts and users are given permission to access that
  PSP."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/concepts/policy/pod-security-policy'

  if pod_security_policies.count.zero?
    impact 'none'
    describe 'GKE Cluster does not have any PodSecurityPolicies, this test is Not Applicable.' do
      skip 'GKE Cluster does not have any PodSecurityPolicies.'
    end
  else
    has_privilege_escalation_disabled = false
    pod_security_policies.each do |pod_security_policy_item|
      pod_security_policy = k8sobject(api: pod_security_policies_api, type: 'podsecuritypolicies', name: pod_security_policy_item.name)
      has_privilege_escalation_disabled = true if pod_security_policy.item.spec.allowPrivilegeEscalation != true
    end
    describe "[#{gcp_project_id}] Pod Security Policies" do
      subject { has_privilege_escalation_disabled }
      it 'have a policy with allowPrivilegeEscalation not enabled' do
        expect(subject).to be true
      end
    end
  end
end

# 4.2.6
sub_control_id = "#{control_id}.6"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Minimize the admission of root containers"

  desc 'Do not generally permit containers to be run as the root user.'
  desc 'rationale', "Containers may run as any Linux user. Containers which run as the root user, whilst
  constrained by Container Runtime security features still have a escalated likelihood of
  container breakout.
  Ideally, all containers should run as a defined non-UID 0 user.
  There should be at least one PodSecurityPolicy (PSP) defined which does not permit root
  users in a container.
  If you need to run root containers, this should be defined in a separate PSP and you should
  carefully check RBAC controls to ensure that only limited service accounts and users are
  given permission to access that PSP."

  tag cis_scored: true
  tag cis_level: 2
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/concepts/policy/pod-security-policy/#enabling-pod-security-policies'

  if pod_security_policies.count.zero?
    impact 'none'
    describe 'GKE Cluster does not have any PodSecurityPolicies, this test is Not Applicable.' do
      skip 'GKE Cluster does not have any PodSecurityPolicies.'
    end
  else

    has_root_user_disabled = true
    pod_security_policies.each do |pod_security_policy_item|
      has_root_user_disabled = true
      pod_security_policy = k8sobject(api: pod_security_policies_api, type: 'podsecuritypolicies', name: pod_security_policy_item.name)
      if pod_security_policy.item.spec.runAsUser.rule == 'MustRunAs'
        pod_security_policy.item.spec.runAsUser.ranges.each do |range|
          has_root_user_disabled = false if range.min.zero?
        end
      elsif pod_security_policy.item.spec.runAsUser.rule == 'RunAsAny'
        has_root_user_disabled = false
      end
      break if has_root_user_disabled == true
    end

    describe "[#{gcp_project_id}] Pod Security Policies" do
      subject { has_root_user_disabled }
      it 'have a policy which does not allow container to run as root user' do
        expect(subject).to be true
      end
    end
  end
end

# 4.2.7
sub_control_id = "#{control_id}.7"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Minimize the admission of containers with the NET_RAW
  capability"

  desc 'Do not generally permit containers with the potentially dangerous NET_RAW capability.'
  desc 'rationale', "Containers run with a default set of capabilities as assigned by the Container Runtime. By
  default this can include potentially dangerous capabilities. With Docker as the container
  runtime the NET_RAW capability is enabled which may be misused by malicious
  containers.
  Ideally, all containers should drop this capability.
  There should be at least one PodSecurityPolicy (PSP) defined which prevents containers
  with the NET_RAW capability from launching.
  If you need to run containers with this capability, this should be defined in a separate PSP
  and you should carefully check RBAC controls to ensure that only limited service accounts
  and users are given permission to access that PSP."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://www.nccgroup.trust/uk/our-research/abusing-privileged-and-unprivileged-linux-containers/'

  if pod_security_policies.count.zero?
    impact 'none'
    describe 'GKE Cluster does not have any PodSecurityPolicies, this test is Not Applicable.' do
      skip 'GKE Cluster does not have any PodSecurityPolicies.'
    end
  else
    has_req_capabilities_dropped = false
    pod_security_policies.each do |pod_security_policy_item|
      pod_security_policy = k8sobject(api: pod_security_policies_api, type: 'podsecuritypolicies', name: pod_security_policy_item.name)
      next if pod_security_policy.item.spec.requiredDropCapabilities.nil?
      has_req_capabilities_dropped = true if pod_security_policy.item.spec.requiredDropCapabilities.include? 'ALL'
      has_req_capabilities_dropped = true if pod_security_policy.item.spec.requiredDropCapabilities.include? 'NET_RAW'
    end
    describe "[#{gcp_project_id}] Pod Security Policies" do
      subject { has_req_capabilities_dropped }
      it 'have a policy with requiredDropCapabilities to include either ALL or NET_RAW' do
        expect(subject).to be true
      end
    end
  end
end

# 4.2.8
sub_control_id = "#{control_id}.8"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Minimize the admission of containers with added capabilities"

  desc 'Do not generally permit containers with capabilities assigned beyond the default set.'
  desc 'rationale', "Containers run with a default set of capabilities as assigned by the Container Runtime.
  Capabilities outside this set can be added to containers which could expose them to risks of
  container breakout attacks.
  There should be at least one PodSecurityPolicy (PSP) defined which prevents containers
  with capabilities beyond the default set from launching.
  If you need to run containers with additional capabilities, this should be defined in a
  separate PSP and you should carefully check RBAC controls to ensure that only limited
  service accounts and users are given permission to access that PSP."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://www.nccgroup.trust/uk/our-research/abusing-privileged-and-unprivileged-linux-containers/'

  if pod_security_policies.count.zero?
    impact 'none'
    describe 'GKE Cluster does not have any PodSecurityPolicies, this test is Not Applicable.' do
      skip 'GKE Cluster does not have any PodSecurityPolicies.'
    end
  else
    has_added_capabilities = false
    pod_security_policies.each do |pod_security_policy_item|
      pod_security_policy = k8sobject(api: pod_security_policies_api, type: 'podsecuritypolicies', name: pod_security_policy_item.name)
      next if pod_security_policy.item.spec.allowedCapabilities.nil?
      if pod_security_policy.item.spec.allowedCapabilities.count.positive?
        has_added_capabilities = true
        break
      end
    end
    describe "[#{gcp_project_id}] Pod Security Policies" do
      subject { has_added_capabilities }
      it 'not have a policy which has non-empty allowedCapabilities' do
        expect(subject).to be false
      end
    end
  end
end

# 4.2.9
sub_control_id = "#{control_id}.9"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Minimize the admission of containers with capabilities assigned"

  desc 'Do not generally permit containers with capabilities.'
  desc 'rationale', "Containers run with a default set of capabilities as assigned by the Container Runtime.
  Capabilities are parts of the rights generally granted on a Linux system to the root user.
  In many cases applications running in containers do not require any capabilities to operate,
  so from the perspective of the principal of least privilege use of capabilities should be
  minimized."

  tag cis_scored: false
  tag cis_level: 2
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://www.nccgroup.trust/uk/our-research/abusing-privileged-and-unprivileged-linux-containers/'

  if pod_security_policies.count.zero?
    impact 'none'
    describe 'GKE Cluster does not have any PodSecurityPolicies, this test is Not Applicable.' do
      skip 'GKE Cluster does not have any PodSecurityPolicies.'
    end
  else
    impact 'none'
    describe 'For each PSP, check whether capabilities have been forbidden. This test needs to be performed manually.' do
      skip 'This test needs to be performed manually.'
    end
  end
end
