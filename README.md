# GKE CIS 1.1.0 Benchmark Inspec Profile

This repository holds the [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine) [Center for Internet Security (CIS)](https://www.cisecurity.org) [version 1.1 Benchmark](https://www.cisecurity.org/benchmark/kubernetes/) [Inspec](https://www.inspec.io/) Profile.

## Required Disclaimer

This is not an officially supported Google product. This code is intended to help users assess their security posture on the GKE against the CIS Benchmark. This code is not certified by CIS.

## Coverage

This is an initial release, mainly consisting of ported controls from the CIS for GCP 1.0.0 Benchmark.

## Usage

### Profile Inputs (see `inspec.yml` file)

This profile uses InSpec Inputs to make the tests more flexible. You are able to provide inputs at runtime either via the `cli` or via `YAML files` to help the profile work best in your deployment.

**pro tip**: Do not change the inputs in the `inspec.yml` file directly, either:
a. update them via the cli
b. pass them in via a YAML file as shown in the `Example'

Further details can be found here: <https://docs.chef.io/inspec/inputs/>

- **gcp_project_id** - (Default: "", type: string) - The target GCP Project that must be specified.

### Cloud Shell Walkthrough

Use this Cloud Shell walkthrough for a hands-on example.

[![Open this project in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/inspec-gke-cis-benchmark&page=editor&tutorial=walkthrough.md)

### CLI Example

```
#install inspec
$ gem install inspec-bin --no-document --quiet
```

```
# make sure you're authenticated to GCP
$ gcloud auth list

# acquire credentials to use with Application Default Credentials
$ gcloud auth application-default login

```

```
# scan a project with this profile, replace <YOUR_PROJECT_ID> with your project ID
$ CHEF_LICENSE=accept-no-persist inspec exec https://github.com/GoogleCloudPlatform/inspec-gke-cis-benchmark.git -t gcp:// --input gcp_project_id=<YOUR_PROJECT_ID> --reporter cli json:myscan.json
...snip...
Profile Summary: 48 successful controls, 5 control failures, 7 controls skipped
Test Summary: 166 successful, 7 failures, 7 skipped
```

### Required Permissions

The following permissions are required to run the CIS benchmark profile on project level:

- compute.regions.list
- compute.zones.list
- container.clusters.get
- container.clusters.list
- serviceusage.services.get
- storage.buckets.get
- storage.buckets.getIamPolicy
