-- ElectroHogarNorte OLTP v2. Datos y credenciales exclusivamente de demostración.
-- Ejecutar 01, 02, 03, 04, 05 en ese orden. No elimina ni migra la base antigua.
USE master;
GO
IF DB_ID(N'ElectroHogarNorte_BI_Origen') IS NULL
    EXEC(N'CREATE DATABASE ElectroHogarNorte_BI_Origen');
GO
USE ElectroHogarNorte_BI_Origen;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO
-- Si hay objetos previos, detenerse. Nunca sobrescribe una instalación existente.
IF EXISTS (SELECT 1 FROM sys.tables WHERE is_ms_shipped=0)
    THROW 50000, 'La base ya contiene tablas. No vuelva a ejecutar 01 sobre ella.', 1;
BEGIN TRANSACTION;
CREATE TABLE dbo.Roles (
id_rol tinyint PRIMARY KEY, nombre nvarchar(40) NOT NULL UNIQUE,
CHECK ((id_rol=1 AND nombre=N'Administrador') OR (id_rol=2 AND nombre=N'Encargado de Compras') OR (id_rol=3 AND nombre=N'Almacenero') OR (id_rol=4 AND nombre=N'Cajero'))
);

CREATE TABLE dbo.Usuarios (
id_usuario int PRIMARY KEY, correo varchar(254) COLLATE Latin1_General_100_CI_AS NOT NULL UNIQUE,
nombres nvarchar(100) NOT NULL, apellidos nvarchar(100) NOT NULL,
id_rol tinyint NOT NULL REFERENCES dbo.Roles(id_rol), activo bit NOT NULL DEFAULT 1,
contrasena_hash varbinary(32) NOT NULL, contrasena_salt varbinary(32) NOT NULL,
contrasena_algoritmo varchar(30) NOT NULL DEFAULT 'PBKDF2-HMAC-SHA256', iteraciones int NOT NULL DEFAULT 600000,
cambiar_contrasena bit NOT NULL DEFAULT 1, intentos_fallidos int NOT NULL DEFAULT 0,
bloqueado_hasta datetime2(0) NULL, fecha_registro datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), fecha_modificacion datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), version_fila rowversion,
CHECK (correo=LOWER(LTRIM(RTRIM(correo))) COLLATE Latin1_General_100_BIN2 AND correo LIKE '%_@_%._%' AND correo NOT LIKE '% %'),
CHECK (DATALENGTH(contrasena_hash)=32 AND DATALENGTH(contrasena_salt)=32),
CHECK (contrasena_algoritmo='PBKDF2-HMAC-SHA256' AND iteraciones>=600000 AND intentos_fallidos>=0)
);

CREATE TABLE dbo.Categorias (
id_categoria int PRIMARY KEY, nombre nvarchar(100) NOT NULL UNIQUE, activo bit NOT NULL DEFAULT 1, fecha_registro datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), fecha_modificacion datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), version_fila rowversion
);

CREATE TABLE dbo.Marcas (
id_marca int PRIMARY KEY, nombre nvarchar(100) NOT NULL UNIQUE, activo bit NOT NULL DEFAULT 1, fecha_registro datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), fecha_modificacion datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), version_fila rowversion
);

CREATE TABLE dbo.Proveedores (
id_proveedor int PRIMARY KEY, ruc char(11) NOT NULL UNIQUE, razon_social nvarchar(150) NOT NULL, correo varchar(254) NOT NULL, ciudad nvarchar(60) NOT NULL, activo bit NOT NULL DEFAULT 1, fecha_registro datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), fecha_modificacion datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), version_fila rowversion, CHECK (ruc NOT LIKE '%[^0-9]%')
);

CREATE TABLE dbo.Clientes (
id_cliente int PRIMARY KEY, tipo_documento varchar(3) NOT NULL, numero_documento varchar(20) NOT NULL, nombres nvarchar(150) NOT NULL, distrito nvarchar(80) NOT NULL, correo varchar(254) NULL, activo bit NOT NULL DEFAULT 1, fecha_registro datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), fecha_modificacion datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), version_fila rowversion, UNIQUE(tipo_documento,numero_documento), CHECK ((tipo_documento='DNI' AND LEN(numero_documento)=8 AND numero_documento NOT LIKE '%[^0-9]%') OR (tipo_documento='RUC' AND LEN(numero_documento)=11 AND numero_documento NOT LIKE '%[^0-9]%') OR (tipo_documento='CE' AND LEN(numero_documento) BETWEEN 9 AND 12))
);

CREATE TABLE dbo.Productos (
id_producto int PRIMARY KEY, codigo varchar(30) NOT NULL UNIQUE, codigo_barras varchar(50) NULL,
nombre nvarchar(150) NOT NULL, id_categoria int NOT NULL REFERENCES dbo.Categorias(id_categoria),
id_marca int NOT NULL REFERENCES dbo.Marcas(id_marca), precio_lista decimal(12,2) NOT NULL CHECK(precio_lista>0),
garantia_meses smallint NOT NULL CHECK(garantia_meses>=0), activo bit NOT NULL DEFAULT 1, fecha_registro datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), fecha_modificacion datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), version_fila rowversion
);

CREATE TABLE dbo.Producto_Proveedor (
id_producto int NOT NULL REFERENCES dbo.Productos(id_producto), id_proveedor int NOT NULL REFERENCES dbo.Proveedores(id_proveedor), codigo_proveedor varchar(40) NOT NULL, PRIMARY KEY(id_producto,id_proveedor)
);

CREATE TABLE dbo.Almacenes (
id_almacen int PRIMARY KEY, nombre nvarchar(100) NOT NULL UNIQUE, direccion nvarchar(200) NOT NULL, activo bit NOT NULL DEFAULT 1
);

CREATE TABLE dbo.Inventario (
id_almacen int NOT NULL REFERENCES dbo.Almacenes(id_almacen), id_producto int NOT NULL REFERENCES dbo.Productos(id_producto), stock int NOT NULL DEFAULT 0 CHECK(stock>=0), stock_minimo int NOT NULL DEFAULT 5 CHECK(stock_minimo>=0), costo_promedio decimal(14,4) NOT NULL DEFAULT 0 CHECK(costo_promedio>=0), fecha_registro datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), fecha_modificacion datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), version_fila rowversion, PRIMARY KEY(id_almacen,id_producto)
);

CREATE TABLE dbo.Metodos_Pago (
id_metodo tinyint PRIMARY KEY, nombre nvarchar(40) NOT NULL UNIQUE, activo bit NOT NULL DEFAULT 1
);

CREATE TABLE dbo.Compras (
id_compra bigint IDENTITY PRIMARY KEY, numero_compra varchar(40) NOT NULL UNIQUE,
id_proveedor int NOT NULL REFERENCES dbo.Proveedores(id_proveedor),
id_usuario int NOT NULL REFERENCES dbo.Usuarios(id_usuario), id_receptor int NOT NULL REFERENCES dbo.Usuarios(id_usuario),
id_almacen int NOT NULL REFERENCES dbo.Almacenes(id_almacen), fecha_compra datetime2(0) NOT NULL,
comprobante varchar(50) NOT NULL, moneda char(3) NOT NULL DEFAULT 'PEN' CHECK(moneda='PEN'),
subtotal decimal(16,2) NOT NULL CHECK(subtotal>=0), impuesto decimal(16,2) NOT NULL CHECK(impuesto>=0),
total AS (subtotal+impuesto) PERSISTED, fecha_registro datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), fecha_modificacion datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), version_fila rowversion, UNIQUE(id_proveedor,comprobante)
);

CREATE TABLE dbo.Detalle_Compras (
id_detalle_compra bigint IDENTITY PRIMARY KEY, id_compra bigint NOT NULL REFERENCES dbo.Compras(id_compra),
id_producto int NOT NULL REFERENCES dbo.Productos(id_producto), cantidad int NOT NULL CHECK(cantidad>0),
precio_unitario decimal(12,2) NOT NULL CHECK(precio_unitario>0), descuento decimal(14,2) NOT NULL DEFAULT 0,
tasa_impuesto decimal(5,4) NOT NULL CHECK(tasa_impuesto BETWEEN 0 AND 1),
subtotal AS CONVERT(decimal(16,2),cantidad*precio_unitario-descuento) PERSISTED,
impuesto AS CONVERT(decimal(16,2),ROUND((cantidad*precio_unitario-descuento)*tasa_impuesto,2)) PERSISTED,
UNIQUE(id_compra,id_producto), CHECK(descuento>=0 AND descuento<cantidad*precio_unitario)
);

CREATE TABLE dbo.Ventas (
id_venta bigint IDENTITY PRIMARY KEY, numero_venta varchar(40) NOT NULL UNIQUE,
id_cliente int NOT NULL REFERENCES dbo.Clientes(id_cliente), id_usuario int NOT NULL REFERENCES dbo.Usuarios(id_usuario),
id_almacen int NOT NULL REFERENCES dbo.Almacenes(id_almacen), fecha_venta datetime2(0) NOT NULL,
tipo_comprobante varchar(10) NOT NULL CHECK(tipo_comprobante IN ('BOLETA','FACTURA')),
moneda char(3) NOT NULL DEFAULT 'PEN' CHECK(moneda='PEN'),
subtotal decimal(16,2) NOT NULL CHECK(subtotal>=0), impuesto decimal(16,2) NOT NULL CHECK(impuesto>=0),
total AS (subtotal+impuesto) PERSISTED, fecha_registro datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), fecha_modificacion datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), version_fila rowversion
);

CREATE TABLE dbo.Detalle_Ventas (
id_detalle_venta bigint IDENTITY PRIMARY KEY, id_venta bigint NOT NULL REFERENCES dbo.Ventas(id_venta),
id_producto int NOT NULL REFERENCES dbo.Productos(id_producto), cantidad int NOT NULL CHECK(cantidad>0),
precio_unitario decimal(12,2) NOT NULL CHECK(precio_unitario>0), descuento decimal(14,2) NOT NULL DEFAULT 0,
costo_unitario decimal(14,4) NOT NULL CHECK(costo_unitario>=0),
tasa_impuesto decimal(5,4) NOT NULL CHECK(tasa_impuesto BETWEEN 0 AND 1),
subtotal AS CONVERT(decimal(16,2),cantidad*precio_unitario-descuento) PERSISTED,
impuesto AS CONVERT(decimal(16,2),ROUND((cantidad*precio_unitario-descuento)*tasa_impuesto,2)) PERSISTED,
costo_total AS CONVERT(decimal(16,4),cantidad*costo_unitario) PERSISTED,
UNIQUE(id_venta,id_producto), CHECK(descuento>=0 AND descuento<cantidad*precio_unitario)
);

CREATE TABLE dbo.Pagos_Ventas (
id_pago bigint IDENTITY PRIMARY KEY, id_venta bigint NOT NULL REFERENCES dbo.Ventas(id_venta),
id_metodo tinyint NOT NULL REFERENCES dbo.Metodos_Pago(id_metodo), fecha_pago datetime2(0) NOT NULL,
monto decimal(16,2) NOT NULL CHECK(monto>0), referencia varchar(80) NULL
);

CREATE TABLE dbo.Movimientos_Inventario (
id_movimiento bigint IDENTITY PRIMARY KEY, id_almacen int NOT NULL, id_producto int NOT NULL,
id_usuario int NOT NULL REFERENCES dbo.Usuarios(id_usuario), fecha_movimiento datetime2(0) NOT NULL,
tipo varchar(10) NOT NULL CHECK(tipo IN ('COMPRA','VENTA','AJUSTE')),
cantidad int NOT NULL CHECK(cantidad<>0), stock_anterior int NOT NULL CHECK(stock_anterior>=0),
stock_nuevo int NOT NULL CHECK(stock_nuevo>=0), costo_unitario decimal(14,4) NOT NULL CHECK(costo_unitario>=0),
id_detalle_compra bigint NULL REFERENCES dbo.Detalle_Compras(id_detalle_compra),
id_detalle_venta bigint NULL REFERENCES dbo.Detalle_Ventas(id_detalle_venta), motivo nvarchar(250) NOT NULL,
fecha_registro datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
FOREIGN KEY(id_almacen,id_producto) REFERENCES dbo.Inventario(id_almacen,id_producto),
CHECK(stock_nuevo=stock_anterior+cantidad),
CHECK((tipo='COMPRA' AND cantidad>0 AND id_detalle_compra IS NOT NULL AND id_detalle_venta IS NULL)
OR (tipo='VENTA' AND cantidad<0 AND id_detalle_venta IS NOT NULL AND id_detalle_compra IS NULL)
OR (tipo='AJUSTE' AND id_detalle_compra IS NULL AND id_detalle_venta IS NULL))
);

CREATE TABLE dbo.Bitacora_Operaciones (
id_evento bigint IDENTITY PRIMARY KEY, fecha_utc datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(), id_usuario int NOT NULL REFERENCES dbo.Usuarios(id_usuario), operacion varchar(30) NOT NULL, referencia varchar(100) NOT NULL, login_sql nvarchar(128) NOT NULL DEFAULT ORIGINAL_LOGIN()
);

CREATE UNIQUE INDEX UX_Producto_Barras ON dbo.Productos(codigo_barras) WHERE codigo_barras IS NOT NULL;
CREATE UNIQUE INDEX UX_Movimiento_Compra ON dbo.Movimientos_Inventario(id_detalle_compra) WHERE id_detalle_compra IS NOT NULL;
CREATE UNIQUE INDEX UX_Movimiento_Venta ON dbo.Movimientos_Inventario(id_detalle_venta) WHERE id_detalle_venta IS NOT NULL;
CREATE INDEX IX_Venta_Fecha ON dbo.Ventas(fecha_venta) INCLUDE(id_cliente,id_usuario,id_almacen,subtotal,impuesto);
CREATE INDEX IX_Compra_Fecha ON dbo.Compras(fecha_compra) INCLUDE(id_proveedor,id_almacen,subtotal,impuesto);
CREATE INDEX IX_DV_Producto ON dbo.Detalle_Ventas(id_producto,id_venta);
CREATE INDEX IX_DC_Producto ON dbo.Detalle_Compras(id_producto,id_compra);
CREATE INDEX IX_Pago_Venta ON dbo.Pagos_Ventas(id_venta) INCLUDE(monto);
CREATE INDEX IX_Mov_Producto ON dbo.Movimientos_Inventario(id_almacen,id_producto,fecha_movimiento,id_movimiento) INCLUDE(cantidad,stock_anterior,stock_nuevo);
CREATE INDEX IX_Proveedor_Producto ON dbo.Producto_Proveedor(id_proveedor,id_producto);
COMMIT;
GO
