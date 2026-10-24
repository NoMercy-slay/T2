USE ElectroHogarNorte_BI_Origen;
GO
-- Ejecutar después de 04, sin transacciones externas y como propietario de la BD.
-- Los casos correctos se revierten. Las secuencias IDENTITY pueden dejar huecos, lo cual es normal.
SET NOCOUNT ON;
DECLARE @l dbo.LineasDocumento, @p dbo.LineasPago;
DECLARE @antes bigint=(SELECT COUNT_BIG(*) FROM dbo.Ventas);
INSERT @l VALUES(1,1,2000,0,0.18);
INSERT @p VALUES(1,2360,'PRUEBA');

BEGIN TRY
 EXEC dbo.usp_RegistrarVenta 'TEST-ROL',1,2,1,'2026-01-01','BOLETA',@l,@p;
 THROW 50999,'FALLO: se acepto rechazo de rol.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN(50111) THROW;
 PRINT N'OK: rechazo de rol';
END CATCH;

BEGIN TRY
 EXEC dbo.usp_RegistrarVenta 'TEST-CLIENTE',999999,6,1,'2026-01-01','BOLETA',@l,@p;
 THROW 50999,'FALLO: se acepto cliente inexistente.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN(50112) THROW;
 PRINT N'OK: cliente inexistente';
END CATCH;

BEGIN TRY
 EXEC dbo.usp_RegistrarVenta 'TEST-RUC',1,6,1,'2026-01-01','FACTURA',@l,@p;
 THROW 50999,'FALLO: se acepto factura sin RUC.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN(50113) THROW;
 PRINT N'OK: factura sin RUC';
END CATCH;

BEGIN TRY
 EXEC dbo.usp_RegistrarVenta 'TEST-FECHA',1,6,1,'2022-01-01','BOLETA',@l,@p;
 THROW 50999,'FALLO: se acepto fecha retroactiva.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN(50106) THROW;
 PRINT N'OK: fecha retroactiva';
END CATCH;

BEGIN TRY
 EXEC dbo.usp_RegistrarVenta 'V-0000001',1,6,1,'2026-01-01','BOLETA',@l,@p;
 THROW 50999,'FALLO: se acepto numero duplicado.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN(2601,2627) THROW;
 PRINT N'OK: numero duplicado';
END CATCH;

BEGIN TRY
 EXEC dbo.usp_AjustarInventario 1,1,4,'2026-01-01',-1000000,N'Prueba negativa de inventario';
 THROW 50999,'FALLO: se acepto ajuste negativo.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN(50124) THROW;
 PRINT N'OK: ajuste negativo';
END CATCH;
DELETE FROM @p; INSERT @p VALUES(1,1,'PRUEBA');

BEGIN TRY
 EXEC dbo.usp_RegistrarVenta 'TEST-PAGO',1,6,1,'2026-01-01','BOLETA',@l,@p;
 THROW 50999,'FALLO: se acepto pago incompleto.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN(50115) THROW;
 PRINT N'OK: pago incompleto';
END CATCH;
DELETE FROM @l; INSERT @l VALUES(1,1000000,2000,0,0.18);

BEGIN TRY
 EXEC dbo.usp_RegistrarVenta 'TEST-STOCK',1,6,1,'2026-01-01','BOLETA',@l,@p;
 THROW 50999,'FALLO: se acepto stock insuficiente.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN(50114) THROW;
 PRINT N'OK: stock insuficiente';
END CATCH;
DELETE FROM @l; INSERT @l VALUES(1,1,2000,0,0.18);

BEGIN TRY
 EXEC dbo.usp_RegistrarCompra 'TEST-PROV',2,2,4,1,'2026-01-01','TEST-PROV',@l;
 THROW 50999,'FALLO: se acepto proveedor sin producto.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() NOT IN(50110) THROW;
 PRINT N'OK: proveedor sin producto';
END CATCH;

IF (SELECT COUNT_BIG(*) FROM dbo.Ventas)<>@antes THROW 50998,'Las pruebas negativas dejaron ventas.',1;
DELETE FROM @p; INSERT @p VALUES(1,1000,'PRUEBA'),(4,1360,'PRUEBA');
BEGIN TRANSACTION;
DECLARE @stock int=(SELECT stock FROM dbo.Inventario WHERE id_almacen=1 AND id_producto=1);
EXEC dbo.usp_RegistrarVenta 'TEST-OK',1,6,1,'2026-01-01','BOLETA',@l,@p;
IF (SELECT stock FROM dbo.Inventario WHERE id_almacen=1 AND id_producto=1)<>@stock-1
BEGIN
 ROLLBACK;
 THROW 50997,'La venta no descontó inventario.',1;
END;
ROLLBACK;
IF (SELECT stock FROM dbo.Inventario WHERE id_almacen=1 AND id_producto=1)<>@stock THROW 50996,'Rollback no restauro el inventario.',1;
PRINT N'OK: venta con pago mixto y rollback.';
GO
