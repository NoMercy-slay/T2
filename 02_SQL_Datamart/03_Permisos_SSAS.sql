/*
    ELECTROHOGARNORTE - T2
    03_Permisos_SSAS.sql

    Objetivo: permitir que la cuenta del servicio SSAS lea las seis tablas
    de ElectroHogarNorte_DM para procesar el cubo.

    Ejecutar desde SSMS, conectado al MOTOR DE BASE DE DATOS, con permisos
    para crear logins, usuarios y conceder SELECT. No es una consulta MDX.
    Ejecutar despues de 01_Estructura_DM.sql y antes de procesar el cubo.

    Configuracion del proyecto: SQL Server y SSAS en el mismo equipo Windows;
    instancia SSAS predeterminada, con el origen de datos configurado para
    usar la cuenta del servicio.

    En otro equipo, confirmar la cuenta de inicio de SSAS y ajustar
    @CuentaSSAS si es distinta. SSAS debe estar instalado para que Windows
    pueda resolver su cuenta virtual. Para servidores separados, configurar
    una identidad Windows que pueda autenticarse en el servidor SQL remoto.

    Se crean el login y el usuario solo si faltan. Si el usuario Windows
    existe con un SID distinto, se vuelve a vincular al login indicado.
    Se conceden seis permisos SELECT; no se revocan permisos preexistentes.
    No cambia tablas ni datos comerciales y no usa contrasenas.

    Archivo preparado para reconstruccion; no se ha ejecutado desde este chat.
*/

USE [master];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Cuenta confirmada en el equipo del proyecto.
DECLARE @CuentaSSAS sysname = N'NT Service\MSSQLServerOLAPService';
DECLARE @CuentaDelimitada nvarchar(258) = QUOTENAME(@CuentaSSAS);
DECLARE @Sql nvarchar(max);

IF @CuentaDelimitada IS NULL OR LEN(LTRIM(RTRIM(@CuentaSSAS))) = 0
BEGIN
    THROW 50311, N'Indique una cuenta Windows valida para SSAS.', 1;
END;

IF DB_ID(N'ElectroHogarNorte_DM') IS NULL
BEGIN
    THROW 50312, N'Primero debe crear ElectroHogarNorte_DM con 01_Estructura_DM.sql.', 1;
END;

IF EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE [name] = @CuentaSSAS AND [type] NOT IN ('U', 'G')
)
BEGIN
    THROW 50313, N'El nombre indicado ya pertenece a un login que no es Windows. Revise @CuentaSSAS.', 1;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM sys.server_principals WHERE [name] = @CuentaSSAS
    )
    BEGIN
        SET @Sql = N'CREATE LOGIN ' + @CuentaDelimitada + N' FROM WINDOWS;';
        EXEC sys.sp_executesql @Sql;
    END;

    SET @Sql = N'USE [ElectroHogarNorte_DM];

    IF EXISTS (
        SELECT 1
        FROM (VALUES
            (N''DimAlmacen''), (N''DimCliente''), (N''DimFecha''),
            (N''DimProducto''), (N''DimUsuario''), (N''FactVenta'')
        ) AS requeridas(Tabla)
        WHERE OBJECT_ID(N''dbo.'' + QUOTENAME(requeridas.Tabla), N''U'') IS NULL
    )
    BEGIN
        THROW 50314, N''Faltan tablas del Datamart. Complete 01_Estructura_DM.sql.'', 1;
    END;

    IF EXISTS (
        SELECT 1 FROM sys.database_principals
        WHERE [name] = @CuentaSSAS AND [type] NOT IN (''U'', ''G'')
    )
    BEGIN
        THROW 50315, N''El usuario existente no es Windows. Revise @CuentaSSAS.'', 1;
    END;

    DECLARE @ComandoUsuario nvarchar(max);

    IF NOT EXISTS (
        SELECT 1 FROM sys.database_principals WHERE [name] = @CuentaSSAS
    )
    BEGIN
        SET @ComandoUsuario = N''CREATE USER '' + QUOTENAME(@CuentaSSAS)
            + N'' FOR LOGIN '' + QUOTENAME(@CuentaSSAS)
            + N'' WITH DEFAULT_SCHEMA = [dbo];'';
        EXEC sys.sp_executesql @ComandoUsuario;
    END
    ELSE IF EXISTS (
        SELECT 1 FROM sys.database_principals
        WHERE [name] = @CuentaSSAS AND [sid] <> SUSER_SID(@CuentaSSAS)
    )
    BEGIN
        SET @ComandoUsuario = N''ALTER USER '' + QUOTENAME(@CuentaSSAS)
            + N'' WITH LOGIN = '' + QUOTENAME(@CuentaSSAS) + N'';'';
        EXEC sys.sp_executesql @ComandoUsuario;
    END;

    GRANT SELECT ON OBJECT::[dbo].[DimAlmacen]  TO ' + @CuentaDelimitada + N';
    GRANT SELECT ON OBJECT::[dbo].[DimCliente]  TO ' + @CuentaDelimitada + N';
    GRANT SELECT ON OBJECT::[dbo].[DimFecha]    TO ' + @CuentaDelimitada + N';
    GRANT SELECT ON OBJECT::[dbo].[DimProducto] TO ' + @CuentaDelimitada + N';
    GRANT SELECT ON OBJECT::[dbo].[DimUsuario]  TO ' + @CuentaDelimitada + N';
    GRANT SELECT ON OBJECT::[dbo].[FactVenta]   TO ' + @CuentaDelimitada + N';';

    EXEC sys.sp_executesql @Sql, N'@CuentaSSAS sysname', @CuentaSSAS = @CuentaSSAS;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT N'No se completo la configuracion. Revise la cuenta de inicio del servicio SSAS y los permisos del ejecutor.';
    THROW;
END CATCH;

-- Mostrar los permisos SELECT directos concedidos sobre las seis tablas.
-- Esta salida comprueba la concesion, no sustituye la prueba de procesar el cubo.
SET @Sql = N'USE [ElectroHogarNorte_DM];
SELECT
    u.[name] AS CuentaSSAS,
    s.[name] AS Esquema,
    t.[name] AS Tabla,
    p.[permission_name] AS Permiso,
    p.[state_desc] AS Estado
FROM sys.database_permissions AS p
INNER JOIN sys.database_principals AS u ON u.principal_id = p.grantee_principal_id
INNER JOIN sys.tables AS t ON t.object_id = p.major_id
INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE u.[name] = @CuentaSSAS
  AND p.[class] = 1
  AND p.minor_id = 0
  AND p.[permission_name] = N''SELECT''
  AND s.[name] = N''dbo''
  AND t.[name] IN (N''DimAlmacen'', N''DimCliente'', N''DimFecha'',
                  N''DimProducto'', N''DimUsuario'', N''FactVenta'')
ORDER BY t.[name];';

EXEC sys.sp_executesql @Sql, N'@CuentaSSAS sysname', @CuentaSSAS = @CuentaSSAS;
PRINT N'Configuracion de permisos SSAS completada. El siguiente control es procesar el cubo con su cuenta de servicio.';
GO
