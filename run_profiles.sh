#!/bin/bash
inspec exec inspec-gke-cis-gcp -t gcp:// --input-file inputs.yml &
inspec exec inspec-gke-cis-k8s -t k8s:// --input-file inputs.yml &
