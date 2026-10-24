/*
    ELECTROHOGARNORTE - T2
    01_JOB_ETL_ElectroHogarNorte.sql

    Exportacion del trabajo configurado en ROB: 24/10/2026 00:21:18.
    Revisado a partir del script compartido por el equipo.
    Se conservan los comandos, pasos, propietario y horarios de la exportacion.
    Se agrega una comprobacion inicial: si el trabajo ya existe, termina sin
    modificarlo. Para cambiar un trabajo existente se usa su configuracion en SSMS.

    Reconstruccion: ejecutar conectado al Motor de base de datos desde SSMS,
    con una cuenta administradora, despues de preparar:
      - El origen y ElectroHogarNorte_DM, con el calendario y conexiones SSIS.
      - SSISDB, carpeta ElectroHogarNorte, proyecto T2 y Package.dtsx desplegado.
      - La base SSAS ElectroHogarNorte_OLAP desplegada.
      - Los permisos SQL de la cuenta SSAS (03_Permisos_SSAS.sql).
      - El rol SSAS Rol_Procesamiento_Agent, con procesamiento de la base y
        lectura de definicion, y la cuenta del servicio SQL Server Agent
        agregada. En el equipo del proyecto: NT SERVICE\SQLSERVERAGENT.
      - SQL Server Agent en ejecucion.

    Referencias propias del entorno original que deben adaptarse al migrar:
      1. @owner_login_name = N'Rob\SIayM': login propietario existente en destino.
         Conservar el esquema de ejecucion por la cuenta del servicio Agent,
         con propietario sysadmin; otro esquema requiere configurar un proxy.
      2. /SERVER Rob en el comando del paso SSIS: instancia del Motor/SSISDB.
      3. @server = N'ROB' en Procesar_Cubo_OLAP: instancia de Analysis Services.
      4. Ruta SSISDB y DatabaseID OLAP, si cambia el nombre de la implementacion.
      5. Las cuentas Windows de los servicios, si son distintas en destino.

    Horarios del servidor SQL Agent:
      - Diario_0800: diario, 08:00:00, habilitado.
      - PRUEBA_T2_AUTOMATIZACION: 23/10/2026, 22:22:00, deshabilitado.
        Se conserva como referencia de la prueba ya realizada.
    En otro equipo, comprobar su zona horaria y adaptar fecha/hora de una
    nueva prueba programada si se desea repetirla.

    Este archivo recrea la definicion. No exporta el historial de ejecuciones
    ni despliega los proyectos SSIS/SSAS. Conservar esas evidencias y archivos.
    No se ha ejecutado este script en SQL Server desde este chat.
*/

USE [msdb]
GO

/****** Objeto: Job [JOB_ETL_ElectroHogarNorte] Fecha de script: 24/10/2026 0:21:18 ******/
-- Conservar el trabajo existente en la instancia de demostracion.
IF EXISTS (
    SELECT 1 FROM msdb.dbo.sysjobs
    WHERE [name] = N'JOB_ETL_ElectroHogarNorte'
)
BEGIN
    PRINT N'El trabajo JOB_ETL_ElectroHogarNorte ya existe. No se ha modificado.';
    RETURN;
END;

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Objeto: JobCategory [[Uncategorized (Local)]] Fecha de script: 24/10/2026 0:21:18 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'JOB_ETL_ElectroHogarNorte', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Carga de dimensiones y ventas al Datamart', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'Rob\SIayM', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Objeto: Step [Ejecutar_ETL] Fecha de script: 24/10/2026 0:21:18 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Ejecutar_ETL', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\ElectroHogarNorte\T2\Package.dtsx\"" /SERVER Rob /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Objeto: Step [Procesar_Cubo_OLAP] Fecha de script: 24/10/2026 0:21:18 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Procesar_Cubo_OLAP', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'<Batch xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Parallel>
    <Process xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ddl2="http://schemas.microsoft.com/analysisservices/2003/engine/2" xmlns:ddl2_2="http://schemas.microsoft.com/analysisservices/2003/engine/2/2" xmlns:ddl100_100="http://schemas.microsoft.com/analysisservices/2008/engine/100/100" xmlns:ddl200="http://schemas.microsoft.com/analysisservices/2010/engine/200" xmlns:ddl200_200="http://schemas.microsoft.com/analysisservices/2010/engine/200/200" xmlns:ddl300="http://schemas.microsoft.com/analysisservices/2011/engine/300" xmlns:ddl300_300="http://schemas.microsoft.com/analysisservices/2011/engine/300/300" xmlns:ddl400="http://schemas.microsoft.com/analysisservices/2012/engine/400" xmlns:ddl400_400="http://schemas.microsoft.com/analysisservices/2012/engine/400/400" xmlns:ddl500="http://schemas.microsoft.com/analysisservices/2013/engine/500" xmlns:ddl500_500="http://schemas.microsoft.com/analysisservices/2013/engine/500/500">
      <Object>
        <DatabaseID>ElectroHogarNorte_OLAP</DatabaseID>
      </Object>
      <Type>ProcessFull</Type>
      <WriteBackTableCreation>UseExisting</WriteBackTableCreation>
    </Process>
  </Parallel>
</Batch>', 
		@server=N'ROB', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Diario_0800', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20261014, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=235959, 
		@schedule_uid=N'08144c8c-e4a5-4a67-99e8-e09e3cd3d43b'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'PRUEBA_T2_AUTOMATIZACION', 
		@enabled=0, 
		@freq_type=1, 
		@freq_interval=0, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20261023, 
		@active_end_date=99991231, 
		@active_start_time=222200, 
		@active_end_time=235959, 
		@schedule_uid=N'aa7b930a-0af5-4959-bc8c-f5ba8684f862'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
