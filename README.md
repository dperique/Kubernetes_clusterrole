# Make a read only kubectl context

Use this to create a service account, clusterrole, clusterrolebinding for read only
access for your k8 cluster.

You will need admin access to your cluster to create these objects.

Use it like this:

```
# Make sure you have ansible and kubectl installed.
# Make sure you can set context to a k8s cluster and have enough privileges
# to create the objects.
#
git clone <this repo>

kubectl config current-context <mykubecluster>
cd Kubernetes_clusterrole
./scripts/set_clusterrole.sh <mykubecluster>

kubectl get po          ;# this will be allowed
kubectl exec -ti ....   ;# this will not be allowed

kubectl config use-context <mykubecluster>     ;# get you back to admin access
kubectl config use-context <mykubecluster>-ro  ;# get you back to read only access
```
