USE ElectroHogarNorte_BI_Origen;
GO
CREATE TYPE dbo.LineasDocumento AS TABLE (
 id_producto int PRIMARY KEY, cantidad int NOT NULL CHECK(cantidad>0),
 precio_unitario decimal(12,2) NOT NULL CHECK(precio_unitario>0),
 descuento decimal(14,2) NOT NULL CHECK(descuento>=0),
 tasa_impuesto decimal(5,4) NOT NULL CHECK(tasa_impuesto BETWEEN 0 AND 1)
);
GO
CREATE TYPE dbo.LineasPago AS TABLE (
 id_metodo tinyint NOT NULL, monto decimal(16,2) NOT NULL CHECK(monto>0), referencia varchar(80) NULL
);
GO
CREATE PROCEDURE dbo.usp_RegistrarCompra
 @numero varchar(40), @proveedor int, @usuario int, @receptor int, @almacen int,
 @fecha datetime2(0), @comprobante varchar(50), @lineas dbo.LineasDocumento READONLY
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @lock int;
 EXEC @lock=sys.sp_getapplock @Resource=N'EHN_Inventario', @LockMode='Exclusive', @LockOwner='Transaction', @LockTimeout=15000;
 IF @lock<0 THROW 50100, 'No se pudo bloquear el inventario; reintente.', 1;
 IF @numero IS NULL OR LEN(LTRIM(RTRIM(@numero)))=0 THROW 50100, 'Numero de documento obligatorio.', 1;
 IF NOT EXISTS(SELECT 1 FROM @lineas) THROW 50101, 'El documento necesita detalles.', 1;
 IF EXISTS(SELECT 1 FROM @lineas WHERE descuento>=cantidad*precio_unitario) THROW 50102, 'Descuento invalido.', 1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Almacenes WHERE id_almacen=@almacen AND activo=1) THROW 50103, 'Almacen inactivo o inexistente.', 1;
 IF EXISTS(SELECT 1 FROM @lineas l LEFT JOIN dbo.Productos p ON p.id_producto=l.id_producto
 LEFT JOIN dbo.Inventario i ON i.id_producto=l.id_producto AND i.id_almacen=@almacen
 WHERE p.id_producto IS NULL OR p.activo=0 OR i.id_producto IS NULL) THROW 50104, 'Producto inactivo o sin inventario inicializado.', 1;
 IF @fecha IS NULL OR @fecha>SYSDATETIME() THROW 50105, 'Fecha invalida.', 1;
 IF EXISTS(SELECT 1 FROM dbo.Movimientos_Inventario m JOIN @lineas l ON l.id_producto=m.id_producto
 WHERE m.id_almacen=@almacen AND m.fecha_movimiento>@fecha) THROW 50106, 'No se permite retroceder la fecha del inventario.', 1;
 DECLARE @subtotal decimal(16,2), @impuesto decimal(16,2);
 SELECT @subtotal=SUM(CONVERT(decimal(16,2),cantidad*precio_unitario-descuento)),
 @impuesto=SUM(CONVERT(decimal(16,2),ROUND((cantidad*precio_unitario-descuento)*tasa_impuesto,2))) FROM @lineas;

 IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios WHERE id_usuario=@usuario AND activo=1 AND id_rol IN(1,2))
 THROW 50107, 'Solo Administrador o Encargado de Compras registra compras.', 1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios WHERE id_usuario=@receptor AND activo=1 AND id_rol IN(1,3))
 THROW 50108, 'La recepcion necesita un Administrador o Almacenero.', 1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Proveedores WHERE id_proveedor=@proveedor AND activo=1)
 THROW 50109, 'Proveedor inactivo o inexistente.', 1;
 IF EXISTS(SELECT 1 FROM @lineas l WHERE NOT EXISTS(SELECT 1 FROM dbo.Producto_Proveedor pp
 WHERE pp.id_producto=l.id_producto AND pp.id_proveedor=@proveedor)) THROW 50110, 'Proveedor no vinculado al producto.', 1;
 INSERT dbo.Compras(numero_compra,id_proveedor,id_usuario,id_receptor,id_almacen,fecha_compra,comprobante,subtotal,impuesto)
 VALUES(@numero,@proveedor,@usuario,@receptor,@almacen,@fecha,@comprobante,@subtotal,@impuesto);
 DECLARE @id bigint=CONVERT(bigint,SCOPE_IDENTITY());
 INSERT dbo.Detalle_Compras(id_compra,id_producto,cantidad,precio_unitario,descuento,tasa_impuesto)
 SELECT @id,id_producto,cantidad,precio_unitario,descuento,tasa_impuesto FROM @lineas;
 INSERT dbo.Movimientos_Inventario(id_almacen,id_producto,id_usuario,fecha_movimiento,tipo,cantidad,stock_anterior,stock_nuevo,costo_unitario,id_detalle_compra,motivo)
 SELECT @almacen,d.id_producto,@receptor,@fecha,'COMPRA',d.cantidad,i.stock,i.stock+d.cantidad,
 CONVERT(decimal(14,4),d.subtotal/d.cantidad),d.id_detalle_compra,N'Recepcion de compra'
 FROM dbo.Detalle_Compras d JOIN dbo.Inventario i ON i.id_producto=d.id_producto AND i.id_almacen=@almacen WHERE d.id_compra=@id;
 UPDATE i SET costo_promedio=CONVERT(decimal(14,4),(i.stock*i.costo_promedio+d.subtotal)/(i.stock+d.cantidad)),
 stock=i.stock+d.cantidad,fecha_modificacion=SYSUTCDATETIME()
 FROM dbo.Inventario i JOIN dbo.Detalle_Compras d ON d.id_producto=i.id_producto
 WHERE i.id_almacen=@almacen AND d.id_compra=@id;
 INSERT dbo.Bitacora_Operaciones(id_usuario,operacion,referencia) VALUES(@usuario,'COMPRA',@numero);
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
CREATE PROCEDURE dbo.usp_RegistrarVenta
 @numero varchar(40), @cliente int, @usuario int, @almacen int, @fecha datetime2(0),
 @tipo varchar(10), @lineas dbo.LineasDocumento READONLY, @pagos dbo.LineasPago READONLY
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @lock int;
 EXEC @lock=sys.sp_getapplock @Resource=N'EHN_Inventario', @LockMode='Exclusive', @LockOwner='Transaction', @LockTimeout=15000;
 IF @lock<0 THROW 50100, 'No se pudo bloquear el inventario; reintente.', 1;
 IF @numero IS NULL OR LEN(LTRIM(RTRIM(@numero)))=0 THROW 50100, 'Numero de documento obligatorio.', 1;
 IF NOT EXISTS(SELECT 1 FROM @lineas) THROW 50101, 'El documento necesita detalles.', 1;
 IF EXISTS(SELECT 1 FROM @lineas WHERE descuento>=cantidad*precio_unitario) THROW 50102, 'Descuento invalido.', 1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Almacenes WHERE id_almacen=@almacen AND activo=1) THROW 50103, 'Almacen inactivo o inexistente.', 1;
 IF EXISTS(SELECT 1 FROM @lineas l LEFT JOIN dbo.Productos p ON p.id_producto=l.id_producto
 LEFT JOIN dbo.Inventario i ON i.id_producto=l.id_producto AND i.id_almacen=@almacen
 WHERE p.id_producto IS NULL OR p.activo=0 OR i.id_producto IS NULL) THROW 50104, 'Producto inactivo o sin inventario inicializado.', 1;
 IF @fecha IS NULL OR @fecha>SYSDATETIME() THROW 50105, 'Fecha invalida.', 1;
 IF EXISTS(SELECT 1 FROM dbo.Movimientos_Inventario m JOIN @lineas l ON l.id_producto=m.id_producto
 WHERE m.id_almacen=@almacen AND m.fecha_movimiento>@fecha) THROW 50106, 'No se permite retroceder la fecha del inventario.', 1;
 DECLARE @subtotal decimal(16,2), @impuesto decimal(16,2);
 SELECT @subtotal=SUM(CONVERT(decimal(16,2),cantidad*precio_unitario-descuento)),
 @impuesto=SUM(CONVERT(decimal(16,2),ROUND((cantidad*precio_unitario-descuento)*tasa_impuesto,2))) FROM @lineas;

 IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios WHERE id_usuario=@usuario AND activo=1 AND id_rol IN(1,4))
 THROW 50111, 'Solo Administrador o Cajero registra ventas.', 1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Clientes WHERE id_cliente=@cliente AND activo=1)
 THROW 50112, 'Cliente inactivo o inexistente.', 1;
 IF @tipo='FACTURA' AND NOT EXISTS(SELECT 1 FROM dbo.Clientes WHERE id_cliente=@cliente AND tipo_documento='RUC')
 THROW 50113, 'La factura requiere cliente con RUC.', 1;
 IF EXISTS(SELECT 1 FROM @lineas l JOIN dbo.Inventario i ON i.id_producto=l.id_producto AND i.id_almacen=@almacen WHERE i.stock<l.cantidad)
 THROW 50114, 'Stock insuficiente.', 1;
 IF NOT EXISTS(SELECT 1 FROM @pagos) OR (SELECT SUM(monto) FROM @pagos)<>@subtotal+@impuesto
 THROW 50115, 'Los pagos deben cubrir exactamente el total.', 1;
 IF EXISTS(SELECT 1 FROM @pagos p LEFT JOIN dbo.Metodos_Pago m ON m.id_metodo=p.id_metodo WHERE m.id_metodo IS NULL OR m.activo=0)
 THROW 50116, 'Metodo de pago invalido.', 1;
 INSERT dbo.Ventas(numero_venta,id_cliente,id_usuario,id_almacen,fecha_venta,tipo_comprobante,subtotal,impuesto)
 VALUES(@numero,@cliente,@usuario,@almacen,@fecha,@tipo,@subtotal,@impuesto);
 DECLARE @id bigint=CONVERT(bigint,SCOPE_IDENTITY());
 INSERT dbo.Detalle_Ventas(id_venta,id_producto,cantidad,precio_unitario,descuento,costo_unitario,tasa_impuesto)
 SELECT @id,l.id_producto,l.cantidad,l.precio_unitario,l.descuento,i.costo_promedio,l.tasa_impuesto
 FROM @lineas l JOIN dbo.Inventario i ON i.id_producto=l.id_producto AND i.id_almacen=@almacen;
 INSERT dbo.Movimientos_Inventario(id_almacen,id_producto,id_usuario,fecha_movimiento,tipo,cantidad,stock_anterior,stock_nuevo,costo_unitario,id_detalle_venta,motivo)
 SELECT @almacen,d.id_producto,@usuario,@fecha,'VENTA',-d.cantidad,i.stock,i.stock-d.cantidad,d.costo_unitario,d.id_detalle_venta,N'Venta al contado'
 FROM dbo.Detalle_Ventas d JOIN dbo.Inventario i ON i.id_producto=d.id_producto AND i.id_almacen=@almacen WHERE d.id_venta=@id;
 UPDATE i SET stock=i.stock-d.cantidad,fecha_modificacion=SYSUTCDATETIME()
 FROM dbo.Inventario i JOIN dbo.Detalle_Ventas d ON d.id_producto=i.id_producto WHERE i.id_almacen=@almacen AND d.id_venta=@id;
 INSERT dbo.Pagos_Ventas(id_venta,id_metodo,fecha_pago,monto,referencia) SELECT @id,id_metodo,@fecha,monto,referencia FROM @pagos;
 INSERT dbo.Bitacora_Operaciones(id_usuario,operacion,referencia) VALUES(@usuario,'VENTA',@numero);
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
CREATE PROCEDURE dbo.usp_AjustarInventario
 @almacen int, @producto int, @usuario int, @fecha datetime2(0), @cantidad int, @motivo nvarchar(250)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @lock int;
 EXEC @lock=sys.sp_getapplock @Resource=N'EHN_Inventario', @LockMode='Exclusive', @LockOwner='Transaction', @LockTimeout=15000;
 IF @lock<0 THROW 50100, 'No se pudo bloquear el inventario; reintente.', 1;

 IF @cantidad IS NULL OR @cantidad=0 OR @motivo IS NULL OR LEN(LTRIM(RTRIM(@motivo)))<10
 THROW 50120, 'Indique cantidad distinta de cero y motivo de al menos diez caracteres.', 1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios WHERE id_usuario=@usuario AND activo=1 AND id_rol IN(1,3))
 THROW 50121, 'Solo Administrador o Almacenero ajusta inventario.', 1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Inventario i JOIN dbo.Productos p ON p.id_producto=i.id_producto
 JOIN dbo.Almacenes a ON a.id_almacen=i.id_almacen WHERE i.id_almacen=@almacen AND i.id_producto=@producto AND p.activo=1 AND a.activo=1)
 THROW 50122, 'Inventario no disponible.', 1;
 IF @fecha IS NULL OR @fecha>SYSDATETIME() OR EXISTS(SELECT 1 FROM dbo.Movimientos_Inventario WHERE id_almacen=@almacen AND id_producto=@producto AND fecha_movimiento>@fecha)
 THROW 50123, 'Fecha de ajuste invalida.', 1;
 IF EXISTS(SELECT 1 FROM dbo.Inventario WHERE id_almacen=@almacen AND id_producto=@producto AND stock+@cantidad<0)
 THROW 50124, 'El ajuste dejaria stock negativo.', 1;
 INSERT dbo.Movimientos_Inventario(id_almacen,id_producto,id_usuario,fecha_movimiento,tipo,cantidad,stock_anterior,stock_nuevo,costo_unitario,motivo)
 SELECT @almacen,@producto,@usuario,@fecha,'AJUSTE',@cantidad,stock,stock+@cantidad,costo_promedio,@motivo
 FROM dbo.Inventario WHERE id_almacen=@almacen AND id_producto=@producto;
 UPDATE dbo.Inventario SET stock=stock+@cantidad,fecha_modificacion=SYSUTCDATETIME() WHERE id_almacen=@almacen AND id_producto=@producto;
 INSERT dbo.Bitacora_Operaciones(id_usuario,operacion,referencia) VALUES(@usuario,'AJUSTE',LEFT(@motivo,100));
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
CREATE VIEW dbo.vw_VentasAnaliticas AS
SELECT v.id_venta,d.id_detalle_venta,v.numero_venta,v.fecha_venta,v.id_cliente,c.distrito,
 v.id_usuario,v.id_almacen,d.id_producto,p.id_categoria,p.id_marca,
 d.cantidad,d.precio_unitario,d.descuento,d.subtotal AS venta_neta,d.impuesto,
 d.subtotal+d.impuesto AS total_con_impuesto,d.costo_unitario,d.costo_total,
 CONVERT(decimal(18,4),d.subtotal-d.costo_total) AS margen_bruto,
 v.fecha_modificacion AS cabecera_modificada,d.id_detalle_venta AS clave_origen
FROM dbo.Ventas v JOIN dbo.Detalle_Ventas d ON d.id_venta=v.id_venta
JOIN dbo.Productos p ON p.id_producto=d.id_producto JOIN dbo.Clientes c ON c.id_cliente=v.id_cliente;
GO
CREATE VIEW dbo.vw_StockActual AS
SELECT i.id_almacen,a.nombre AS almacen,i.id_producto,p.codigo,p.nombre,i.stock,i.stock_minimo,i.costo_promedio,
 CONVERT(decimal(18,4),i.stock*i.costo_promedio) AS valor_stock,
 CASE WHEN i.stock=0 THEN 'AGOTADO' WHEN i.stock<=i.stock_minimo THEN 'CRITICO' ELSE 'NORMAL' END AS estado_stock
FROM dbo.Inventario i JOIN dbo.Productos p ON p.id_producto=i.id_producto JOIN dbo.Almacenes a ON a.id_almacen=i.id_almacen;
GO
-- Roles SQL para cuentas técnicas. Los cuatro roles de Usuarios son roles de negocio.
CREATE ROLE ehn_operador;
CREATE ROLE ehn_etl;
GRANT EXECUTE ON dbo.usp_RegistrarCompra TO ehn_operador;
GRANT EXECUTE ON dbo.usp_RegistrarVenta TO ehn_operador;
GRANT EXECUTE ON dbo.usp_AjustarInventario TO ehn_operador;
GRANT EXECUTE ON TYPE::dbo.LineasDocumento TO ehn_operador;
GRANT REFERENCES ON TYPE::dbo.LineasDocumento TO ehn_operador;
GRANT EXECUTE ON TYPE::dbo.LineasPago TO ehn_operador;
GRANT REFERENCES ON TYPE::dbo.LineasPago TO ehn_operador;
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO ehn_operador;
DENY SELECT ON dbo.Usuarios TO ehn_etl;
GRANT SELECT ON dbo.vw_VentasAnaliticas TO ehn_etl;
GRANT SELECT ON dbo.vw_StockActual TO ehn_etl;
GO
CREATE VIEW dbo.vw_UsuariosETL AS
SELECT id_usuario,nombres,apellidos,id_rol,activo,fecha_registro,fecha_modificacion FROM dbo.Usuarios;
GO
GRANT SELECT ON dbo.vw_UsuariosETL TO ehn_etl;
GRANT SELECT ON dbo.Roles TO ehn_etl;
GRANT SELECT ON dbo.Categorias TO ehn_etl;
GRANT SELECT ON dbo.Marcas TO ehn_etl;
GRANT SELECT ON dbo.Proveedores TO ehn_etl;
GRANT SELECT ON dbo.Clientes TO ehn_etl;
GRANT SELECT ON dbo.Productos TO ehn_etl;
GRANT SELECT ON dbo.Producto_Proveedor TO ehn_etl;
GRANT SELECT ON dbo.Almacenes TO ehn_etl;
GRANT SELECT ON dbo.Inventario TO ehn_etl;
GRANT SELECT ON dbo.Metodos_Pago TO ehn_etl;
GRANT SELECT ON dbo.Compras TO ehn_etl;
GRANT SELECT ON dbo.Detalle_Compras TO ehn_etl;
GRANT SELECT ON dbo.Ventas TO ehn_etl;
GRANT SELECT ON dbo.Detalle_Ventas TO ehn_etl;
GRANT SELECT ON dbo.Pagos_Ventas TO ehn_etl;
GRANT SELECT ON dbo.Movimientos_Inventario TO ehn_etl;
GO
