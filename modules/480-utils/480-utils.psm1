function 480Banner()
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
{
    $conn = $Global:DefaultVIServer

    if ($conn){
        $msg = "Already connected to: {0}" -f $conn

        Write-Host -ForegroundColor Green $msg
    }else
    {
        $conn = Connect-VIServer -Server $server
    }
}

function Get-480Config([string] $config_path)
{
    $conf=$null
    if(Test-Path $config_path)
    {
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        $msg = "Using Configuration at {0}" -f $config_path
        Write-Host -ForegroundColor Green $msg
    }else
    {
        Write-Host -ForegroundColor Yellow "No Configuration"
    }
    return $conf
}

function Select-VM([string] $folder)
{
    $selected_vm=$null
    try
    {
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms)
        {
            Write-Host [$index] $vm.name
            $index+=1
        }
        $pick_index =  Read-Host "Which index number [x] do you wish to pick?"
        # 480-TODO need to deal with an invalid index (consider making this check a fuction)
        if ($pick_index -gt $index -1)
        {
            Write-Host "Please select a valid VM" -ForegroundColor Yellow
        }else 
        {
            $selected_vm = $vms[$pick_index -1]
            Write-Host "You picked " $selected_vm.Name
            # note this is a full on vm object that we can interact with
            return $selected_vm
        }

        
    }
    catch
    {
        Write-Host "Invalid Folder: $folder" -ForegroundColor Red
    }
}

function vmSnapshot ([string] $snapshot_name, $selected_vm)
{
    # Write-Host $snapshot_name
    $vm = Get-VM -Name $selected_vm.Name
    
    try {
        # Prompt User for name of snapshot
        $snapPrompt = Read-Host -Prompt "Enter snapshot name (default: $snapshot_name)" 
        # Take snapshot of VM, terminate on error
        $snapshot = Get-Snapshot -VM $vm -Name $snapPrompt -ErrorAction Stop
        return $snapshot
    }
    catch {
        $uInput = Read-Host "No valid VM selected. Use default? (y/n)"
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
{
    try {
        # Prompt user for IP of vmHost
        $hostPrompt = Read-Host -Prompt "Enter IP of VM Host (default: $hostIP)"
        # Define vmHost
        $vmHost = Get-VMHost -Name $hostPrompt -ErrorAction Stop
        return $vmHost
    }
    catch {
        $uInput = Read-Host "No valid VM Host selected. Use default? (y/n)"
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
{
    try {
        # Prompt user for datastore
        $hostPrompt = Read-Host -Prompt "Enter IP of the datastore you would like to use (default: $datastore)"
        # Define datastore
        $ds = Get-Datastore -Name $hostPrompt -ErrorAction Stop
        return $ds
    }
    catch {
        $uInput = Read-Host "No valid datastore selected. Use default? (y/n)"
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
{
    Write-Host "Creating linked clone..."
    # Defines linked clone
    $linkedClone = "{0}.linked" -f $vm.name

    # Defines Linked VM
    $linkedVM = New-VM -LinkedClone -Name $linkedClone -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
    
    try
    {
        # Promts user for network adapter name:
        $hostPrompt = Read-Host -Prompt "Enter the network adapter you would like to use (default: $net)"
        # Assigns net adapter to linked VM
        $linkedVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $hostPrompt -ErrorAction Stop
        Write-Host "Network adapter assigned: $net" -ForegroundColor Green
    }
    catch
    {
        $uInput = Read-Host "No valid network adapter selected. Use default? (y/n)"
        if ($uInput -eq "y" -or  "Y") 
        {
            # Define datastore
            $linkedVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $net
            Write-Host "Network adapter assigned: $net" -ForegroundColor Green
        }else {
            Write-Host "Goodbye"
            exit
        }
    }
    
}