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
WHERE name = '$env:DATABRICKS_LOADER_USER') BEGIN
    CREATE LOGIN $env:DATABRICKS_LOADER_USER WITH PASSWORD = '$env:DATABRICKS_LOADER_PASSWORD';
END

IF NOT EXISTS
    (SELECT name
FROM sys.sql_logins
WHERE name = '$env:POWERBI_VIEWER_USER') BEGIN
    CREATE LOGIN $env:POWERBI_VIEWER_USER WITH PASSWORD = '$env:POWERBI_VIEWER_PASSWORD';
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
WHERE name = '$env:DATABRICKS_LOADER_USER')
BEGIN
    CREATE USER $env:DATABRICKS_LOADER_USER;
END

GRANT CONTROL ON DATABASE::[dwtfadl] to $env:DATABRICKS_LOADER_USER;

EXEC sp_addrolemember 'staticrc20', '$env:DATABRICKS_LOADER_USER';

IF NOT EXISTS (SELECT name
FROM sys.database_principals
WHERE name = '$env:POWERBI_VIEWER_USER')
BEGIN
    CREATE USER $env:POWERBI_VIEWER_USER;
END

EXEC sp_addrolemember 'db_datareader', '$env:POWERBI_VIEWER_USER';
"@

$MasterSqlConnection.Open()
$MasterSqlCommand.ExecuteNonQuery()
$MasterSqlConnection.Close()

$DatabaseSqlConnection.Open()
$DatabaseSqlCommand.ExecuteNonQuery()
$DatabaseSqlConnection.Close()
