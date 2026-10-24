/*
    ELECTROHOGARNORTE - T2
    01_Estructura_DM.sql
    Plataforma de referencia: SQL Server 2025 (17.x), compatibilidad 170.

    Instalacion inicial: ejecutar en una instancia donde NO exista
    ElectroHogarNorte_DM. Este archivo crea la base y sus seis tablas vacias.
    No ejecutar sobre la base de trabajo ya construida.

    Se conserva el DDL de tablas, columnas, claves, restricciones e indices
    exportado el 23/10/2026. La base usa las rutas predeterminadas de la instancia,
    de modo que no depende de la carpeta de instalacion del equipo ROB.

    Orden de reconstruccion:
      1. Ejecutar este archivo.
      2. Ejecutar 02_Cargar_DimFecha.sql con el calendario exportado.
      3. Configurar conexiones y ejecutar el proyecto SSIS T2.
      4. Configurar la cuenta de SSAS, su login en SQL Server, el usuario en
         ElectroHogarNorte_DM y SELECT sobre las seis tablas; desplegar/procesar
         el proyecto SSAS. Documentar estos permisos en el script de configuracion.

    El usuario Windows del servicio SSAS no se crea en este archivo: su nombre
    y login deben configurarse en el equipo de destino antes de procesar el cubo.
    No se han ejecutado sentencias de este archivo sobre tu servidor.
*/

USE [master]
GO
/****** Objeto: Database [ElectroHogarNorte_DM] Fecha de script: 23/10/2026 23:50:48 ******/
CREATE DATABASE [ElectroHogarNorte_DM];
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET COMPATIBILITY_LEVEL = 170
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [ElectroHogarNorte_DM].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET ARITHABORT OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET  ENABLE_BROKER 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET RECOVERY FULL 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET  MULTI_USER 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET DB_CHAINING OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET OPTIMIZED_LOCKING = OFF 
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'ElectroHogarNorte_DM', N'ON'
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET QUERY_STORE = ON
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [ElectroHogarNorte_DM]
GO
-- Configurar por separado el login, el usuario y los permisos de lectura de SSAS.
-- La cuenta depende del servicio instalado en el equipo de destino.

/****** Objeto: Table [dbo].[DimAlmacen] Fecha de script: 23/10/2026 23:50:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimAlmacen](
	[AlmacenKey] [int] IDENTITY(1,1) NOT NULL,
	[IdAlmacenOrigen] [int] NOT NULL,
	[Almacen] [nvarchar](100) NOT NULL,
	[FechaCargaUTC] [datetime2](0) NOT NULL,
	[FechaActualizacionUTC] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_DimAlmacen] PRIMARY KEY CLUSTERED 
(
	[AlmacenKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_DimAlmacen_Origen] UNIQUE NONCLUSTERED 
(
	[IdAlmacenOrigen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[DimCliente] Fecha de script: 23/10/2026 23:50:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimCliente](
	[ClienteKey] [int] IDENTITY(1,1) NOT NULL,
	[IdClienteOrigen] [int] NOT NULL,
	[Cliente] [nvarchar](150) NOT NULL,
	[Distrito] [nvarchar](80) NOT NULL,
	[FechaCargaUTC] [datetime2](0) NOT NULL,
	[FechaActualizacionUTC] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_DimCliente] PRIMARY KEY CLUSTERED 
(
	[ClienteKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_DimCliente_Origen] UNIQUE NONCLUSTERED 
(
	[IdClienteOrigen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[DimFecha] Fecha de script: 23/10/2026 23:50:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimFecha](
	[FechaKey] [int] NOT NULL,
	[Fecha] [date] NOT NULL,
	[Anio] [smallint] NOT NULL,
	[Semestre] [tinyint] NOT NULL,
	[Trimestre] [tinyint] NOT NULL,
	[MesNumero] [tinyint] NOT NULL,
	[MesNombre] [nvarchar](12) NOT NULL,
	[AnioMes] [int] NOT NULL,
	[AnioMesTexto] [char](7) NOT NULL,
	[DiaMes] [tinyint] NOT NULL,
	[DiaSemanaNumero] [tinyint] NOT NULL,
	[DiaSemanaNombre] [nvarchar](12) NOT NULL,
	[EsFinSemana] [bit] NOT NULL,
 CONSTRAINT [PK_DimFecha] PRIMARY KEY CLUSTERED 
(
	[FechaKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_DimFecha_Fecha] UNIQUE NONCLUSTERED 
(
	[Fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[DimProducto] Fecha de script: 23/10/2026 23:50:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimProducto](
	[ProductoKey] [int] IDENTITY(1,1) NOT NULL,
	[IdProductoOrigen] [int] NOT NULL,
	[CodigoProducto] [varchar](30) NOT NULL,
	[Producto] [nvarchar](150) NOT NULL,
	[Categoria] [nvarchar](100) NOT NULL,
	[Marca] [nvarchar](100) NOT NULL,
	[FechaCargaUTC] [datetime2](0) NOT NULL,
	[FechaActualizacionUTC] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_DimProducto] PRIMARY KEY CLUSTERED 
(
	[ProductoKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_DimProducto_Codigo] UNIQUE NONCLUSTERED 
(
	[CodigoProducto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_DimProducto_Origen] UNIQUE NONCLUSTERED 
(
	[IdProductoOrigen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[DimUsuario] Fecha de script: 23/10/2026 23:50:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimUsuario](
	[UsuarioKey] [int] IDENTITY(1,1) NOT NULL,
	[IdUsuarioOrigen] [int] NOT NULL,
	[Usuario] [nvarchar](201) NOT NULL,
	[FechaCargaUTC] [datetime2](0) NOT NULL,
	[FechaActualizacionUTC] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_DimUsuario] PRIMARY KEY CLUSTERED 
(
	[UsuarioKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_DimUsuario_Origen] UNIQUE NONCLUSTERED 
(
	[IdUsuarioOrigen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[FactVenta] Fecha de script: 23/10/2026 23:50:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactVenta](
	[VentaKey] [bigint] IDENTITY(1,1) NOT NULL,
	[IdDetalleVentaOrigen] [bigint] NOT NULL,
	[IdVentaOrigen] [bigint] NOT NULL,
	[NumeroVenta] [varchar](40) NOT NULL,
	[TipoComprobante] [varchar](10) NOT NULL,
	[Moneda] [char](3) NOT NULL,
	[FechaHoraVenta] [datetime2](0) NOT NULL,
	[FechaKey] [int] NOT NULL,
	[ProductoKey] [int] NOT NULL,
	[ClienteKey] [int] NOT NULL,
	[UsuarioKey] [int] NOT NULL,
	[AlmacenKey] [int] NOT NULL,
	[Cantidad] [int] NOT NULL,
	[PrecioUnitario] [decimal](12, 2) NOT NULL,
	[Descuento] [decimal](14, 2) NOT NULL,
	[VentaNeta] [decimal](16, 2) NOT NULL,
	[TasaImpuesto] [decimal](5, 4) NOT NULL,
	[Impuesto] [decimal](16, 2) NOT NULL,
	[CostoUnitario] [decimal](14, 4) NOT NULL,
	[CostoTotal] [decimal](16, 4) NOT NULL,
	[TotalConImpuesto]  AS (CONVERT([decimal](17,2),[VentaNeta]+[Impuesto])) PERSISTED,
	[MargenBruto]  AS (CONVERT([decimal](19,4),[VentaNeta]-[CostoTotal])) PERSISTED,
	[FechaCargaUTC] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_FactVenta] PRIMARY KEY CLUSTERED 
(
	[VentaKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_FactVenta_Detalle] UNIQUE NONCLUSTERED 
(
	[IdDetalleVentaOrigen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Index [IX_FactVenta_Almacen] Fecha de script: 23/10/2026 23:50:49 ******/
CREATE NONCLUSTERED INDEX [IX_FactVenta_Almacen] ON [dbo].[FactVenta]
(
	[AlmacenKey] ASC,
	[FechaKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [IX_FactVenta_Cliente] Fecha de script: 23/10/2026 23:50:49 ******/
CREATE NONCLUSTERED INDEX [IX_FactVenta_Cliente] ON [dbo].[FactVenta]
(
	[ClienteKey] ASC,
	[FechaKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [IX_FactVenta_Documento] Fecha de script: 23/10/2026 23:50:49 ******/
CREATE NONCLUSTERED INDEX [IX_FactVenta_Documento] ON [dbo].[FactVenta]
(
	[IdVentaOrigen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [IX_FactVenta_Fecha] Fecha de script: 23/10/2026 23:50:49 ******/
CREATE NONCLUSTERED INDEX [IX_FactVenta_Fecha] ON [dbo].[FactVenta]
(
	[FechaKey] ASC
)
INCLUDE([VentaNeta],[CostoTotal],[Cantidad],[IdVentaOrigen]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [IX_FactVenta_Producto] Fecha de script: 23/10/2026 23:50:49 ******/
CREATE NONCLUSTERED INDEX [IX_FactVenta_Producto] ON [dbo].[FactVenta]
(
	[ProductoKey] ASC,
	[FechaKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [IX_FactVenta_Usuario] Fecha de script: 23/10/2026 23:50:49 ******/
CREATE NONCLUSTERED INDEX [IX_FactVenta_Usuario] ON [dbo].[FactVenta]
(
	[UsuarioKey] ASC,
	[FechaKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimAlmacen] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCargaUTC]
GO
ALTER TABLE [dbo].[DimAlmacen] ADD  DEFAULT (sysutcdatetime()) FOR [FechaActualizacionUTC]
GO
ALTER TABLE [dbo].[DimCliente] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCargaUTC]
GO
ALTER TABLE [dbo].[DimCliente] ADD  DEFAULT (sysutcdatetime()) FOR [FechaActualizacionUTC]
GO
ALTER TABLE [dbo].[DimProducto] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCargaUTC]
GO
ALTER TABLE [dbo].[DimProducto] ADD  DEFAULT (sysutcdatetime()) FOR [FechaActualizacionUTC]
GO
ALTER TABLE [dbo].[DimUsuario] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCargaUTC]
GO
ALTER TABLE [dbo].[DimUsuario] ADD  DEFAULT (sysutcdatetime()) FOR [FechaActualizacionUTC]
GO
ALTER TABLE [dbo].[FactVenta] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCargaUTC]
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD  CONSTRAINT [FK_FactVenta_Almacen] FOREIGN KEY([AlmacenKey])
REFERENCES [dbo].[DimAlmacen] ([AlmacenKey])
GO
ALTER TABLE [dbo].[FactVenta] CHECK CONSTRAINT [FK_FactVenta_Almacen]
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD  CONSTRAINT [FK_FactVenta_Cliente] FOREIGN KEY([ClienteKey])
REFERENCES [dbo].[DimCliente] ([ClienteKey])
GO
ALTER TABLE [dbo].[FactVenta] CHECK CONSTRAINT [FK_FactVenta_Cliente]
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD  CONSTRAINT [FK_FactVenta_Fecha] FOREIGN KEY([FechaKey])
REFERENCES [dbo].[DimFecha] ([FechaKey])
GO
ALTER TABLE [dbo].[FactVenta] CHECK CONSTRAINT [FK_FactVenta_Fecha]
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD  CONSTRAINT [FK_FactVenta_Producto] FOREIGN KEY([ProductoKey])
REFERENCES [dbo].[DimProducto] ([ProductoKey])
GO
ALTER TABLE [dbo].[FactVenta] CHECK CONSTRAINT [FK_FactVenta_Producto]
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD  CONSTRAINT [FK_FactVenta_Usuario] FOREIGN KEY([UsuarioKey])
REFERENCES [dbo].[DimUsuario] ([UsuarioKey])
GO
ALTER TABLE [dbo].[FactVenta] CHECK CONSTRAINT [FK_FactVenta_Usuario]
GO
ALTER TABLE [dbo].[DimFecha]  WITH CHECK ADD CHECK  (([DiaMes]>=(1) AND [DiaMes]<=(31)))
GO
ALTER TABLE [dbo].[DimFecha]  WITH CHECK ADD CHECK  (([DiaSemanaNumero]>=(1) AND [DiaSemanaNumero]<=(7)))
GO
ALTER TABLE [dbo].[DimFecha]  WITH CHECK ADD CHECK  (([MesNumero]>=(1) AND [MesNumero]<=(12)))
GO
ALTER TABLE [dbo].[DimFecha]  WITH CHECK ADD CHECK  (([Semestre]>=(1) AND [Semestre]<=(2)))
GO
ALTER TABLE [dbo].[DimFecha]  WITH CHECK ADD CHECK  (([Trimestre]>=(1) AND [Trimestre]<=(4)))
GO
ALTER TABLE [dbo].[DimFecha]  WITH CHECK ADD  CONSTRAINT [CK_DimFecha_Atributos] CHECK  (([Anio]=datepart(year,[Fecha]) AND [MesNumero]=datepart(month,[Fecha]) AND [DiaMes]=datepart(day,[Fecha]) AND [AnioMes]=(datepart(year,[Fecha])*(100)+datepart(month,[Fecha])) AND [Trimestre]=datepart(quarter,[Fecha]) AND [Semestre]=case when datepart(month,[Fecha])<=(6) then (1) else (2) end))
GO
ALTER TABLE [dbo].[DimFecha] CHECK CONSTRAINT [CK_DimFecha_Atributos]
GO
ALTER TABLE [dbo].[DimFecha]  WITH CHECK ADD  CONSTRAINT [CK_DimFecha_Clave] CHECK  (([FechaKey]=((datepart(year,[Fecha])*(10000)+datepart(month,[Fecha])*(100))+datepart(day,[Fecha]))))
GO
ALTER TABLE [dbo].[DimFecha] CHECK CONSTRAINT [CK_DimFecha_Clave]
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD CHECK  (([Cantidad]>(0)))
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD CHECK  (([CostoUnitario]>=(0)))
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD CHECK  (([CostoTotal]>=(0)))
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD CHECK  (([Descuento]>=(0)))
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD CHECK  (([Impuesto]>=(0)))
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD CHECK  (([Moneda]='PEN'))
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD CHECK  (([PrecioUnitario]>(0)))
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD CHECK  (([TasaImpuesto]>=(0) AND [TasaImpuesto]<=(1)))
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD CHECK  (([TipoComprobante]='FACTURA' OR [TipoComprobante]='BOLETA'))
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD CHECK  (([VentaNeta]>(0)))
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD  CONSTRAINT [CK_FactVenta_Costo] CHECK  (([CostoTotal]=CONVERT([decimal](16,4),[Cantidad]*[CostoUnitario])))
GO
ALTER TABLE [dbo].[FactVenta] CHECK CONSTRAINT [CK_FactVenta_Costo]
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD  CONSTRAINT [CK_FactVenta_Descuento] CHECK  (([Descuento]<[Cantidad]*[PrecioUnitario]))
GO
ALTER TABLE [dbo].[FactVenta] CHECK CONSTRAINT [CK_FactVenta_Descuento]
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD  CONSTRAINT [CK_FactVenta_Fecha] CHECK  (([FechaKey]=((datepart(year,[FechaHoraVenta])*(10000)+datepart(month,[FechaHoraVenta])*(100))+datepart(day,[FechaHoraVenta]))))
GO
ALTER TABLE [dbo].[FactVenta] CHECK CONSTRAINT [CK_FactVenta_Fecha]
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD  CONSTRAINT [CK_FactVenta_Impuesto] CHECK  (([Impuesto]=CONVERT([decimal](16,2),round([VentaNeta]*[TasaImpuesto],(2)))))
GO
ALTER TABLE [dbo].[FactVenta] CHECK CONSTRAINT [CK_FactVenta_Impuesto]
GO
ALTER TABLE [dbo].[FactVenta]  WITH CHECK ADD  CONSTRAINT [CK_FactVenta_Neta] CHECK  (([VentaNeta]=CONVERT([decimal](16,2),[Cantidad]*[PrecioUnitario]-[Descuento])))
GO
ALTER TABLE [dbo].[FactVenta] CHECK CONSTRAINT [CK_FactVenta_Neta]
GO
USE [master]
GO
ALTER DATABASE [ElectroHogarNorte_DM] SET  READ_WRITE 
GO
