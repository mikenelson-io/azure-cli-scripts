REM Variables
set resourceGroupName=%myResourceGroup%
set location=%westeurope%
set sourcevm=%virtual-machine%

REM Get the URI for the source VM operating system disk.
uri="$(az vm show -g %resourceGroupName% -n %sourcevm% --query [storageProfile.osDisk.vhd.uri] -o tsv)"

REM Delete the source virtual machine, this will not delete the disk.
az vm delete -g %resourceGroupName% -n %sourcevm%

REM Create a new virtual machine.
az vm create ^
  --image UbuntuLTS ^
  --admin-username opsadmin ^
  --ssh-key-value c:\ssh\id_rsa.pub ^
  --resource-group %resourceGroupName% ^
  --location %location% ^
  --name myVM

REM Attach the VHD as a data disk to the newly created VM
az vm disk attach-existing --vm-name myVM -g %resourceGroupName% --vhd %uri% --lun 0 -n dd1
