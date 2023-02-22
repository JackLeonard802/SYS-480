# Prompt user for VM name
$vmName = Read-Host -Prompt "Enter VM Name: "
# Define VM variable from VM name
$vm = Get-VM -Name $vmName

# Prompt User for name of snapshot
$snapName = Read-Host -Prompt "Enter snapshot name: "
# Take snapshot of VM
$snapshot = Get-Snapshot -Vm $vm -Name $snapName

# Prompt user for IP of vmHost
$hostIP = Read-Host -Prompt "Enter IP of VmHost: "
# Define vmHost
$vmHost = Get-VMHost -Name $hostIP

# Prompt user for name of datastore
$dsName = Read-Host -Prompt "Enter datastore name: "
# Define Datastore
$ds = Get-Datastore -Name $dsName

# Defines linked clone
$linkedClone = "{0}.linked" -f $vm.name

# Defines Linked VM
$linkedVM = New-VM -LinkedClone -Name $linkedClone -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds

# Prompts user for clone name
$cloneName = Read-Host -Prompt "Enter clone name: "
# Defines new VM
$newVM = New-VM -Name $cloneName -VM $linkedVM -VMHost $vmhost -Datastore $ds

# Prompts user for name of new Vm snapshot
$newVMSnap = Read-Host -Prompt "Enter the name for the snapshot of the new VM"
# Takes snapshot of new Vm
$newVM | New-Snapshot -Name $newVMSnap

# Removes linked clone
$linkedVM | Remove-VM -DeletePermanently

# Displays VMs
Get-VM