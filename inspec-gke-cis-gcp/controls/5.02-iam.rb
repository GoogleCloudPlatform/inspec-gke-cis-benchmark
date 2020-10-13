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

title 'Ensure GKE clusters are not running using the Compute Engine default service account'

gcp_project_id = input('gcp_project_id')
gcp_gke_locations = input('gcp_gke_locations')
cis_version = input('cis_version')
cis_url = input('cis_url')
control_id = '5.2.1'
control_abbrev = 'iam'

gke_clusters = GKECache(project: gcp_project_id, gke_locations: gcp_gke_locations).gke_clusters_cache

control "cis-gke-#{control_id}-#{control_abbrev}" do
  impact 'medium'

  title "[#{control_abbrev.upcase}] Ensure GKE clusters are not running using the Compute Engine default service account"

  desc 'Create and use minimally privileged Service accounts to run GKE cluster nodes instead of using the Compute Engine default Service account. Unnecessary permissions could be abused in the case of a node compromise.'
  desc 'rationale', "A GCP service account (as distinct from a Kubernetes ServiceAccount) is an identity that an instance or an application can use to run GCP API requests on your behalf. This identity is used to identify virtual machine instances to other Google Cloud Platform services. By default, Kubernetes Engine nodes use the Compute Engine default service account. This account has broad access by default, as defined by access scopes, making it useful to a wide variety of applications on the VM, but it has more permissions than are required to run your Kubernetes Engine cluster.

You should create and use a minimally privileged service account to run your Kubernetes Engine cluster instead of using the Compute Engine default service account, and create separate service accounts for each Kubernetes Workload (See Recommendation 6.2.2).

Kubernetes Engine requires, at a minimum, the node service account to have the monitoring.viewer, monitoring.metricWriter, and logging.logWriter roles. Additional roles may need to be added for the nodes to pull images from GCR."

  tag cis_scored: true
  tag cis_level: 1
  tag cis_gke: control_id.to_s
  tag cis_version: cis_version.to_s
  tag project: gcp_project_id.to_s

  ref 'CIS Benchmark', url: cis_url.to_s
  ref 'GCP Docs', url: 'https://cloud.google.com/compute/docs/access/service-accounts#compute_engine_default_service_account'

  if gke_clusters.nil? || gke_clusters.count.zero?
    impact 'none'
    describe "[#{gcp_project_id}] does not have any GKE clusters, this test is Not Applicable." do
      skip "[#{gcp_project_id}] does not have any GKE clusters."
    end
  else
    gke_clusters.each do |gke_cluster|
      google_container_node_pools(project: gcp_project_id, location: gke_cluster[:location], cluster_name: gke_cluster[:cluster_name]).node_pool_names.each do |nodepoolname|
        describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}/#{nodepoolname}" do
          subject { google_container_node_pool(project: gcp_project_id, location: gke_cluster[:location], cluster_name: gke_cluster[:cluster_name], nodepool_name: nodepoolname) }
          its('config.service_account') { should_not cmp 'default' }
        end
      end
    end
  end
end
