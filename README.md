# GKE CIS 1.1.0 Benchmark Inspec Profile

This repository holds the [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine) [Center for Internet Security (CIS)](https://www.cisecurity.org) [version 1.1 Benchmark](https://www.cisecurity.org/benchmark/kubernetes/).

## Required Disclaimer

This is not an officially supported Google product. This code is intended to help users assess their security posture on the GKE against the CIS Benchmark. This code is not certified by CIS.

## Coverage

The benchmark contains of three [Inspec](https://www.inspec.io/) profiles which can be found in the subdirectories [inspec-gke-cis-gcp](inspec-gke-cis-gcp), [inspec-gke-cis-k8s](inspec-gke-cis-k8s) and [inspec-gke-cis-ssh](inspec-gke-cis-ssh). The profiles are separated, since each profile needs to run against a different target (`-t`) option when running `inspec exec`. Targets which are used:
 * inspec-gke-cis-gcp uses [inspec-gcp](https://github.com/inspec/inspec-gcp)
 * inspec-gke-cis-k8s uses [inspec-k8s](https://github.com/bgeesaman/inspec-k8s)
 * inspec-gke-cis-ssh uses the SSH protocol for remote access (requires root privileges).

A wrapper script `run_profiles.sh` is provided in the root directory of the repository which executes all profiles sequentially and stores reports in a dedicated folder `/reports`. Note, that you need to configure access via the [Identity-Aware Proxy (IAP)](https://cloud.google.com/iap/docs/enabling-kubernetes-howto) to cluster nodes for this script to run successfully.

## Prerequisites
* Configure access via the [Identity-Aware Proxy (IAP)](https://cloud.google.com/iap/docs/enabling-kubernetes-howto) to cluster nodes for the inspec-gke-cis-ssh profile to run successfully
* Follow the setup steps for inspec-k8s as explained [here](https://github.com/bgeesaman/train-kubernetes#installation)

### CLI Example (Cloud Shell)

```
# install inspec (later version might work but not tested)
$ gem install inspec-bin -v 4.41.2 --no-document --quiet

# clone the Git Repo
$ git clone https://github.com/GoogleCloudPlatform/inspec-gke-cis-benchmark.git
$ cd inspec-gke-cis-benchmark

# Write an inputs file, see basic example below
$ cat <<EOF > inputs.yml
gcp_project_id: "<YOUR PROJECT ID>"
gcp_gke_locations:
 - 'us-central1-c'
gce_zones:
 - 'us-central1'
 - 'us-central1-c'
EOF

# Connect to GKE Cluster (getting credentials in ~/.kubeconfig, validate using kubectl)
$ gcloud container clusters get-credentials <cluster name> \
  --zone <zone> --project <YOUR PROJECT ID>

# install inspec-k8s and relevant gems (needs to run in directory of Gemfile)
# (refer to the inspec-k8s docs for details and troubleshooting)
$ bundle install

# install InSpec plugin train-kubernetes
$ inspec plugin install train-kubernetes

# Add the host you are running from to the master-authorized-networks to allow access to Private K8S Clusters
$ gcloud container clusters update <cluster name> \
  --zone <zone> \
  --enable-master-authorized-networks \
  --master-authorized-networks <your host's IP address>/32


```

```
# make sure you're authenticated to GCP
$ gcloud auth list

# acquire credentials to use with Application Default Credentials
$ gcloud auth application-default login

```

```
# Create a file inputs.yml which contains the required and optional inputs to the profiles in the subdirectories
$ ./run_profiles.sh -c <cluster name> -u <ssh user> -k <keyfile path> -z <cluster zone> -i inputs.yml
```

### Profile Inputs (combined across all profiles)

* **gcp_project_id** - (Default: "", type: string) - The target GCP Project that must be specified.
* **gcp_gke_locations** - (Default: "", type: array) - The list of regions and/or zone names where GKE clusters are running. An empty array searches all locations
* **gce_zones** - (Default: "", type: array) - The list of zone names where GCE instances are running. An empty array searches all locations.
* **registry_storage_admin_list** - (Default: "", type: array) - The allowed list of Storage Admins on Registry image bucket
* **registry_storage_object_admin_list** - (Default: "", type: array) - The allowed list of Storage Object Admins on Registry image bucket
* **registry_storage_object_creator_list** - (Default: "", type: array) - The allowed list of Storage Object Admins on Registry image bucket
* **registry_storage_object_creator_list** - (Default: "", type: array) - The allowed list of Storage Object Creators on Registry image bucket
* **registry_storage_legacy_bucket_owner_list** - (Default: "", type: array) - The allowed list of Storage Legacy Bucket Owners on Registry image bucket
* **registry_storage_legacy_bucket_writer_list** - (Default: "", type: array) - The allowed list of Storage Legacy Bucket Writers on Registry image bucket
* **registry_storage_legacy_object_owner_list** - (Default: "", type: array) - The allowed list of Storage Legacy Object Owners on Registry image bucket
* **client_ca_file_path** - (Default: "/etc/srv/kubernetes/pki/ca-certificates.crt", type: string) - Path to the client ca file used in Kubelet config
* **event_record_qps** - (Default: "0", type: string) - --event-qps flag of Kubelet config (see control 3.2.9)
* **tls_cert_file** - (Default: "", type: string) - Location of the certificate file to use to identify the Kubelet
* **tls_private_key_file** - (Default: "", type: string) - Location of the corresponding private key file to use to identify the Kubelet

### Cloud Shell Walkthrough

Use this Cloud Shell walkthrough for a hands-on example.

[![Open this project in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/inspec-gke-cis-benchmark&page=editor&tutorial=walkthrough.md)

### Required Permissions

The following permissions are required to run the CIS benchmark profile on project level:

* compute.regions.list
* compute.zones.list
* container.clusters.get
* container.clusters.list
* serviceusage.services.get
* storage.buckets.get
* storage.buckets.getIamPolicy
