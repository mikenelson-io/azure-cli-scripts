REM Update with OMS Id and OMS key.
set omsid=myOMSId
set omskey=myOMSKey

REM Variables
set resourceGroupName=myResourceGroup
set location=westeurope
set publicdns=mypublicdns%RANDOM%

REM Create a resource group.
az group create --name %resourceGroupName% --location %location%

REM Create a storage account.
az storage account create --resource-group %resourceGroupName% --location %location% ^
  --name $storageaccount --kind Storage --sku Standard_LRS

REM Create a virtual network.
az network vnet create --resource-group %resourceGroupName% --location %location% --name myVnet ^
  --address-prefix 192.168.0.0/16 --subnet-name mySubnet --subnet-prefix 192.168.1.0/24

REM Create a public IP address and specify a DNS name.
az network public-ip create --resource-group %resourceGroupName% --location %location% ^
  --name myPublicIP --dns-name %publicdns% --allocation-method static --idle-timeout 4

REM Create a network security group.
az network nsg create --resource-group %resourceGroupName% --location %location% ^
  --name myNetworkSecurityGroup

REM Create an inbound network security group rule for port 22.
az network nsg rule create --resource-group %resourceGroupName% ^
  --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleSSH ^
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' ^
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 ^
  --access allow

REM Create a virtual network card and associate with public IP address and NSG.
az network nic create --resource-group %resourceGroupName% --location %location% --name myNic1 ^
  --vnet-name myVnet --subnet mySubnet --network-security-group myNetworkSecurityGroup ^
  --public-ip-address myPublicIP

REM Create a virtual machine. 
az vm create ^
  --resource-group %resourceGroupName% ^
  --name myVM1 ^
  --location %location% ^
  --nics myNic1 ^
  --vnet myVnet ^
  --subnet-name mySubnet ^
  --nsg myNetworkSecurityGroup ^
  --storage-account $storageaccount ^
  --image UbuntuLTS ^
  --ssh-key-value ~/.ssh/id_rsa.pub ^
  --admin-username opsadmin

REM Install and configure the OMS agent.
az vm extension set ^
  --resource-group %resourceGroupName% ^
  --vm-name myVM1 --name OmsAgentForLinux ^
  --publisher Microsoft.EnterpriseCloud.Monitoring ^
  --version 1.0 --protected-settings '{"workspaceKey": "%omskey%"}' ^
  --settings '{"workspaceId": "%omsid%"}'
