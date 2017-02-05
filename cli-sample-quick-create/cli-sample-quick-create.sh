#/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create a virtual machine. 
az vm create \
  --image UbuntuLTS \
  --admin-username ops \
  --ssh-key-value ~/.ssh/id_rsa.pub \
  --resource-group myResourceGroup \
  --location westus \
  --name myVM \
  --no-wait
