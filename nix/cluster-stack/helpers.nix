# get local IP:  
# export IP_ADDRESS=$(kubectl get node  --output 'jsonpath={.items[0].status.addresses[0].address}'):
# $(kubectl get svc $INGRESSGATEWAY --namespace istio-system   --output 'jsonpath={.spec.ports[?(@.port==80)].nodePort}')

{writeScriptBin}: {
# kubectl -n garden port-forward service/etcd 32379:2379 > /dev/null &  
}
