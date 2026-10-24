/* ElectroHogarNorte - T2. Validacion EXP-01 / evidencia E-06.
   Ejecutar en una consulta del MOTOR de SQL Server desde SSMS.
   Solo consulta datos: no crea, modifica ni elimina objetos o registros.
   Compara todo el periodo del conjunto (2023-2025), sin filtros comerciales.
   Primera cuadricula: totales de origen y Datamart.
   Segunda cuadricula: faltantes, sobrantes y detalles con diferencias en
   identificadores, numero de venta, fechas, cantidades e importes comparados.
   Guardar ambas salidas como evidencia. Este archivo no se ha ejecutado
   en el servidor del equipo desde este chat.
*/
USE [ElectroHogarNorte_DM];
GO
SET NOCOUNT ON;

-- 1. Totales comparables al mismo grano: una fila por detalle de venta.
SELECT
    N'Origen' AS Capa,
    COUNT_BIG(*) AS Detalles,
    COUNT_BIG(DISTINCT id_detalle_venta) AS DetallesUnicos,
    COUNT_BIG(DISTINCT id_venta) AS NumeroVentas,
    COUNT_BIG(DISTINCT id_cliente) AS ClientesConCompras,
    SUM(CONVERT(bigint, cantidad)) AS Unidades,
    SUM(venta_neta) AS VentasNetas,
    SUM(costo_total) AS CostoTotal,
    SUM(margen_bruto) AS UtilidadBruta,
    MIN(fecha_venta) AS PrimeraVenta,
    MAX(fecha_venta) AS UltimaVenta,
    COUNT(DISTINCT CONVERT(char(6), fecha_venta, 112)) AS MesesConVentas
FROM [ElectroHogarNorte_BI_Origen].[dbo].[vw_VentasAnaliticas]
UNION ALL
SELECT
    N'Datamart', COUNT_BIG(*), COUNT_BIG(DISTINCT IdDetalleVentaOrigen),
    COUNT_BIG(DISTINCT IdVentaOrigen), COUNT_BIG(DISTINCT ClienteKey),
    SUM(CONVERT(bigint, Cantidad)), SUM(VentaNeta), SUM(CostoTotal), SUM(MargenBruto),
    MIN(FechaHoraVenta), MAX(FechaHoraVenta),
    COUNT(DISTINCT CONVERT(char(6), FechaHoraVenta, 112))
FROM dbo.FactVenta;

-- 2. Conciliacion por identificador de detalle y claves de negocio.
-- EXCEPT compara tambien los NULL: una dimension sin correspondencia
-- no debe quedar oculta por la logica de comparaciones con NULL.
SELECT
    COALESCE(SUM(CONVERT(bigint, CASE
        WHEN o.id_detalle_venta IS NOT NULL AND f.IdDetalleVentaOrigen IS NULL
        THEN 1 ELSE 0 END)), 0) AS FaltantesEnDatamart,
    COALESCE(SUM(CONVERT(bigint, CASE
        WHEN o.id_detalle_venta IS NULL AND f.IdDetalleVentaOrigen IS NOT NULL
        THEN 1 ELSE 0 END)), 0) AS SobrantesEnDatamart,
    COALESCE(SUM(CONVERT(bigint, CASE
        WHEN o.id_detalle_venta IS NOT NULL AND f.IdDetalleVentaOrigen IS NOT NULL
             AND d.Diferente = 1
        THEN 1 ELSE 0 END)), 0) AS DetallesConDiferencias
FROM [ElectroHogarNorte_BI_Origen].[dbo].[vw_VentasAnaliticas] AS o
FULL OUTER JOIN dbo.FactVenta AS f ON f.IdDetalleVentaOrigen = o.id_detalle_venta
LEFT JOIN dbo.DimProducto AS p ON p.ProductoKey = f.ProductoKey
LEFT JOIN dbo.DimCliente AS c ON c.ClienteKey = f.ClienteKey
LEFT JOIN dbo.DimUsuario AS u ON u.UsuarioKey = f.UsuarioKey
LEFT JOIN dbo.DimAlmacen AS a ON a.AlmacenKey = f.AlmacenKey
LEFT JOIN dbo.DimFecha AS cal ON cal.FechaKey = f.FechaKey
CROSS APPLY (
    SELECT CASE WHEN EXISTS (
        SELECT o.id_venta, o.numero_venta COLLATE DATABASE_DEFAULT,
               o.fecha_venta, CONVERT(date, o.fecha_venta),
               YEAR(o.fecha_venta) * 10000 + MONTH(o.fecha_venta) * 100 + DAY(o.fecha_venta),
               o.id_producto, o.id_cliente, o.id_usuario, o.id_almacen,
               o.cantidad, o.precio_unitario, o.descuento, o.venta_neta,
               o.impuesto, o.costo_unitario, o.costo_total
        EXCEPT
        SELECT f.IdVentaOrigen, f.NumeroVenta COLLATE DATABASE_DEFAULT,
               f.FechaHoraVenta, cal.Fecha, f.FechaKey,
               p.IdProductoOrigen, c.IdClienteOrigen, u.IdUsuarioOrigen, a.IdAlmacenOrigen,
               f.Cantidad, f.PrecioUnitario, f.Descuento, f.VentaNeta,
               f.Impuesto, f.CostoUnitario, f.CostoTotal
    ) THEN 1 ELSE 0 END AS Diferente
) AS d;
GO
