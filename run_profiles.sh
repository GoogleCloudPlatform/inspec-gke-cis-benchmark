#!/bin/bash
# Copyright 2020 Google LLC
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
#
#
# INSTRUCTIONS:
# =============
# To see usage, execute `run_profiles.sh -h`

usage() {
  echo "Usage: run_profiles.sh -c cluster_name -u username -k keyfile -z zone -r region -i input_file"
  echo
  echo "Runs all InSpec profiles of the GKE CIS benchmark"
  echo
  echo "  -c cluster_name         Name of the GKE cluster which will be scanned (required)"
  echo "  -u username             User which logs in to cluster nodes (required). This user requires root privileges on cluster nodes."
  echo "  -k keyfile              Path to SSH Keyfile required for user to log in to cluster nodes. (required)"
  echo "  -z zone                 Zone of zonal GKE cluster. Provide either zone or region."
  echo "  -r region               Region of regional GKE cluster. Provide either zone or region."
  echo "  -i input file           Path to input file for inspec."
}

main() {

  mkdir -p reports

  if [ -z "$input_file" ];then
    input_file=inputs.yml
  fi


  echo "Running InSpec profile inspec-gke-cis-gcp ..."
  inspec exec inspec-gke-cis-gcp -t gcp:// --input-file $input_file --reporter cli json:reports/inspec-gke-cis-gcp_report.json html:reports/inspec-gke-cis-gcp_report.html
  echo "Stored report in reports/inspec-gke-cis-gcp_report."

  echo "Running InSpec profile inspec-gke-cis-k8s ..."
  inspec exec inspec-gke-cis-k8s -t k8s:// --input-file $input_file --reporter cli json:reports/inspec-gke-cis-k8s_report.json html:reports/inspec-gke-cis-k8s_report.html
  echo "Stored report in reports/inspec-gke-cis-gcp_report."

  if [ -z "$region" ];then
    location_option="--zone $zone"
  else
    location_option="--region $region"
  fi

  # to run InSpec on all cluster nodes, get all node pools of the cluster and get all instances that are part of the associated instance group
  node_pools=`gcloud container clusters describe $cluster_name $location_option --format json | jq .nodePools[].name | tr -d \'\"`
  for node_pool in $node_pools
  do
    instance_group_urls=`gcloud container node-pools describe $node_pool --cluster $cluster_name $location_option --format json | jq .instanceGroupUrls | jq @sh`

    for i in $instance_group_urls
    do
      instance_group_uri=`echo $i | tr -d \'\"`
      instance_uri_list=`gcloud compute instance-groups managed list-instances --uri $instance_group_uri`
      for instance in $instance_uri_list
      do
        instance=`echo $instance | sed 's/^.*instances\///'`
        instance_zone=`gcloud compute instances list --filter="name=($instance)" --format "value(zone)"`

        proxy_command=`gcloud compute ssh $instance --tunnel-through-iap --dry-run --zone $instance_zone | sed 's/^.*\(ProxyCommand .* -o ProxyUse\).*$/\1/' | sed 's/\ProxyCommand //g' | sed 's/\ -o ProxyUse//g'`

        echo "Running InSpec profile inspec-gke-cis-ssh on node $instance ..."
        inspec exec inspec-gke-cis-ssh -t ssh://$instance --input-file $input_file --proxy_command="$proxy_command" -i $keyfile --user $username --sudo --reporter cli json:reports/inspec-gke-cis-ssh_${instance}_report.json html:reports/inspec-gke-cis-ssh_${instance}_report.html
        echo "Stored report in reports/inspec-gke-cis-ssh_${instance}_report."
      done
    done
  done
}

while getopts 'c:u:k:z:r:i' c
do
  case $c in
    c) cluster_name="$OPTARG";;
    u) username="$OPTARG";;
    k) keyfile="$OPTARG";;
    z) zone="$OPTARG";;
    r) region="$OPTARG";;
    i) input_file="$OPTARG";;
    h|?)
      usage
      exit 2
      ;;
  esac
done

main
