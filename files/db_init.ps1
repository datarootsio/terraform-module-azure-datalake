Install-Module SQLServer -Confirm:$False -Force

$SqlConnection = new-object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = 'Server=tcp:${server}.database.windows.net,1433;Initial Catalog=${database};Persist Security Info=False;User ID=${user};Password=${password};'

$SqlCommand = $SqlConnection.CreateCommand()
$SqlCommand.CommandText = get-content "/tmp/rendered_script.sql

$SqlConnection.Open();
$SqlCommand.ExecuteQuery();
$SqlConnection.Close();