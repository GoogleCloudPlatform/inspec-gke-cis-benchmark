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

  kubelet_config_file_path = command('ps -ef | grep kubelet | grep -e "--config " | sed "s/^.*\(--config .* \).*$/\1/"  | awk \'{print $2}\'').stdout.split("\n").first
  kubelet_config_file = yaml(kubelet_config_file_path)
  anonymous_auth_config = kubelet_config_file.authentication["anonymous"]["enabled"]

  describe "[#{gcp_project_id}] Kubelet config file #{kubelet_config_file_path}" do
    subject { anonymous_auth_config }
    it 'should have anonymous authentication disabled' do
      expect(subject).to cmp "false"
    end
  end

end
