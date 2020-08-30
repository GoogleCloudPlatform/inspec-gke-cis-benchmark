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

title 'Ensure Image Vulnerability Scanning using GCR Container Analysis or a third party provider'

gcp_project_id = input('gcp_project_id')
cis_version = input('cis_version')
cis_url = input('cis_url')
control_id = '5.1.1'
control_abbrev = 'container-registry'

control "cis-gke-#{control_id}-#{control_abbrev}" do
  impact 'none'

  title "[#{control_abbrev.upcase}] Ensure Image Vulnerability Scanning using GCR Container Analysis or a third party provider"

  desc 'Scan images stored in Google Container Registry (GCR) for vulnerabilities.'
  desc 'rationale', "Vulnerabilities in software packages can be exploited by hackers or malicious users to 
  obtain unauthorized access to local cloud resources. GCR Container Analysis and other 
  third party products allow images stored in GCR to be scanned for known vulnerabilities."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://cloud.google.com/container-registry/docs/container-analysis'

  describe "[#{gcp_project_id}]"  do
    subject { google_project_service(project: gcp_project_id, name: 'containerscanning.googleapis.com') }
    its('state') { should cmp "ENABLED" }
  end
end
