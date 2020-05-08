$ErrorActionPreference = "Stop";

Install-Module SQLServer -Confirm:$False -Force

$SqlPassword = New-Object -TypeName System.Security.SecureString
foreach ($c in $env:PASSWORD.ToCharArray()) {
    $SqlPassword.AppendChar($c)
}
$SqlPassword.MakeReadOnly()

$SqlCredential = New-Object -TypeName System.Data.SqlClient.SqlCredential -ArgumentList $env:USER, $SqlPassword
$MasterSqlConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList "Server=tcp:$env:SERVER,1433;Initial Catalog=master;Persist Security Info=False;", $SqlCredential
$DatabaseSqlConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList "Server=tcp:$env:SERVER,1433;Initial Catalog=$env:DATABASE;Persist Security Info=False;", $SqlCredential

$MasterSqlCommand = $MasterSqlConnection.CreateCommand()
$DatabaseSqlCommand = $DatabaseSqlConnection.CreateCommand()

$MasterSqlCommand.CommandText = @"
IF NOT EXISTS
    (SELECT name
FROM sys.sql_logins
WHERE name = 'DatabricksLoader') BEGIN
    CREATE LOGIN DatabricksLoader WITH PASSWORD = '$env:DATABRICKS_LOADER_PASSWORD';

END

IF NOT EXISTS
    (SELECT name
FROM sys.sql_logins
WHERE name = 'PowerBiViewer') BEGIN
    CREATE LOGIN PowerBiViewer WITH PASSWORD = '$env:POWERBI_VIEWER_PASSWORD';

END
"@

$DatabaseSqlCommand.CommandText = @"
IF (SELECT COUNT(*)
FROM sys.symmetric_keys
WHERE name LIKE '%DatabaseMasterKey%') = 0
BEGIN
    CREATE MASTER KEY
END

IF NOT EXISTS (SELECT name
FROM sys.database_principals
WHERE name = 'DatabricksLoader')
BEGIN
    CREATE USER DatabricksLoader;
END

GRANT CONTROL ON DATABASE::[dwtfadl] to DatabricksLoader;

EXEC sp_addrolemember 'staticrc20', 'DatabricksLoader';

IF NOT EXISTS (SELECT name
FROM sys.database_principals
WHERE name = 'PowerBiViewer')
BEGIN
    CREATE USER PowerBiViewer;
END
"@

$MasterSqlConnection.Open()
$MasterSqlCommand.ExecuteNonQuery()
$MasterSqlConnection.Close()

$DatabaseSqlConnection.Open()
$DatabaseSqlCommand.ExecuteNonQuery()
$DatabaseSqlConnection.Close()