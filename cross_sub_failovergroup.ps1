# define all variables
$primarysubscriptionname = '' # primary subscription 
$primaryresourcegroupname = '' # primary rg
$primaryservername = '' # primary server
$failovergroupname = '' # failover group name 
$secondarysubscriptionname = '' # secondary subscription name
$secondaryresourcegroupname = '' # secondary resource group name
$secondaryresourcegrouplocation = '' # location for secondary resource group
$secondaryservername = '' # name of secondary SQL Server
$extsqladmin = '' # designated AZ-AD group for SQL Admin

#set context to secondary sub
set-AzContext -subscription $secondarysubscriptionname
#create secondary rg
New-AzResourceGroup -Name $secondaryresourcegroupname -Location $secondaryresourcegrouplocation
#grab secondary subscription ID

New-AzSqlServer -ResourceGroupName $secondaryresourcegroupname -Location $secondaryresourcegrouplocation -ServerName $secondaryservername -SqlAdministratorCredentials (Get-Credential) -ExternalAdminName $extsqladmin

$subscription_id_secondary = get-AzSubscription -SubscriptionName $secondarysubscriptionname
#set context to primary subscription
set-AzContext -subscription $primarysubscriptionname
# create the failover group object 
$failoverGroup = New-AzSqlDatabaseFailoverGroup -ServerName $primaryservername -FailoverGroupName $failovergroupname -PartnerSubscriptionId $subscription_id_secondary.Id -PartnerResourceGroupName $secondaryresourcegroupname -PartnerServerName $secondaryservername -FailoverPolicy Manual -ResourceGroupName $primaryresourcegroupname
# get all the databases on the primary 
$databases = get-AzSqlDatabase -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername
# put all the databases in the primary into the failover group 
foreach ($db in $databases) {
    if($db.DatabaseName -like 'x*'){ # basic logic to only add DB to failover if they are named X
 Get-AzSqlDatabase -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername  -DatabaseName $db.DatabaseName | Add-AzSqlDatabaseToFailoverGroup -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername  -FailoverGroupName $failovergroupname
 Start-Sleep -Seconds 3
    }
    else{ # remove DBs if they are not named X
       # Get-AzSqlDatabase -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername  -DatabaseName $db.DatabaseName | Remove-AzSqlDatabaseFromFailoverGroup -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername -FailoverGroupName $failovergroupname
    }    
}
