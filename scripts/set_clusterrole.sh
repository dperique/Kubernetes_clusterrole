#!/bin/bash

if [ "$1" == "" ]; then
    echo "Usage:"
    echo ""
    echo "  $0 <a-k8s-Cluster>"
    echo ""
    echo "  * Adds a service account, clusterrole, clusterrolebinding for read-only"
    echo "    access."
    echo "  * Creates the kubectl context as \<a-k8s-Cluster\>-ro"
    echo "  * Sets the kubectl context to \<a-k8s-Cluster\>-ro"
    echo ""
    exit
fi

cluster_name=$1
namespace=default
sa_account=generic-read-only-sa

# Render the clusterrole template.
#
ansible-playbook -v -i localhost clusterrole.yaml -e cluster_name=$cluster_name \
                                               -e namespace=$namespace \
                                               -e sa_account=$sa_account -e do_it=1

# Get the kubernetes secret for the service account.
#
secret=$(kubectl get sa -n $namespace $sa_account -o "jsonpath={.secrets[0].name}")
#echo $secret

# Extract the token data.
#
token_data=$(kubectl get secret -n $namespace $secret -o "jsonpath={.data.token}" | base64 --decode)
#echo $token_data

# Extract the cert data.
#
cert_data=$(kubectl get secret -n $namespace $secret -o 'go-template={{index .data "ca.crt"}}')
echo $cert_data | base64 --decode > /tmp/${cluster_name}-ro.pem
#echo $cert_data
#cat /tmp/${cluster_name}-ro.pem

# Get the endpoint of the cluster.
#
endpoint=`kubectl config view -o jsonpath="{.clusters[?(@.name == \"$cluster_name\")].cluster.server}"`
echo $endpoint

kubectl config set-cluster ${cluster_name}-ro \
  --server=$endpoint \
  --embed-certs=true \
  --certificate-authority=/tmp/${cluster_name}-ro.pem

kubectl config set-credentials ${sa_account} --token=$token_data

kubectl config set-context ${cluster_name}-ro \
  --cluster=${cluster_name}-ro \
  --user=$sa_account \
  --namespace=$namespace

kubectl config use-context ${cluster_name}-ro

# For debugging use only.
#
#kubectl config use-context ${cluster_name}
#kubectl get sa
#kubectl get clusterrole generic-read-only-cr
#kubectl get clusterrolebinding generic-read-only-crb -o wide

# Remove what we added to the cluster via this.
#
#kubectl delete -f /tmp/${cluster_name}-clusterrole.yaml
