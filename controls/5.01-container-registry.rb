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
control_id = '5.1'
control_abbrev = 'container-registry'

registry_storage_admin_list = input('registry_storage_admin_list')
registry_storage_object_admin_list = input('registry_storage_object_admin_list')
registry_storage_object_creator_list = input('registry_storage_object_creator_list')
registry_storage_legacy_bucket_owner_list = input('registry_storage_legacy_bucket_owner_list')
registry_storage_legacy_bucket_writer_list = input('registry_storage_legacy_bucket_writer_list')
registry_storage_legacy_object_owner_list = input('registry_storage_legacy_object_owner_list')

# 5.1.1
sub_control_id = "#{control_id}.1"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'none'

  title "[#{control_abbrev.upcase}] Ensure Image Vulnerability Scanning using GCR Container Analysis or a third party provider"

  desc 'Scan images stored in Google Container Registry (GCR) for vulnerabilities.'
  desc 'rationale', "Vulnerabilities in software packages can be exploited by hackers or malicious users to
  obtain unauthorized access to local cloud resources. GCR Container Analysis and other
  third party products allow images stored in GCR to be scanned for known vulnerabilities."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://cloud.google.com/container-registry/docs/container-analysis'

  if google_project_service(project: gcp_project_id, name: 'containerregistry.googleapis.com').state == 'DISABLED'
    impact 'none'
    describe "[#{gcp_project_id}] This project does not have the Google Container Registry Service enabled, this test is Not Applicable." do
      skip "[#{gcp_project_id}] This project does not have the Google Container Registry Service enabled."
    end
  else
    describe "[#{gcp_project_id}]" do
      subject { google_project_service(project: gcp_project_id, name: 'containerscanning.googleapis.com') }
      its('state') { should cmp 'ENABLED' }
    end
  end
end

# 5.1.2
sub_control_id = "#{control_id}.2"
control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Minimize user access to GCR"

  desc 'Restrict user access to GCR, limiting interaction with build images to only authorized
  personnel and service accounts.'
  desc 'rationale', "Weak access control to GCR may allow malicious users to replace built images with
  vulnerable or backdoored containers."

  tag cis_scored: false
  tag cis_level: 1
  tag cis_gke: sub_control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://cloud.google.com/container-registry/docs/access-control'

  # Check if storage bucket exists
  if google_storage_bucket(name: "artifacts.#{gcp_project_id}.appspot.com").name.nil?
    impact 'none'
    describe "[#{gcp_project_id}] does not have a storage bucket for Google Container Registry Images, this test is Not Applicable." do
      skip "[#{gcp_project_id}] does not have a storage bucket for Google Container Registry Images."
    end
  else
    bucket_iam_policy = google_storage_bucket_iam_policy(bucket: "artifacts.#{gcp_project_id}.appspot.com")
    bucket_iam_policy.bindings.each do |iam_policy|
      case iam_policy.role
      when 'roles/storage.admin'
        role_member_list = registry_storage_admin_list
      when 'roles/storage.objectAdmin'
        role_member_list = registry_storage_object_admin_list
      when 'roles/storage.objectCreator'
        role_member_list = registry_storage_object_creator_list
      when 'roles/storage.legacyBucketOwner'
        role_member_list = registry_storage_legacy_bucket_owner_list
      when 'roles/storage.legacyBucketWriter'
        role_member_list = registry_storage_legacy_bucket_writer_list
      when 'roles/storage.legacyObjectOwner'
        role_member_list = registry_storage_legacy_object_owner_list
      else
        next
      end
      describe "[#{gcp_project_id}] Members for #{iam_policy.role} in Storage Bucket artifacts.#{gcp_project_id}.appspot.com" do
        subject { google_storage_bucket_iam_binding(bucket: "artifacts.#{gcp_project_id}.appspot.com", role: iam_policy.role) }
        it 'match the allow list' do
          expect(subject.members).to cmp(role_member_list)
        end
      end
    end
  end
end
