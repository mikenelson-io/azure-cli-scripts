#/bin/bash

storageaccount=mystorageaccount$RANDOM
publicdns=mypublicdns$RANDOM

az group create --name myResourceGroup --location westeurope

az storage account create --resource-group myResourceGroup --location westeurope \
  --name $storageaccount --kind Storage --sku Standard_LRS

az network vnet create --resource-group myResourceGroup --location westeurope --name myVnet \
  --address-prefix 192.168.0.0/16 --subnet-name mySubnet --subnet-prefix 192.168.1.0/24

az network public-ip create --resource-group myResourceGroup --location westeurope \
  --name myPublicIP --dns-name $publicdns --allocation-method static --idle-timeout 4

az network lb create --resource-group myResourceGroup --location westeurope \
  --name myLoadBalancer --public-ip-address myPublicIP \
  --frontend-ip-name myFrontEndPool --backend-pool-name myBackEndPool

az network lb probe create --resource-group myResourceGroup --lb-name myLoadBalancer \
  --name myHealthProbe --protocol tcp --port 80 --interval 15 --threshold 4

az network lb rule create --resource-group myResourceGroup --lb-name myLoadBalancer \
  --name myLoadBalancerRuleWeb --protocol tcp --frontend-port 80 --backend-port 80 \
  --frontend-ip-name myFrontEndPool --backend-pool-name myBackEndPool \
  --probe-name myHealthProbe

for i in `seq 1 3`; do
  az network lb inbound-nat-rule create --resource-group myResourceGroup \
    --lb-name myLoadBalancer --name myLoadBalancerRuleSSH$i --protocol tcp \
    --frontend-port 422$i --backend-port 22 --frontend-ip-name myFrontEndPool
done

az network nsg create --resource-group myResourceGroup --location westeurope \
  --name myNetworkSecurityGroup

az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleSSH \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 \
  --access allow

az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleHTTP \
  --protocol tcp --direction inbound --priority 1001 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 \
  --access allow

for i in `seq 1 3`; do
  az network nic create --resource-group myResourceGroup --location westeurope --name myNic$i \
    --vnet-name myVnet --subnet mySubnet --network-security-group myNetworkSecurityGroup \
    --lb-name myLoadBalancer --lb-address-pools myBackEndPool \
    --lb-inbound-nat-rules myLoadBalancerRuleSSH$i
done

az vm availability-set create --resource-group myResourceGroup --location westeurope \
  --name myAvailabilitySet

for i in `seq 1 3`; do
  az vm create \
    --resource-group myResourceGroup \
    --name myVM$i \
    --location westeurope \
    --availability-set myAvailabilitySet \
    --nics myNic$i \
    --vnet myVnet \
    --subnet-name mySubnet \
    --nsg myNetworkSecurityGroup \
    --storage-account $storageaccount \
    --image UbuntuLTS \
    --ssh-key-value ~/.ssh/id_rsa.pub \
    --admin-username ops
done

echo "The public DNS name for your load balanced set is http://$publicdns.westeurope.cloudapp.azure.com. 

You can SSH to your VMs to install apps like nginx with ops@$publicdns.westeurope.cloudapp.azure.com on ports 4221, 4222, and 4223 respectively."