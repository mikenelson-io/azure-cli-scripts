#/bin/bash

storageaccount=mystorageaccount$RANDOM
publicdns=mypublicdns$RANDOM

az group create --name myResourceGroup --location westeurope

az storage account create --resource-group myResourceGroup --location westeurope \
  --name $storageaccount --kind Storage --sku Standard_LRS

az network vnet create --resource-group myResourceGroup --location westeurope --name myVnet \
  --address-prefix 192.168.0.0/16 --subnet-name mySubnetFrontEnd --subnet-prefix 192.168.1.0/24

az network vnet subnet create --resource-group myResourceGroup --vnet-name myVnet \
  --name mySubnetBackEnd --address-prefix 192.168.2.0/24

az network public-ip create --resource-group myResourceGroup --location westeurope \
  --name myPublicIP --dns-name $publicdns --allocation-method static --idle-timeout 4

az network nsg create --resource-group myResourceGroup --location westeurope \
  --name myNetworkSecurityGroupFrontEnd

az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroupFrontEnd --name myNetworkSecurityGroupRuleFrontEndSSH \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 \
  --access allow

az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroupFrontEnd --name myNetworkSecurityGroupRuleFrontEndHTTP \
  --protocol tcp --direction inbound --priority 1001 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 \
  --access allow

az network vnet subnet update --resource-group myResourceGroup --vnet-name myVnet \
  --name mySubnetFrontEnd --network-security-group myNetworkSecurityGroupFrontEnd

az network nsg create --resource-group myResourceGroup --location westeurope \
  --name myNetworkSecurityGroupBackEnd

az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroupBackEnd --name myNetworkSecurityGroupRuleBackEndSSH \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix 192.168.1.0/24 \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 \
  --access allow

az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroupBackEnd --name myNetworkSecurityGroupRuleBackEndMongoDB \
  --protocol tcp --direction inbound --priority 1001 --source-address-prefix 192.168.1.0/24 \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 27017 \
  --access allow

az network vnet subnet update --resource-group myResourceGroup --vnet-name myVnet \
  --name mySubnetBackEnd --network-security-group myNetworkSecurityGroupBackEnd

az network nic create --resource-group myResourceGroup --location westeurope --name myNic1 \
    --vnet-name myVnet --subnet mySubnetFrontEnd --public-ip-address myPublicIP
az network nic create --resource-group myResourceGroup --location westeurope --name myNic2 \
    --vnet-name myVnet --subnet mySubnetBackEnd

az vm create \
    --resource-group myResourceGroup \
    --name myVMFrontEnd \
    --location westeurope \
    --nics myNic1 \
    --vnet myVnet \
    --subnet-name mySubnetFrontEnd \
    --storage-account $storageaccount \
    --image UbuntuLTS \
    --ssh-key-value ~/.ssh/id_rsa.pub \
    --admin-username ops

az vm create \
    --resource-group myResourceGroup \
    --name myVMBackEnd \
    --location westeurope \
    --nics myNic2\
    --vnet myVnet \
    --subnet-name mySubnetBackEnd \
    --storage-account $storageaccount \
    --image UbuntuLTS \
    --ssh-key-value ~/.ssh/id_rsa.pub \
    --admin-username ops


echo "The public DNS name for your front end VM is http://$publicdns.westeurope.cloudapp.azure.com. 

You can SSH to your front end VM to install apps like nginx with ops@$publicdns.westeurope.cloudapp.azure.com. You can then SSH to your back end VM to install apps like MongoDB."