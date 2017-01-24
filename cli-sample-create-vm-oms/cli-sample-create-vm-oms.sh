#/bin/sh

omsid=myOMSId
omskey=myOMSKey

storageaccount=mystorageaccount$RANDOM
publicdns=mypublicdns$RANDOM

az group create --name myResourceGroup --location westeurope

az storage account create --resource-group myResourceGroup --location westeurope \
  --name $storageaccount --kind Storage --sku Standard_LRS

az network vnet create --resource-group myResourceGroup --location westeurope --name myVnet \
  --address-prefix 192.168.0.0/16 --subnet-name mySubnet --subnet-prefix 192.168.1.0/24

az network public-ip create --resource-group myResourceGroup --location westeurope \
  --name myPublicIP --dns-name $publicdns --allocation-method static --idle-timeout 4

az network nsg create --resource-group myResourceGroup --location westeurope \
  --name myNetworkSecurityGroup

az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleSSH \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 \
  --access allow

az network nic create --resource-group myResourceGroup --location westeurope --name myNic1 \
  --vnet-name myVnet --subnet mySubnet --network-security-group myNetworkSecurityGroup \

az vm create \
  --resource-group myResourceGroup \
  --name myVM1 \
  --location westeurope \
  --nics myNic1 \
  --vnet myVnet \
  --subnet-name mySubnet \
  --nsg myNetworkSecurityGroup \
  --storage-account $storageaccount \
  --image UbuntuLTS \
  --ssh-key-value ~/.ssh/id_rsa.pub \
  --admin-username ops

az vm extension set \
  --resource-group myResourceGroup \
  --vm-name myVM1 --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --version 1.0 --protected-settings '{"workspaceKey": "$omskey"}' \
  --settings '{"workspaceId": "$omsid"}'