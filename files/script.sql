IF (SELECT COUNT(*)
FROM sys.symmetric_keys
WHERE name LIKE '%DatabaseMasterKey%') = 0
BEGIN
    CREATE MASTER KEY
END