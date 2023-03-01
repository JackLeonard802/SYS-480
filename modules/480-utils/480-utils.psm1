function 480Banner()
# Presents Banner for 480Utils
{
    $banner = @"
     __ __  ____  ____ 
    / // / ( __ )/ __ \
   / // /_/ __  / / / /
  /__  __/ /_/ / /_/ / 
    /_/  \____/\____/  
    / / / / /_(_) /____
   / / / / __/ / / ___/
  / /_/ / /_/ / (__  ) 
  \____/\__/_/_/____/  
                       
"@

    Write-Host $banner
}

function 480connect([string] $server)
# connects to vCenter
{
    $conn = $Global:DefaultVIServer

    if ($conn){
        $msg = "Already connected to: {0}" -f $conn

        # Presents if user is already connected
        Write-Host -ForegroundColor Green $msg
    }else
    {
        # Connecting to server
        $conn = Connect-VIServer -Server $server
    }
}

function Get-480Config([string] $config_path)
# Pulls config file and converts data from json
{
    $conf=$null
    if(Test-Path $config_path)
    {
        # Converts from json
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        $msg = "Using Configuration at {0}" -f $config_path
        Write-Host -ForegroundColor Green $msg
    }else
    {
        # Presents if no configuration present
        Write-Host -ForegroundColor Yellow "No Configuration"
    }

    # Returns config
    return $conf
}

function Select-VM([string] $folder)
# Presents VM selection Menu and allows user to select VM
{
    # Clears selection
    $selected_vm=$null

    # Error handling
    try
    {
        # Gets VMs from folder
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms)
        {
            #Lists each VM in folder
            Write-Host [$index] $vm.name
            $index+=1
        }

        # Prompts user to pick VM from index number
        $pick_index =  Read-Host "Which index number [x] do you wish to pick?"

        # Handles invalid index
        if ($pick_index -gt $index -1)
        {
            # Notifies user of invalid index
            Write-Host "Please select a valid VM" -ForegroundColor Yellow
        }else 
        {
            # Selects VM that user specified
            $selected_vm = $vms[$pick_index -1]
            Write-Host "You picked " $selected_vm.Name
            
            # Returns VM object
            return $selected_vm
        }

        
    }
    catch
    {
        # Displays if folder is invalid
        Write-Host "Invalid Folder: $folder" -ForegroundColor Red
    }
}

function vmSnapshot ([string] $snapshot_name, $selected_vm)
# Chooses snapshot of VM selected by user
{
    # Gets VM user selected
    $vm = Get-VM -Name $selected_vm.Name
    
    # Error Handling
    try {

        # Prompt User for name of snapshot
        $snapPrompt = Read-Host -Prompt "Enter snapshot name (default: $snapshot_name)" 

        # Take snapshot of VM, terminate on error
        $snapshot = Get-Snapshot -VM $vm -Name $snapPrompt -ErrorAction Stop
        return $snapshot
    }
    catch {

        # Prompts user if invalid input detected
        $uInput = Read-Host "No valid VM selected. Use default? (y/n)"

        # Uses default, else quits
        if ($uInput -eq "y" -or  "Y") 
        {
            # Take snapshot of VM
            $snapshot = Get-Snapshot -VM $vm -Name $snapshot_name
            return $snapshot
        }else {
            Write-Host "Goodbye"
            exit
        }
    }
}

function esxiHost ([string] $hostIP)
# user selects ESXi host
{
    # Error Handling
    try {
        # Prompt user for IP of vmHost
        $hostPrompt = Read-Host -Prompt "Enter IP of VM Host (default: $hostIP)"

        # Define vmHost, terminate on error
        $vmHost = Get-VMHost -Name $hostPrompt -ErrorAction Stop
        return $vmHost
    }
    catch {

        # Runs if invalid input detected
        $uInput = Read-Host "No valid VM Host selected. Use default? (y/n)"

        # uses default, else quits
        if ($uInput -eq "y" -or  "Y") 
        {
            # Define vmHost
            $vmHost = Get-VMHost -Name $hostIP
            return $vmHost
        }else {
            Write-Host "Goodbye"
            exit
        }
    }
}

function datastoreName ([string] $datastore)
# User selects datastore from ESXi host
{
    # Error Handling
    try {
        # Prompt user for datastore
        $hostPrompt = Read-Host -Prompt "Enter the datastore you would like to use (default: $datastore)"
        # Define datastore
        $ds = Get-Datastore -Name $hostPrompt -ErrorAction Stop
        return $ds
    }
    catch {

        # Runs if invalid input detected
        $uInput = Read-Host "No valid datastore selected. Use default? (y/n)"

        # Uses default, else quits
        if ($uInput -eq "y" -or  "Y") 
        {
            # Define datastore
            $ds = Get-Datastore -Name $datastore
            return $ds
        }else {
            Write-Host "Goodbye"
            exit
        }
    }
}

function linkedClone ($vm, $snapshot, $vmhost, $ds, $net)
# Creates linked clone from predefined parameters and sets network adapter
{
    Write-Host "Creating linked clone..."

    # Defines linked clone
    $linkedClone = "{0}.linked" -f $vm.name

    # Defines Linked VM
    $linkedVM = New-VM -LinkedClone -Name $linkedClone -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
    
    # Setting network adapter and Error handling
    try
    {
        # Promts user for network adapter name:
        $hostPrompt = Read-Host -Prompt "Enter the network adapter you would like to use (default: $net)"
        # Assigns net adapter to linked VM
        Get-VM $linkedVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $hostPrompt -ErrorAction Stop
        Write-Host "Network adapter assigned: $net" -ForegroundColor Green
    }
    catch
    {
        # Runs if no valid input detected
        $uInput = Read-Host "No valid network adapter selected. Use default? (y/n)"

        # Uses default, else quits
        if ($uInput -eq "y" -or  "Y") 
        {
            # Define datastore
            Get-VM $linkedVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $net
            Write-Host "Network adapter assigned: $net" -ForegroundColor Green

        }else {
            Write-Host "Goodbye"
            exit
        }
    }
    
}