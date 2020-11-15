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

title 'Other Cluster Configurations'

gcp_project_id = input('gcp_project_id')
gcp_gke_locations = input('gcp_gke_locations')
cis_version = input('cis_version')
cis_url = input('cis_url')
control_id = '5.10'
control_abbrev = 'other'

gke_clusters = GKECache(project: gcp_project_id, gke_locations: gcp_gke_locations).gke_clusters_cache

if gke_clusters.nil? || gke_clusters.count.zero?
  control "cis-gke-#{control_id}-#{control_abbrev}" do
    title "[#{control_abbrev.upcase}] Other Cluster Configurations"
    impact 'none'
    describe "[#{gcp_project_id}] does not have any GKE clusters, this section of tests is Not Applicable." do
      skip "[#{gcp_project_id}] does not have any GKE clusters."
    end
  end
else

  # 5.10.1
  sub_control_id = "#{control_id}.1"
  control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
    impact 'medium'

    title "[#{control_abbrev.upcase}] Ensure Kubernetes Web UI is Disabled"

    desc 'The Kubernetes Web UI (Dashboard) has been a historical source of vulnerability and should only be deployed when necessary.'
    desc 'rationale', "You should disable the Kubernetes Web UI (Dashboard) when running on Kubernetes Engine. The Kubernetes Web UI is backed by a highly privileged Kubernetes Service Account.

  The Google Cloud Console provides all the required functionality of the Kubernetes Web UI and leverages Cloud IAM to restrict user access to sensitive cluster controls and settings."

    tag cis_scored: true
    tag cis_level: 1
    tag cis_gke: sub_control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#disable_kubernetes_dashboard'

    gke_clusters.each do |gke_cluster|
      describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}" do
        subject { google_container_cluster(project: gcp_project_id, location: gke_cluster[:location], name: gke_cluster[:cluster_name]) }
        # TODO: Inspec-GCP support needed
        its('addons_config.kubernetes_dashboard.disabled') { should cmp true }
      end
    end
  end

  # 5.10.2
  sub_control_id = "#{control_id}.2"
  control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
    impact 'medium'

    title "[#{control_abbrev.upcase}] Ensure that Alpha clusters are not used for production workloads"

    desc 'Alpha clusters are not covered by an SLA and are not production-ready.'
    desc 'rationale', "Alpha clusters are designed for early adopters to experiment with workloads that take
    advantage of new features before those features are production-ready. They have all
    Kubernetes API features enabled, but are not covered by the GKE SLA, do not receive
    security updates, have node auto-upgrade and node auto-repair disabled, and cannot be
    upgraded. They are also automatically deleted after 30 days."

    tag cis_scored: true
    tag cis_level: 1
    tag cis_gke: sub_control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/concepts/alpha-clusters'

    gke_clusters.each do |gke_cluster|
      describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}" do
        subject { google_container_cluster(project: gcp_project_id, location: gke_cluster[:location], name: gke_cluster[:cluster_name]) }
        its('enable_kubernetes_alpha') { should eq nil }
      end
    end
  end

  # 5.10.3
  sub_control_id = "#{control_id}.3"
  control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
    impact 'medium'

    title "[#{control_abbrev.upcase}] Ensure Pod Security Policy is Enabled and set as appropriate"

    desc 'Pod Security Policy should be used to prevent privileged containers where possible and enforce namespace and workload configurations.'
    desc 'rationale', "A Pod Security Policy is a cluster-level resource that controls security sensitive aspects of the pod specification. A PodSecurityPolicy object defines a set of conditions that a pod must run with in order to be accepted into the system, as well as defaults for the related fields. When a request to create or update a Pod does not meet the conditions in the Pod Security Policy, that request is rejected and an error is returned. The Pod Security Policy admission controller validates requests against available Pod Security Policies.

  PodSecurityPolicies specify a list of restrictions, requirements, and defaults for Pods created under the policy. See further details on recommended policies in Recommendation section 5.2."

    tag cis_scored: false
    tag cis_level: 1
    tag cis_gke: sub_control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies'
    ref 'GCP Docs', url: 'https://kubernetes.io/docs/concepts/policy/pod-security-policy'

    gke_clusters.each do |gke_cluster|
      describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}" do
        subject { google_container_cluster(project: gcp_project_id, location: gke_cluster[:location], name: gke_cluster[:cluster_name], beta: true) }
        # TODO: Inspec-GCP support
        its('pod_security_policy_config.enabled') { should cmp true }
      end
    end
  end
  # 5.10.5
  sub_control_id = "#{control_id}.5"
  control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
    impact 'medium'

    title "[#{control_abbrev.upcase}] Ensure use of Binary Authorization"

    desc 'Binary Authorization helps to protect supply-chain security by only allowing images with verifiable cryptographically signed metadata into the cluster.'
    desc 'rationale', "Binary Authorization provides software supply-chain security for images that you deploy to GKE from Google Container Registry (GCR) or another container image registry.
    Binary Authorization requires images to be signed by trusted authorities during the development process. These signatures are then validated at deployment time. By
    enforcing validation, you can gain tighter control over your container environment by ensuring only verified images are integrated into the build-and-release process."

    tag cis_scored: true
    tag cis_level: 1
    tag cis_gke: sub_control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/binary-authorization/'

    gke_clusters.each do |gke_cluster|
      describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}" do
        subject { google_container_cluster(project: gcp_project_id, location: gke_cluster[:location], name: gke_cluster[:cluster_name]) }
        its('binary_authorization.enabled') { should cmp true }
      end
    end
  end
end
