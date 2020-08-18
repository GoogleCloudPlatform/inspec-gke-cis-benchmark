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

title 'Authentication and Authorization'

gcp_project_id = input('gcp_project_id')
gcp_gke_locations = input('gcp_gke_locations')
cis_version = input('cis_version')
cis_url = input('cis_url')
control_id = '5.8'
control_abbrev = 'authn-authz'

gke_clusters = GKECache(project: gcp_project_id, gke_locations: gcp_gke_locations).gke_clusters_cache

if gke_clusters.nil? || gke_clusters.count.zero?
  control "cis-gke-#{control_id}-#{control_abbrev}" do
    title "[#{control_abbrev.upcase}] Authentication and Authorization"
    impact 'none'
    describe "[#{gcp_project_id}] does not have any GKE clusters, this section of tests is Not Applicable." do
      skip "[#{gcp_project_id}] does not have any GKE clusters."
    end
  end
else

  # 5.8.1
  sub_control_id = "#{control_id}.1"
  control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
    impact 'medium'

    title "[#{control_abbrev.upcase}] Ensure Basic Authentication using static passwords is Disabled"

    desc 'Disable Basic Authentication (basic auth) for API server authentication as it uses static passwords which need to be rotated.'
    desc 'rationale', "Basic Authentication allows a user to authenticate to a Kubernetes cluster with a username and static password which is stored in plaintext (without any encryption). Disabling Basic Authentication will prevent attacks like brute force and credential stuffing. It is recommended to disable Basic Authentication and instead use another authentication method such as OpenID Connect.

  GKE manages authentication via gcloud using the OpenID Connect token method, setting up the Kubernetes configuration, getting an access token, and keeping it up to date. This means Basic Authentication using static passwords and Client Certificate authentication, which both require additional management overhead of key management and rotation, are not necessary and should be disabled.

  When Basic Authentication is disabled, you will still be able to authenticate to the cluster with other authentication methods, such as OpenID Connect tokens. See also Recommendation 5.8.2 to disable authentication using Client Certificates."

    tag cis_scored: true
    tag cis_level: 1
    tag cis_gke: sub_control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/how-to/iam-integration'

    gke_clusters.each do |gke_cluster|
      describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}" do
        subject { google_container_cluster(project: gcp_project_id, location: gke_cluster[:location], name: gke_cluster[:cluster_name]) }
        its('master_auth.username') { should cmp nil }
        # master_auth.password should also be nil, but we don't want to put that sensitive info in the output
      end
    end
  end

  # 5.8.2
  sub_control_id = "#{control_id}.2"
  control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
    impact 'medium'

    title "[#{control_abbrev.upcase}] Ensure authentication using Client Certificates is Disabled"

    desc 'Disable Client Certificates, which require certificate rotation, for authentication. Instead, use another authentication method like OpenID Connect.'
    desc 'rationale', "With Client Certificate authentication, a client presents a certificate that the API server verifies with the specified Certificate Authority. In GKE, Client Certificates are signed by the cluster root Certificate Authority. When retrieved, the Client Certificate is only base64 encoded and not encrypted.

  GKE manages authentication via gcloud for you using the OpenID Connect token method, setting up the Kubernetes configuration, getting an access token, and keeping it up to date. This means Basic Authentication using static passwords and Client Certificate authentication, which both require additional management overhead of key management and rotation, are not necessary and should be disabled.

  When Client Certificate authentication is disabled, you will still be able to authenticate to the cluster with other authentication methods, such as OpenID Connect tokens. See also Recommendation 6.8.1 to disable authentication using static passwords, known as Basic Authentication."

    tag cis_scored: true
    tag cis_level: 1
    tag cis_gke: sub_control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your- cluster#restrict_authn_methods'

    gke_clusters.each do |gke_cluster|
      describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}", :sensitive do
        subject { google_container_cluster(project: gcp_project_id, location: gke_cluster[:location], name: gke_cluster[:cluster_name]) }
        its('master_auth.client_certificate') { should cmp nil }
      end
    end
  end

  # 5.8.4
  sub_control_id = "#{control_id}.4"
  control "cis-gke-#{sub_control_id}-#{control_abbrev}" do
    impact 'medium'

    title "[#{control_abbrev.upcase}] Ensure Legacy Authorization (ABAC) is Disabled"

    desc 'Legacy Authorization, also known as Attribute-Based Access Control (ABAC) has been superseded by Role-Based Access Control (RBAC) and is not under active development. RBAC is the recommended way to manage permissions in Kubernetes.'
    desc 'rationale', 'In Kubernetes, RBAC is used to grant permissions to resources at the cluster and namespace level. RBAC allows you to define roles with rules containing a set of permissions, whilst the legacy authorizer (ABAC) in Kubernetes Engine grants broad, statically defined permissions. As RBAC provides significant security advantages over ABAC, it is recommended option for access control. Where possible, legacy authorization must be disabled for GKE clusters.'

    tag cis_scored: true
    tag cis_level: 1
    tag cis_gke: sub_control_id.to_s
    tag cis_version: cis_version.to_s
    tag project: gcp_project_id.to_s

    ref 'CIS Benchmark', url: cis_url.to_s
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control'
    ref 'GCP Docs', url: 'https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your- cluster#leave_abac_disabled_default_for_110'

    gke_clusters.each do |gke_cluster|
      describe "[#{gcp_project_id}] Cluster #{gke_cluster[:location]}/#{gke_cluster[:cluster_name]}" do
        subject { google_container_cluster(project: gcp_project_id, location: gke_cluster[:location], name: gke_cluster[:cluster_name]) }
        its('legacy_abac.enabled') { should cmp nil }
      end
    end
  end
end
