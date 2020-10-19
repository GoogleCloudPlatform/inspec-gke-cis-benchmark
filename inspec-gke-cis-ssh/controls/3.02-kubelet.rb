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
control_id = '3.2'
control_abbrev = 'kubelet'

client_ca_file_path = input('client_ca_file_path')
event_record_qps = input('event_record_qps')
tls_cert_file = input('tls_cert_file')
tls_private_key_file = input('tls_private_key_file')

kubelet_config_file_path = command('ps -ef | grep kubelet | grep -e "--config " | sed "s/^.*\(--config .* \).*$/\1/"  | awk \'{print $2}\'').stdout.split("\n").first
kubelet_config_file = yaml(kubelet_config_file_path)

# 3.2.1
sub_control_id = "#{control_id}.1"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the --anonymous-auth argument is set to false"

  desc 'Disable anonymous requests to the Kubelet server.'
  desc 'rationale', "When enabled, requests that are not rejected by other configured authentication methods
  are treated as anonymous requests. These requests are then served by the Kubelet server.
  You should rely on authentication to authorize access and disallow anonymous requests."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-authentication-authorization/#kubelet-authentication'

  anonymous_auth_config = kubelet_config_file.authentication["anonymous"]["enabled"]

  describe "[#{gcp_project_id}] Kubelet config file #{kubelet_config_file_path}" do
    subject { anonymous_auth_config }
    it 'should have anonymous authentication disabled' do
      expect(subject).to cmp "false"
    end
  end

end

# 3.2.2
sub_control_id = "#{control_id}.2"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the --authorization-mode argument is not set to AlwaysAllow"

  desc 'Do not allow all requests. Enable explicit authorization.'
  desc 'rationale', "Kubelets, by default, allow all authenticated requests (even anonymous ones) without
  needing explicit authorization checks from the apiserver. You should restrict this behavior
  and only allow explicitly authorized requests."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-authentication-authorization/#kubelet-authentication'

  authorization_mode_config = kubelet_config_file.authorization["mode"]

  describe "[#{gcp_project_id}] Kubelet config file #{kubelet_config_file_path}" do
    subject { authorization_mode_config }
    it 'should not have authorization mode set to AlwaysAllow' do
      expect(subject).not_to cmp "AlwaysAllow"
    end
  end

end

# 3.2.3
sub_control_id = "#{control_id}.3"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the --client-ca-file argument is set as appropriate"

  desc 'Enable Kubelet authentication using certificates.'
  desc 'rationale', "The connections from the apiserver to the kubelet are used for fetching logs for pods,
  attaching (through kubectl) to running pods, and using the kubelet’s port-forwarding
  functionality. These connections terminate at the kubelet’s HTTPS endpoint. By default, the
  apiserver does not verify the kubelet’s serving certificate, which makes the connection
  subject to man-in-the-middle attacks, and unsafe to run over untrusted and/or public
  networks. Enabling Kubelet certificate authentication ensures that the apiserver could
  authenticate the Kubelet before submitting any requests."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-authentication-authorization/#kubelet-authentication'

  client_ca_file = kubelet_config_file.authentication["x509"]["clientCAFile"]

  describe "[#{gcp_project_id}] Kubelet config file #{kubelet_config_file_path}" do
    subject { client_ca_file }
    it 'should be have certificate authentication enabled' do
      expect(subject).to cmp client_ca_file_path
    end
  end

end

# 3.2.4
sub_control_id = "#{control_id}.4"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the --read-only-port argument is set to 0"

  desc 'Disable the read-only port.'
  desc 'rationale', "The Kubelet process provides a read-only API in addition to the main Kubelet API.
  Unauthenticated access is provided to this read-only API which could possibly retrieve
  potentially sensitive information about the cluster."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/admin/kubelet/'

  describe "[#{gcp_project_id}] Kubelet config file #{kubelet_config_file_path}" do
    subject { yaml(kubelet_config_file_path) }
    its('readOnlyPort') { should cmp 0 }
  end

end

# 3.2.5
sub_control_id = "#{control_id}.5"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the --streaming-connection-idle-timeout argument is not set to 0"

  desc 'Do not disable timeouts on streaming connections.'
  desc 'rationale', "Setting idle timeouts ensures that you are protected against Denial-of-Service attacks,
  inactive connections and running out of ephemeral ports."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://github.com/kubernetes/kubernetes/pull/18552'

  describe "[#{gcp_project_id}] Kubelet config file #{kubelet_config_file_path}" do
    subject { yaml(kubelet_config_file_path) }
    its('streamingConnectionIdleTimeout') { should_not eq 0 }
  end

end

# 3.2.6
sub_control_id = "#{control_id}.6"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the --protect-kernel-defaults argument is set to true"

  desc 'Protect tuned kernel parameters from overriding kubelet default kernel parameter values.'
  desc 'rationale', "Kernel parameters are usually tuned and hardened by the system administrators before
  putting the systems into production. These parameters protect the kernel and the system.
  Your kubelet kernel defaults that rely on such parameters should be appropriately set to
  match the desired secured system state. Ignoring this could potentially lead to running
  pods with undesired kernel behavior."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/'

  describe "[#{gcp_project_id}] Kubelet config file #{kubelet_config_file_path}" do
    subject { yaml(kubelet_config_file_path) }
    its('protectKernelDefaults') { should cmp 'true' }
  end

end

# 3.2.7
sub_control_id = "#{control_id}.7"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the --make-iptables-util-chains argument is set to true"

  desc 'Allow Kubelet to manage iptables.'
  desc 'rationale', "Kubelets can automatically manage the required changes to iptables based on how you
  choose your networking options for the pods. It is recommended to let kubelets manage
  the changes to iptables. This ensures that the iptables configuration remains in sync with
  pods networking configuration. Manually configuring iptables with dynamic pod network
  configuration changes might hamper the communication between pods/containers and to
  the outside world. You might have iptables rules too restrictive or too open."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/'

  describe "[#{gcp_project_id}] Kubelet config file #{kubelet_config_file_path}" do
    subject { yaml(kubelet_config_file_path) }
    its('makeIPTablesUtilChains') { should_not cmp 'false' }
  end

end

# 3.2.8
sub_control_id = "#{control_id}.8"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'none'

  title "[#{control_abbrev.upcase}] Ensure that the --hostname-override argument is not set"

  desc 'Do not override node hostnames.'
  desc 'rationale', "Overriding hostnames could potentially break TLS setup between the kubelet and the
  apiserver. Additionally, with overridden hostnames, it becomes increasingly difficult to
  associate logs with a particular node and process them for security analytics. Hence, you
  should setup your kubelet nodes with resolvable FQDNs and avoid overriding the
  hostnames with IPs."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://github.com/kubernetes/kubernetes/issues/22063'

  describe "[#{gcp_project_id}] This setting is not configurable via the Kubelet config file, this test is Not Applicable." do
    skip "[#{gcp_project_id}] This setting is not configurable via the Kubelet config file."
  end

end

# 3.2.9
sub_control_id = "#{control_id}.9"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the --event-qps argument is set to 0 or a level which
  ensures appropriate event capture"

  desc 'Security relevant information should be captured. The --event-qps flag on the Kubelet can
  be used to limit the rate at which events are gathered. Setting this too low could result in
  relevant events not being logged, however the unlimited setting of 0 could result in a denial
  of service on the kubelet.'
  desc 'rationale', "It is important to capture all events and not restrict event creation. Events are an important
  source of security information and analytics that ensure that your environment is
  consistently monitored using the event data."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://github.com/kubernetes/kubernetes/blob/master/pkg/kubelet/apis/kubeletconfig/v1beta1/types.go'

  describe "[#{gcp_project_id}] Kubelet config file #{kubelet_config_file_path}" do
    subject { yaml(kubelet_config_file_path) }
    its('eventRecordQPS') { should cmp event_record_qps }
  end

end

# 3.2.10
sub_control_id = "#{control_id}.9"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the --tls-cert-file and --tls-private-key-file arguments
  are set as appropriate"

  desc 'Setup TLS connection on the Kubelets.'
  desc 'rationale', "Kubelet communication contains sensitive parameters that should remain encrypted in
  transit. Configure the Kubelets to serve only HTTPS traffic."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'http://rootsquash.com/2016/05/10/securing-the-kubernetes-api/'

  describe "[#{gcp_project_id}] Kubelet config file #{kubelet_config_file_path}" do
    subject { yaml(kubelet_config_file_path) }
    its('tlsCertFile') { should cmp tls_cert_file }
    its('tlsPrivateKeyFile') { should cmp tls_private_key_file }
  end

end
