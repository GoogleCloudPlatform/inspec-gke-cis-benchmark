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

title 'Node Configuration and Maintenance'

gcp_project_id = input('gcp_project_id')
gcp_gke_locations = input('gcp_gke_locations')
cis_version = input('cis_version')
cis_url = input('cis_url')
control_id = '5.5'
control_abbrev = 'nodes'

gke_clusters = GKECache(project: gcp_project_id, gke_locations: gcp_gke_locations).gke_clusters_cache

if gke_clusters.nil? || gke_clusters.count.zero?
  control "cis-gke-#{control_id}-#{control_abbrev}" do
    title "[#{control_abbrev.upcase}] Node Configuration and Maintenance"
    impact 'none'
    describe "[#{gcp_project_id}] does not have any GKE clusters, this section of tests is Not Applicable." do
      skip "[#{gcp_project_id}] does not have any GKE clusters."
    end
  end
else

  # 5.5.1
  sub_control_id = "#{control_id}.1"
  control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
    impact 'low'

    title "[#{control_abbrev.upcase}] Ensure Container-Optimized OS (COS) is used for GKE node images"

    desc "Use Container-Optimized OS (COS) as a managed, optimized and hardened base OS that limits the host's attack surface."
    desc 'rationale', "COS is an operating system image for Compute Engine VMs optimized for running containers. With COS, you can bring up your containers on Google Cloud Platform quickly, efficiently, and securely.

  Using COS as the node image provides the following benefits:

  - Run containers out of the box: COS instances come pre-installed with the container runtime and cloud-init. With a COS instance, you can bring up your container at the same time you create your VM, with no on-host setup required.
  - Smaller attack surface: COS has a smaller footprint, reducing your instance's potential attack surface.
  - Locked-down by default: COS instances include a locked-down firewall and other security settings by default."

    tag cis_scored: true
    tag cis_level: 1
    tag cis_gke: sub_control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/concepts/node-images'
    ref 'GCP Docs', url: 'https://cloud.google.com/container-optimized-os/docs/'

    gke_clusters.each do |gke_cluster|
      google_container_node_pools(project: gcp_project_id, location: gke_cluster[:location], cluster_name: gke_cluster[:cluster_name]).node_pool_names.each do |nodepoolname|
        describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}, Node Pool: #{nodepoolname}" do
          subject { google_container_node_pool(project: gcp_project_id, location: gke_cluster[:location], cluster_name: gke_cluster[:cluster_name], nodepool_name: nodepoolname) }
          its('config.image_type') { should match(/COS/) }
        end
      end
    end
  end

  # 5.5.2
  sub_control_id = "#{control_id}.2"
  control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
    impact 'medium'

    title "[#{control_abbrev.upcase}] Ensure Node Auto-Repair is enabled for GKE nodes"

    desc 'Nodes in a degraded state are an unknown quantity and so may pose a security risk.'
    desc 'rationale', "Kubernetes Engine's node auto-repair feature helps you keep the nodes in your cluster in a healthy, running state. When enabled, Kubernetes Engine makes periodic checks on the health state of each node in your cluster. If a node fails consecutive health checks over an extended time period, Kubernetes Engine initiates a repair process for that node."

    tag cis_scored: true
    tag cis_level: 1
    tag cis_gke: sub_control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/concepts/node-auto-repair'

    gke_clusters.each do |gke_cluster|
      google_container_node_pools(project: gcp_project_id, location: gke_cluster[:location], cluster_name: gke_cluster[:cluster_name]).node_pool_names.each do |nodepoolname|
        describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}, Node Pool: #{nodepoolname}" do
          subject { google_container_node_pool(project: gcp_project_id, location: gke_cluster[:location], cluster_name: gke_cluster[:cluster_name], nodepool_name: nodepoolname) }
          its('management.auto_repair') { should cmp true }
        end
      end
    end
  end

  # 5.5.3
  sub_control_id = "#{control_id}.3"
  control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
    impact 'low'

    title "[#{control_abbrev.upcase}] Ensure Node Auto-Upgrade is enabled for GKE nodes"

    desc 'Node auto-upgrade keeps nodes at the current Kubernetes and OS security patch level to mitigate known vulnerabilities.'
    desc 'rationale', "Node auto-upgrade helps you keep the nodes in your cluster or Node pool up to date with the latest stable patch version of Kubernetes as well as the underlying node operating system. Node auto-upgrade uses the same update mechanism as manual node upgrades.

  Node pools with node auto-upgrade enabled are automatically scheduled for upgrades when a new stable Kubernetes version becomes available. When the upgrade is performed, the Node pool is upgraded to match the current cluster master version. From a security perspective, this has the benefit of applying security updates automatically to the Kubernetes Engine when security fixes are released."

    tag cis_scored: true
    tag cis_level: 1
    tag cis_gke: sub_control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/concepts/node-auto-upgrades'

    gke_clusters.each do |gke_cluster|
      google_container_node_pools(project: gcp_project_id, location: gke_cluster[:location], cluster_name: gke_cluster[:cluster_name]).node_pool_names.each do |nodepoolname|
        describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}, Node Pool: #{nodepoolname}" do
          subject { google_container_node_pool(project: gcp_project_id, location: gke_cluster[:location], cluster_name: gke_cluster[:cluster_name], nodepool_name: nodepoolname) }
          its('management.auto_upgrade') { should cmp true }
        end
      end
    end
  end
end
