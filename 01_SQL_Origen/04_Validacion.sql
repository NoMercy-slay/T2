USE ElectroHogarNorte_BI_Origen;
GO
SET NOCOUNT ON;
-- Cada falla detiene este lote con THROW. Al final debe aparecer VALIDACION CORRECTA.
DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
IF EXISTS(SELECT 1 FROM dbo.Compras c OUTER APPLY(SELECT SUM(d.subtotal) st,SUM(d.impuesto) igv FROM dbo.Detalle_Compras d WHERE d.id_compra=c.id_compra) x WHERE x.st IS NULL OR c.subtotal<>x.st OR c.impuesto<>x.igv)
 THROW 50301,'Compras: totales no coinciden con los detalles.',1;
IF EXISTS(SELECT 1 FROM dbo.Ventas v OUTER APPLY(SELECT SUM(d.subtotal) st,SUM(d.impuesto) igv FROM dbo.Detalle_Ventas d WHERE d.id_venta=v.id_venta) x WHERE x.st IS NULL OR v.subtotal<>x.st OR v.impuesto<>x.igv)
 THROW 50302,'Ventas: totales no coinciden con los detalles.',1;
IF EXISTS(SELECT 1 FROM dbo.Ventas v OUTER APPLY(SELECT SUM(monto) pagado FROM dbo.Pagos_Ventas p WHERE p.id_venta=v.id_venta) x WHERE x.pagado IS NULL OR x.pagado<>v.total)
 THROW 50303,'Pagos no coinciden con las ventas.',1;
IF EXISTS(SELECT 1 FROM dbo.Inventario i OUTER APPLY(SELECT SUM(m.cantidad) saldo FROM dbo.Movimientos_Inventario m WHERE m.id_almacen=i.id_almacen AND m.id_producto=i.id_producto) x WHERE i.stock<>COALESCE(x.saldo,0))
 THROW 50304,'Saldo de inventario no coincide con los movimientos.',1;
IF EXISTS(SELECT 1 FROM (SELECT stock_anterior, LAG(stock_nuevo,1,0) OVER(PARTITION BY id_almacen,id_producto ORDER BY fecha_movimiento,id_movimiento) anterior FROM dbo.Movimientos_Inventario) q WHERE q.stock_anterior<>q.anterior)
 THROW 50305,'Cadena de saldos de inventario inconsistente.',1;
IF EXISTS(SELECT 1 FROM dbo.Detalle_Ventas d JOIN dbo.Ventas v ON v.id_venta=d.id_venta LEFT JOIN dbo.Movimientos_Inventario m ON m.id_detalle_venta=d.id_detalle_venta WHERE m.id_movimiento IS NULL OR m.cantidad<>-d.cantidad OR m.id_producto<>d.id_producto OR m.id_almacen<>v.id_almacen OR m.costo_unitario<>d.costo_unitario OR m.fecha_movimiento<>v.fecha_venta)
 THROW 50306,'Movimiento de venta inconsistente.',1;
IF EXISTS(SELECT 1 FROM dbo.Detalle_Compras d JOIN dbo.Compras c ON c.id_compra=d.id_compra LEFT JOIN dbo.Movimientos_Inventario m ON m.id_detalle_compra=d.id_detalle_compra WHERE m.id_movimiento IS NULL OR m.cantidad<>d.cantidad OR m.id_producto<>d.id_producto OR m.id_almacen<>c.id_almacen OR m.fecha_movimiento<>c.fecha_compra)
 THROW 50307,'Movimiento de compra inconsistente.',1;
IF EXISTS(SELECT 1 FROM dbo.Ventas v JOIN dbo.Usuarios u ON u.id_usuario=v.id_usuario WHERE u.id_rol NOT IN(1,4)) THROW 50308,'Rol de venta inconsistente.',1;
IF EXISTS(SELECT 1 FROM dbo.Compras c JOIN dbo.Usuarios u ON u.id_usuario=c.id_usuario JOIN dbo.Usuarios a ON a.id_usuario=c.id_receptor WHERE u.id_rol NOT IN(1,2) OR a.id_rol NOT IN(1,3)) THROW 50309,'Rol de compra o recepcion inconsistente.',1;
IF (SELECT COUNT(DISTINCT CONVERT(char(7),fecha_venta,126)) FROM dbo.Ventas)<>36 THROW 50310,'Se esperaban 36 meses de ventas.',1;
IF (SELECT MIN(CONVERT(date,fecha_venta)) FROM dbo.Ventas)<>'20230101' OR (SELECT MAX(CONVERT(date,fecha_venta)) FROM dbo.Ventas)<>'20251231' THROW 50311,'Periodo inesperado.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.Usuarios)<>10 THROW 50312,'Conteo inesperado: Usuarios.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.Clientes)<>1200 THROW 50312,'Conteo inesperado: Clientes.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.Productos)<>80 THROW 50312,'Conteo inesperado: Productos.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.Compras)<>862 THROW 50312,'Conteo inesperado: Compras.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.Detalle_Compras)<>3947 THROW 50312,'Conteo inesperado: Detalle_Compras.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.Ventas)<>13262 THROW 50312,'Conteo inesperado: Ventas.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.Detalle_Ventas)<>18163 THROW 50312,'Conteo inesperado: Detalle_Ventas.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.Pagos_Ventas)<>14827 THROW 50312,'Conteo inesperado: Pagos_Ventas.',1;
IF (SELECT COUNT_BIG(*) FROM dbo.Movimientos_Inventario)<>22182 THROW 50312,'Conteo inesperado: Movimientos_Inventario.',1;
DECLARE @esperado TABLE(anio int, ventas int, neto decimal(18,2), impuesto decimal(18,2), costo decimal(18,4));
INSERT @esperado VALUES
(2023,3698,5990867.73,1078357.67,4621591.5895),
(2024,4424,7540152.14,1357227.45,5696637.2066),
(2025,5140,8815826.24,1586849.32,6575223.4278);
IF EXISTS(SELECT 1 FROM @esperado e JOIN (SELECT YEAR(fecha_venta) anio,COUNT(DISTINCT id_venta) ventas,SUM(venta_neta) neto,SUM(impuesto) impuesto,SUM(costo_total) costo FROM dbo.vw_VentasAnaliticas GROUP BY YEAR(fecha_venta)) a ON a.anio=e.anio WHERE a.ventas<>e.ventas OR a.neto<>e.neto OR a.impuesto<>e.impuesto OR a.costo<>e.costo)
 THROW 50313,'Resultados anuales distintos de la simulacion de referencia.',1;
DECLARE @stock TABLE(almacen int,producto int,stock int,costo decimal(14,4));
INSERT @stock VALUES
(1,1,15,1523.1854),
(1,2,15,1694.5348),
(1,3,16,1863.2312),
(1,4,18,2033.2495),
(1,5,9,2199.7014),
(1,6,13,2369.4415),
(1,7,17,2536.5997),
(1,8,15,2711.4775),
(1,9,13,2876.7191),
(1,10,14,1354.6346),
(1,11,13,1142.0892),
(1,12,12,1269.5707),
(1,13,13,1396.1678),
(1,14,13,1524.1983),
(1,15,18,1651.2799),
(1,16,12,1776.5383),
(1,17,14,1907.1716),
(1,18,15,2032.4802),
(1,19,18,2156.4555),
(1,20,12,1013.6568),
(1,21,18,952.0137),
(1,22,17,1058.6170),
(1,23,12,1161.9575),
(1,24,11,1268.9095),
(1,25,15,1375.4479),
(1,26,12,1480.2881),
(1,27,17,1589.2701),
(1,28,14,1693.3298),
(1,29,17,1800.6341),
(1,30,18,847.0032),
(1,31,8,665.8276),
(1,32,10,739.0869),
(1,33,16,814.1162),
(1,34,13,887.3509),
(1,35,14,963.3705),
(1,36,17,1036.7197),
(1,37,14,1111.4406),
(1,38,10,1185.8859),
(1,39,13,1260.2796),
(1,40,15,592.2606),
(1,41,12,237.8449),
(1,42,11,263.8073),
(1,43,17,291.0944),
(1,44,13,317.3340),
(1,45,17,343.9823),
(1,46,11,369.8611),
(1,47,13,395.9499),
(1,48,16,423.7950),
(1,49,14,449.4483),
(1,50,12,211.6521),
(1,51,9,85.6122),
(1,52,14,95.2708),
(1,53,11,104.6457),
(1,54,17,114.2925),
(1,55,14,123.7451),
(1,56,12,133.2854),
(1,57,14,143.0231),
(1,58,12,152.1366),
(1,59,9,161.7906),
(1,60,18,76.2334),
(1,61,16,95.2724),
(1,62,11,105.6853),
(1,63,9,116.3908),
(1,64,12,126.9215),
(1,65,15,137.5499),
(1,66,9,147.9879),
(1,67,16,158.6646),
(1,68,13,169.3289),
(1,69,12,179.9381),
(1,70,12,84.6502),
(1,71,16,114.4043),
(1,72,9,127.0152),
(1,73,10,139.6370),
(1,74,18,152.4489),
(1,75,11,164.8906),
(1,76,15,177.9062),
(1,77,13,190.4336),
(1,78,16,203.1306),
(1,79,13,215.8931),
(1,80,16,101.5795),
(2,1,10,1518.1887),
(2,2,16,1690.3784),
(2,3,13,1852.7600),
(2,4,13,2026.8422),
(2,5,12,2196.4797),
(2,6,14,2357.0625),
(2,7,12,2535.8996),
(2,8,17,2697.5374),
(2,9,16,2875.9269),
(2,10,12,1349.5207),
(2,11,12,1138.4204),
(2,12,11,1265.5153),
(2,13,14,1394.4110),
(2,14,14,1516.8188),
(2,15,18,1646.1622),
(2,16,8,1769.7351),
(2,17,18,1901.4126),
(2,18,10,2023.0127),
(2,19,17,2158.5970),
(2,20,8,1008.0220),
(2,21,13,949.8986),
(2,22,9,1051.3639),
(2,23,11,1160.1712),
(2,24,15,1267.5244),
(2,25,15,1367.9485),
(2,26,15,1473.6859),
(2,27,12,1579.6978),
(2,28,18,1691.3145),
(2,29,15,1795.6463),
(2,30,13,844.7755),
(2,31,13,665.5882),
(2,32,11,738.9209),
(2,33,11,813.6265),
(2,34,14,887.0354),
(2,35,18,963.9126),
(2,36,13,1034.7565),
(2,37,15,1109.3346),
(2,38,14,1181.0367),
(2,39,13,1254.8603),
(2,40,18,591.7355),
(2,41,16,237.4081),
(2,42,10,263.6775),
(2,43,14,290.3791),
(2,44,13,316.7819),
(2,45,12,343.0065),
(2,46,17,369.2382),
(2,47,12,396.3031),
(2,48,14,421.9511),
(2,49,10,449.2207),
(2,50,12,211.0212),
(2,51,8,85.5860),
(2,52,15,94.9923),
(2,53,10,104.2949),
(2,54,12,113.8525),
(2,55,15,123.0293),
(2,56,13,132.9472),
(2,57,18,142.6134),
(2,58,13,152.2345),
(2,59,17,161.8354),
(2,60,10,76.1389),
(2,61,17,95.1206),
(2,62,13,105.8657),
(2,63,17,116.3925),
(2,64,15,126.8923),
(2,65,13,137.0840),
(2,66,16,148.0883),
(2,67,15,158.7511),
(2,68,15,168.4193),
(2,69,15,179.3090),
(2,70,11,84.5938),
(2,71,14,113.9056),
(2,72,13,126.3572),
(2,73,16,139.5413),
(2,74,10,152.0330),
(2,75,18,164.7871),
(2,76,14,177.0911),
(2,77,9,190.0025),
(2,78,10,202.8753),
(2,79,15,215.1280),
(2,80,12,101.4257);
IF EXISTS(SELECT 1 FROM @stock e LEFT JOIN dbo.Inventario i ON i.id_almacen=e.almacen AND i.id_producto=e.producto WHERE i.id_producto IS NULL OR e.stock<>i.stock OR e.costo<>i.costo_promedio)
 THROW 50314,'Stock o costo final inesperado.',1;
SELECT YEAR(fecha_venta) anio,COUNT(DISTINCT id_venta) ventas,SUM(cantidad) unidades,
 SUM(venta_neta) venta_neta,SUM(impuesto) impuesto,SUM(costo_total) costo,SUM(margen_bruto) margen_bruto
FROM dbo.vw_VentasAnaliticas GROUP BY YEAR(fecha_venta) ORDER BY anio;
SELECT YEAR(fecha_venta) anio,MONTH(fecha_venta) mes,COUNT(*) ventas,SUM(total) cobrado
FROM dbo.Ventas GROUP BY YEAR(fecha_venta),MONTH(fecha_venta) ORDER BY anio,mes;
SELECT * FROM dbo.vw_StockActual ORDER BY id_almacen,id_producto;
PRINT N'VALIDACION CORRECTA: integridad, pagos, inventario, 36 meses y resultados esperados.';
GO
