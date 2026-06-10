![alt text](image.png)

![alt text](image-1.png)

![alt text](image-2.png)

![alt text](image-3.png)

kubectl wait --for=condition=available deployment --all
![alt text](image-4.png)

kubectl get svc
![alt text](image-5.png)

kubectl port-forward pod/podname <localport>:<container-port>
![alt text](image-7.png)

https://d222vzusebo6w5.cloudfront.net/proxy/8080/
![alt text](image-6.png)

kubectl get nodepool
![alt text](image-8.png)
from the console side
![alt text](image-9.png)
using cli command
![alt text](image-10.png)

for node in $(kubectl get nodes -l karpenter.sh/nodepool=general-purpose -o custom-columns=NAME:.metadata.name --no-headers); do
  echo "Pods on $node:"
  kubectl get pods --all-namespaces --field-selector spec.nodeName=$node
done
![alt text](image-11.png)

kubectl scale --replicas=12 deployment/retail-store-app-ui
![alt text](image-12.png)

kubectl get pod
![alt text](image-13.png)
upgraded the helm
![alt text](image-14.png)

![alt text](image-15.png)

![alt text](image-16.png)

kubectl get node -L topology.kubernetes.io/zone --no-headers | while read node status roles age version zone; do
echo "Pods on node $node (Zone: $zone):"
  kubectl get pods --all-namespaces --field-selector spec.nodeName=$node -l app.kubernetes.io/instance=retail-store-app-ui
echo "-----------------------------------"
done

![alt text](image-17.png)

eksctl create addon --name metrics-server --cluster ${DEMO_CLUSTER_NAME}
![alt text](image-18.png)

![alt text](image-19.png)

kubectl run load-generator \
 --image=williamyeh/hey:latest \
 --restart=Never -- -c 10 -q 10 -z 4m http://retail-store-app-ui/utility/stress/200000
 ![alt text](image-20.png)

 ![alt text](image-21.png)

 