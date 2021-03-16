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

title 'Cloud Key Management Service'

gcp_project_id = input('gcp_project_id')
gcp_gke_locations = input('gcp_gke_locations')
cis_version = input('cis_version')
cis_url = input('cis_url')
control_id = '6.3'
control_abbrev = 'kms'

gke_clusters = GKECache(project: gcp_project_id, gke_locations: gcp_gke_locations).gke_clusters_cache

if gke_clusters.nil? || gke_clusters.count.zero?
  control "cis-gke-#{control_id}-#{control_abbrev}" do
    title "[#{control_abbrev.upcase}] Cloud Key Management Service"
    impact 'none'
    describe "[#{gcp_project_id}] does not have any GKE clusters, this section of tests is Not Applicable." do
      skip "[#{gcp_project_id}] does not have any GKE clusters."
    end
  end
else

  # 6.3.1
  sub_control_id = "#{control_id}.1"
  control "cis-gke-#{control_id}-#{control_abbrev}" do
    impact 'medium'

    title "[#{control_abbrev.upcase}] Ensure Kubernetes Secrets are encrypted using keys managed in
    Cloud KMS"

    desc "Encrypt Kubernetes secrets, stored in etcd, at the application-layer using a customer-
    managed key in Cloud KMS."
    desc 'rationale', "By default, GKE encrypts customer content stored at rest, including Secrets. GKE handles
    and manages this default encryption for you without any additional action on your part.
    Application-layer Secrets Encryption provides an additional layer of security for sensitive
    data, such as user defined Secrets and Secrets required for the operation of the cluster,
    such as service account keys, which are all stored in etcd.
    Using this functionality, you can use a key, that you manage in Cloud KMS, to encrypt data
    at the application layer. This protects against attackers in the event that they manage to
    gain access to etcd."

    tag cis_scored: true
    tag cis_level: 1
    tag cis_gke: sub_control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets'

    gke_clusters.each do |gke_cluster|
      describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}" do
        subject { google_container_cluster(project: gcp_project_id, location: gke_cluster[:location], name: gke_cluster[:cluster_name]) }
        its('database_encryption.key_name') { should_not eq nil }
        its('database_encryption.state') { should cmp 'ENCRYPTED' }
      end
    end
  end
end
