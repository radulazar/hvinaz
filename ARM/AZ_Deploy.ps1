# deploy VMs in Azure
Connect-AzAccount
Get-AzContext
Get-AzSubscription

$config = get-content .\ARM\EnvironmentConfig.json | ConvertFrom-Json


# connect to MSDN subscription
Set-AzContext -SubscriptionId dae5303d-160f-4b71-ad9b-a3d62357e396

# create Resource Group
$location = "West Europe"
$rgDeployResult = New-AzSubscriptionDeployment -Location $location -guid '01' -TemplateFile .\arm\rg.json

$rg = $rgDeployResult.Outputs.rgname.Value
$guid = $rgDeployResult.Outputs.guid.Value

# Create Virtual Network
New-AzResourceGroupDeployment -ResourceGroupName $rg -guid $guid -TemplateFile .\arm\virtualnetwork.json

# Create Virtual Machines based on role attribute from Config file

## create server VMs
$HVVMs = $config.azure.virtualmachines | Where-Object {$_.role -eq 'Hyper-V'} 
foreach ($vm in $HVVMs) {New-AzResourceGroupDeployment -ResourceGroupName $rg -guid $guid -vmName $vm.Name -PrivateIP $vm.IP -subnet $vm.subnet -TemplateFile .\arm\vm.json}
# deploy only the 1st machine if needed
foreach ($vm in $HVVMs[0]) {New-AzResourceGroupDeployment -ResourceGroupName $rg -guid $guid -vmName $vm.Name -PrivateIP $vm.IP -subnet $vm.subnet -TemplateFile .\arm\vm.json}

# create client VMs
$VMcls = $config.azure.virtualmachines | Where-Object {$_.role -eq 'Client'}
foreach ($vmcl in $VMcls) {New-AzResourceGroupDeployment -ResourceGroupName $rg -guid $guid -vmName $vmcl.Name -PrivateIP $vmcl.IP -subnet $vmcl.subnet -TemplateFile .\arm\vmclient.json}