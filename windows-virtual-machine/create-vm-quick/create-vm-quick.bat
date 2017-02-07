REM Variables
set resourceGroupName=myResourceGroup
set location=westeurope

REM Create a resource group.
az group create --name %resourceGroupName% --location %location%

REM Create a virtual machine. 
az vm create ^
  --image UbuntuLTS ^
  --admin-username ops ^
  --ssh-key-value ~/.ssh/id_rsa.pub ^
  --resource-group %resourceGroupName% ^
  --location %location% ^
  --name myVM ^
  --no-wait