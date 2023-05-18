# define all variables
$primarysubscriptionname = 'CRM-DMS-APAC-prd-sub'
$primaryresourcegroupname = 'public-sqldb-apac-prd-001-rg'
$primaryservername = 'aa03-wsql03'

$failovergroupname = 'test-ha-crmdms'

$secondarysubscriptionname = 'it-ba-lab-d3'
$secondaryresourcegroupname = 'CRM-DMS-APAC-SQLDB'
$secondaryservername = 'aa03-sql04'

#set context to primary subscription
set-AzContent -subscription $primarysubscriptionname
#grab secondary subscription ID
$subscription_id_secondary = get-AzSubscription -SubscriptionName $secondarysubscriptionname
# create the failover group object
$failoverGroup = New-AzSqlDatabaseFailoverGroup -ServerName $primaryservername -FailoverGroupName $failovergroupname -PartnerSubscriptionId $subscription_id_secondary.Id -PartnerResourceGroupName $secondaryresourcegroupname -PartnerServerName $secondaryservername -FailoverPolicy Manual -ResourceGroupName $primaryresourcegroupname
# get all the databases on the primary 
$databases = get-AzSqlDatabase -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername
# put all the databases in the primary into the failover group 
foreach ($dbName in $databases) {
 Get-AzSqlDatabase -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername  -DatabaseName $dbName.DatabaseName | Add-AzSqlDatabaseToFailoverGroup -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername  -FailoverGroupName $failovergroupname
 Start-Sleep -Seconds 3
}
