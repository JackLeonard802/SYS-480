# import module
Import-Module '480-utils' -Force

# present banner
480Banner

# load json as conf
$conf = Get-480Config -config_path "/home/jack/Documents/SYS-480/480.json"

# Connect to vCenter
480connect -server $conf.vcenter_server

# Select VM from folder
Write-Host "Selecting your VM"
$selected_vm = Select-VM -folder "BASEVM"

# Select snapshot
$snapshot = vmSnapshot -snapshot_name $conf.snapshot -selected_vm $selected_vm

# Select ESXi Host
$vmhost = esxiHost -hostIP $conf.esxi_host

# Select datastore
$ds = datastoreName -datastore $conf.default_datastore

# Create Linked Clone
linkedClone -vm $selected_vm -snapshot $snapshot -vmhost $vmhost -ds $ds -net $conf.default_network