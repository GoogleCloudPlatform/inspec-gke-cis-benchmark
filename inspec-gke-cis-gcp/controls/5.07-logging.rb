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

title 'Ensure Stackdriver Kubernetes Logging and Monitoring is Enabled'

gcp_project_id = input('gcp_project_id')
gcp_gke_locations = input('gcp_gke_locations')
cis_version = input('cis_version')
cis_url = input('cis_url')
control_id = '5.7.1'
control_abbrev = 'logging'

gke_clusters = GKECache(project: gcp_project_id, gke_locations: gcp_gke_locations).gke_clusters_cache

if gke_clusters.nil? || gke_clusters.count.zero?
  control "cis-gke-#{control_id}-#{control_abbrev}" do
    title "[#{control_abbrev.upcase}] Logging"
    impact 'none'
    describe "[#{gcp_project_id}] does not have any GKE clusters, this section of tests is Not Applicable." do
      skip "[#{gcp_project_id}] does not have any GKE clusters."
    end
  end
else

  # 5.7.1
  control "cis-gke-#{control_id}-#{control_abbrev}" do
    impact 'low'

    title "[#{control_abbrev.upcase}] Ensure Stackdriver Kubernetes Logging and Monitoring is Enabled"

    desc 'Send logs and metrics to a remote aggregator to mitigate the risk of local tampering in the event of a breach.'
    desc 'rationale', "Exporting logs and metrics to a dedicated, persistent datastore such as Stackdriver ensures availability of audit data following a cluster security event, and provides a central location for analysis of log and metric data collated from multiple sources.

  Currently, there are two mutually exclusive variants of Stackdriver available for use with GKE clusters: Legacy Stackdriver Support and Stackdriver Kubernetes Engine Monitoring Support.

  Although Stackdriver Kubernetes Engine Monitoring is the preferred option, starting with GKE versions 1.12.7 and 1.13, Legacy Stackdriver is the default option up through GKE version 1.13. The use of either of these services is sufficient to pass the benchmark recommendation.

  However, note that as Legacy Stackdriver Support is not getting any improvements and lacks features present in Stackdriver Kubernetes Engine Monitoring, Legacy Stackdriver Support may be deprecated in favour of Stackdriver Kubernetes Engine Monitoring Support in future versions of this benchmark."

    tag cis_scored: true
    tag cis_level: 1
    tag cis_gke: control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-container-cluster'
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/how-to/logging'
    ref 'GCP Docs', url: 'https://cloud.google.com/logging/docs/basic-concepts'

    # if gke_clusters.members.nil? || gke_clusters.members.count.zero?

    gke_clusters.each do |gke_cluster|
      describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}" do
        subject { google_container_cluster(project: gcp_project_id, location: gke_cluster[:location], name: gke_cluster[:cluster_name]) }
        its('logging_service') { should match(/^logging.googleapis.com/) }
        its('monitoring_service') { should match(/^monitoring.googleapis.com/) }
      end
    end
  end
end
