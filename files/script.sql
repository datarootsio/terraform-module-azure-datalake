IF (SELECT COUNT(*)
FROM sys.symmetric_keys
WHERE name LIKE '%DatabaseMasterKey%') = 0
BEGIN
    CREATE MASTER KEY
END

IF (SELECT COUNT(*)
FROM sys.database_scoped_credentials
WHERE name = 'ADLSCredential') = 0
BEGIN
    CREATE DATABASE SCOPED CREDENTIAL ADLSCredential
    WITH
        IDENTITY = '${user}',
        SECRET = '${secret}'
    ;
END

%{ for container in containers ~}
IF (SELECT COUNT(*)
FROM sys.external_data_sources
WHERE name = 'fs${container}${data_lake_name}') = 0
BEGIN
    CREATE EXTERNAL DATA SOURCE fs${container}${data_lake_name}
    WITH (
        TYPE = HADOOP,
        LOCATION='abfss://fs${container}${data_lake_name}@${account_name}.dfs.core.windows.net',
        CREDENTIAL = ADLSCredential
    );
END
%{ endfor ~}