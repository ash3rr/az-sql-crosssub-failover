# define all variables
$primarysubscriptionname = 'CRM-DMS-APAC-prd-sub'
$primaryresourcegroupname = 'public-sqldb-apac-prd-001-rg'
$primaryservername = 'aa03-wsql03'

$failovergroupname = 'crm-dms-apac-ha'

$secondarysubscriptionname = 'it-ba-lab-d3'
$secondaryresourcegroupname = 'public-sqldb-emea-prd-001-rg'
$secondaryresourcegrouplocation = 'Germany West Central'
$secondaryservername = 'aa03-wsql04'


#set context to secondary sub
set-AzContext -subscription $secondarysubscriptionname
#create secondary rg
New-AzResourceGroup -Name $secondaryresourcegroupname -Location $secondaryresourcegrouplocation
#grab secondary subscription ID

New-AzSqlServer -ResourceGroupName $secondaryresourcegroupname -Location $secondaryresourcegrouplocation -ServerName $secondaryservername -SqlAdministratorCredentials (Get-Credential) -ExternalAdminName 'AA_DBAdmin_MSSQL-sg'

$subscription_id_secondary = get-AzSubscription -SubscriptionName $secondarysubscriptionname
#set context to primary subscription
set-AzContext -subscription $primarysubscriptionname
# create the failover group object 
$failoverGroup = New-AzSqlDatabaseFailoverGroup -ServerName $primaryservername -FailoverGroupName $failovergroupname -PartnerSubscriptionId $subscription_id_secondary.Id -PartnerResourceGroupName $secondaryresourcegroupname -PartnerServerName $secondaryservername -FailoverPolicy Manual -ResourceGroupName $primaryresourcegroupname
# get all the databases on the primary 
$databases = get-AzSqlDatabase -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername
# put all the databases in the primary into the failover group 
foreach ($db in $databases) {
 Get-AzSqlDatabase -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername  -DatabaseName $db.DatabaseName | Add-AzSqlDatabaseToFailoverGroup -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername  -FailoverGroupName $failovergroupname
 Start-Sleep -Seconds 3
}
