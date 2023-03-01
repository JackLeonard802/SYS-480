Import-Module '480-utils' -Force

480Banner
$conf = Get-480Config -config_path "/home/jack/Documents/SYS-480/480.json"
480connect -server $conf.vcenter_server
Write-Host "Selecting your VM"
$selected_vm = Select-VM -folder "BASEVM"
$snapshot = vmSnapshot -snapshot_name $conf.snapshot -selected_vm $selected_vm
$vmhost = esxiHost -hostIP $conf.esxi_host
$ds = datastoreName -datastore $conf.default_datastore
linkedClone -vm $selected_vm -snapshot $snapshot -vmhost $vmhost -ds $ds -net $conf.default_network