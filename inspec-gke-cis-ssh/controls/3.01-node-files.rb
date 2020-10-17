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
control_id = '3.1'
control_abbrev = 'worker-node-configuration-files'

# 3.1.1
sub_control_id = "#{control_id}.1"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the proxy kubeconfig file permissions are set to 644 or
  more restrictive"

  desc 'If kube-proxy is running, and if it is using a file-based kubeconfig file, ensure that the proxy
  kubeconfig file has permissions of 644 or more restrictive.'
  desc 'rationale', "The kube-proxy kubeconfig file controls various parameters of the kube-proxy service in
  the worker node. You should restrict its file permissions to maintain the integrity of the file.
  The file should be writable by only the administrators on the system.
  It is possible to run kube-proxy with the kubeconfig parameters configured as a
  Kubernetes ConfigMap instead of a file. In this case, there is no proxy kubeconfig file."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/admin/kube-proxy/'

  c = command('ps -ef | grep kube-proxy | grep -e "--kubeconfig=" | sed "s/^.*\(--kubeconfig=.* \).*$/\1/" | awk \'{print $1}\'').stdout.split('=')
  kube_proxy_config_file_path = c[1].split("\n").first
  
  file_permissions = command("stat -c %a #{kube_proxy_config_file_path}").stdout.to_i

  describe "[#{gcp_project_id}] File permissions of kube-proxy config file #{kube_proxy_config_file_path}" do
    subject { file_permissions }
    it 'should be 644 or more restrictive' do
      expect(subject).to be_in [644, 640, 600, 400, 444, 440]
    end
  end

end

# 3.1.2
sub_control_id = "#{control_id}.2"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the proxy kubeconfig file ownership is set to root:root"

  desc 'If kube-proxy is running, ensure that the file ownership of its kubeconfig file is set to
  root:root.'
  desc 'rationale', "The kubeconfig file for kube-proxy controls various parameters for the kube-proxy service
  in the worker node. You should set its file ownership to maintain the integrity of the file.
  The file should be owned by root:root."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/admin/kube-proxy/'

  c = command('ps -ef | grep kube-proxy | grep -e "--kubeconfig=" | sed "s/^.*\(--kubeconfig=.* \).*$/\1/" | awk \'{print $1}\'').stdout.split('=')
  kube_proxy_config_file_path = c[1].split("\n").first

  describe "[#{gcp_project_id}] Kube-proxy config file #{kube_proxy_config_file_path}" do
    subject { file(kube_proxy_config_file_path) }
    its('owner') { should cmp 'root' }
    its('group') { should cmp 'root' }
  end

end

# 3.1.3
sub_control_id = "#{control_id}.3"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the kubelet configuration file has permissions set to
  644 or more restrictive"

  desc 'If kube-proxy is running, ensure that the file ownership of its kubeconfig file is set to
  root:root.'
  desc 'rationale', "The kubeconfig file for kube-proxy controls various parameters for the kube-proxy service
  in the worker node. You should set its file ownership to maintain the integrity of the file.
  The file should be owned by root:root."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/tasks/administer-cluster/kubelet-config-file/'

  kubelet_config_file_path = command('ps -ef | grep kubelet | grep -e "--config " | sed "s/^.*\(--config .* \).*$/\1/"  | awk \'{print $2}\'').stdout.split("\n").first
  file_permissions = command("stat -c %a #{kubelet_config_file_path}").stdout.to_i

  describe "[#{gcp_project_id}] File permissions of kubelet config file #{kubelet_config_file_path}" do
    subject { file_permissions }
    it 'should be 644 or more restrictive' do
      expect(subject).to be_in [644, 640, 600, 400, 444, 440]
    end
  end

end

# 3.1.4
sub_control_id = "#{control_id}.4"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure that the kubelet configuration file ownership is set to root:root"

  desc 'Ensure that if the kubelet refers to a configuration file with the --config argument, that file
  is owned by root:root.'
  desc 'rationale', "The kubelet reads various parameters, including security settings, from a config file
  specified by the --config argument. If this file is specified you should restrict its file
  permissions to maintain the integrity of the file. The file should be owned by root:root."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://kubernetes.io/docs/tasks/administer-cluster/kubelet-config-file/'

  kubelet_config_file_path = command('ps -ef | grep kubelet | grep -e "--config " | sed "s/^.*\(--config .* \).*$/\1/"  | awk \'{print $2}\'').stdout.split("\n").first

  describe "[#{gcp_project_id}] Kubelet config file #{kubelet_config_file_path}" do
    subject { file(kubelet_config_file_path) }
    its('owner') { should cmp 'root' }
    its('group') { should cmp 'root' }
  end

end