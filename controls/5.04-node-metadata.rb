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

title 'Node Metadata'

gcp_project_id = input('gcp_project_id')
gcp_gke_locations = input('gcp_gke_locations')
cis_version = input('cis_version')
cis_url = input('cis_url')
control_id = '5.4'
control_abbrev = 'node-metadata'

gke_clusters = GKECache(project: gcp_project_id, gke_locations: gcp_gke_locations).gke_clusters_cache

if gke_clusters.nil? || gke_clusters.count.zero?
  control "cis-gke-#{control_id}-#{control_abbrev}" do
    title "[#{control_abbrev.upcase}] Node Metadata"
    impact 'none'
    describe "[#{gcp_project_id}] does not have any GKE clusters, this section of tests is Not Applicable." do
      skip "[#{gcp_project_id}] does not have any GKE clusters."
    end
  end
else

  # 5.4.1
  sub_control_id = "#{control_id}.1"
  control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
    impact 'medium'

    title "[#{control_abbrev.upcase}] Ensure legacy Compute Engine instance metadata APIs are Disabled"

    desc "Disable the legacy GCE instance metadata APIs for GKE nodes. Under some circumstances, these can be used from within a pod to extract the node's credentials."
    desc 'rationale', "The legacy GCE metadata endpoint allows simple HTTP requests to be made returning
    sensitive information. To prevent the enumeration of metadata endpoints and data
    exfiltration, the legacy metadata endpoint must be disabled.

    Without requiring a custom HTTP header when accessing the legacy GCE metadata
    endpoint, a flaw in an application that allows an attacker to trick the code into retrieving
    the contents of an attacker-specified web URL could provide a simple method for
    enumeration and potential credential exfiltration. By requiring a custom HTTP header, the
    attacker needs to exploit an application flaw that allows them to control the URL and also
    add custom headers in order to carry out this attack successfully."

    tag cis_scored: true
    tag cis_level: 1
    tag cis_gke: sub_control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/how-to/protecting-cluster-metadata#disable-legacy-apis'

    gke_clusters.each do |gke_cluster|
      google_container_node_pools(project: gcp_project_id, location: gke_cluster[:location], cluster_name: gke_cluster[:cluster_name]).node_pool_names.each do |nodepoolname|
        nodepool = google_container_node_pool(project: gcp_project_id, location: gke_cluster[:location], cluster_name: gke_cluster[:cluster_name], nodepool_name: nodepoolname)
        has_legacy_endpoints_disabled = nodepool.config.metadata['disable-legacy-endpoints']
        describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}, Node Pool: #{nodepoolname}" do
          subject { nodepool }
          it 'should have legacy endpoints disabled.' do
            expect(has_legacy_endpoints_disabled).to cmp 'true'
          end
        end
      end
    end
  end
end
