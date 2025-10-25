+++
title = 'Mssql Database Restore'
date = 2025-10-19T17:12:58-06:00
draft = true
description = 'Restore a MSSQL database from a bak file'
summary = 'Restore a MSSQL database from a backup file'
+++

# Microsoft SQL Server Database Restore

SQL Server stores backups in a `bak` format. Currently Linux does not have
a utility for extracting the schema and data from this files we have to use
an SQL Server instance.

## Start SQL server container

Use the SQL Server container image to avoid installing it system wide.

```bash
user@host ~$ podman run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=$PASSWORD" \
   -p 1433:1433 --name sql1 --hostname sql1 -d    \
   -v ./files:/files:Z                            \
   mcr.microsoft.com/mssql/server:2025-latest
```

## Verify the container environment

```bash
user@host ~$ podman exec -it sql1 "bash"

```

## Start an `sqlcmd` session inside the container

```bash
user@host ~$ podman exec -it sql1 /opt/mssql-tools18/bin/sqlcmd -No -S localhost -U sa -P $PASSWORD
```

## Restore the backup file

To avoid problems with the file paths use the `MOVE` option.

```sql
RESTORE DATABASE gourmet FROM DISK = N'/files/my_sql_backup.bak'
    WITH FILE = 1,
    NOUNLOAD,
    REPLACE,
    NORECOVERY,
    STATS = 5
    MOVE N'gourmet' TO N'/var/opt/mssql/data/imcsk8.mdf'
    MOVE N'gourmet_log' TO N'/var/opt/mssql/data/imcsk8_log.LDF';
```

```sql
RESTORE DATABASE imcsk8 WITH RECOVERY;
```

Enter the database
```sql
USE imcsk8;
GO
```

Verify that the tables exist

```sql
select name from sys.Tables;
GO
```

# References
* https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver17&tabs=cli&pivots=cs1-bash
* https://learn.microsoft.com/es-es/sql/linux/sql-server-linux-backup-and-restore-database?view=sql-server-ver17
