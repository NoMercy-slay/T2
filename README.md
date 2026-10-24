# ElectroHogarNorte — Proyecto T2 de Inteligencia de Negocios

Solución académica para analizar ventas y rentabilidad bruta mediante SQL Server, un Datamart dimensional, SSIS, un cubo multidimensional SSAS y Power BI.

Repositorio: https://github.com/NoMercy-slay/T2

## Contenido de la entrega

| Carpeta | Contenido |
|---|---|
| `01_SQL_Origen` | Scripts 01–05 de estructura, procedimientos y vistas, datos 2023–2025, validación y reglas del origen. |
| `02_SQL_Datamart` | `01_Estructura_DM.sql`, `02_Cargar_DimFecha.sql`, `03_Permisos_SSAS.sql` y `04_Validacion_Origen_DM.sql`. |
| `03_Automatizacion` | `01_JOB_ETL_ElectroHogarNorte.sql`: definición del trabajo de SQL Server Agent. |
| `04_SSIS` | Solución `T2.slnx`, proyecto `T2.dtproj`, `Package.dtsx` y archivos del proyecto. |
| `05_SSAS` | Solución y proyecto `ElectroHogarNorte_OLAP`, cubo `CuboVentas`, dimensiones, origen y vista de datos, particiones y rol. |
| `06_PowerBI` | `ElectroHogarNorte_Dashboard_OLAP.pbix`, conectado al cubo. |
| `07_Informe` | Informe de la T2 con evidencias y resultados. |
| `08_Evidencias` | Capturas y salidas SQL/MDX, historial de automatización y evidencias del dashboard. |

La tabla describe la organización prevista para la entrega completa. El contenido publicado debe coincidir con el informe y los archivos efectivamente incorporados.

## Entorno y conexiones

Se requiere un entorno Windows con SQL Server 2025, Motor de base de datos, SSIS, SQL Server Agent y SSAS en modo multidimensional; Visual Studio con los proyectos SSIS y SSAS; SSMS; Power BI Desktop; y el proveedor OLE DB utilizado por los proyectos (`MSOLEDBSQL.1`).

| Componente | Configuración del equipo de referencia |
|---|---|
| Servidor | `ROB`, instancia predeterminada. |
| Base transaccional | `ElectroHogarNorte_BI_Origen`. |
| Datamart | `ElectroHogarNorte_DM`. |
| SSIS: `CN_Origen` | `localhost`, base `ElectroHogarNorte_BI_Origen`, autenticación integrada de Windows. |
| SSIS: `CN_Datamart` | `localhost`, base `ElectroHogarNorte_DM`, autenticación integrada de Windows. |
| Catálogo SSIS | `SSISDB`, carpeta `ElectroHogarNorte`, proyecto `T2`, paquete `Package.dtsx`. |
| Base SSAS | `ElectroHogarNorte_OLAP`, servidor `ROB`. |
| Cubo | `CuboVentas`. |
| Origen de datos del cubo | `ROB`, `ElectroHogarNorte_DM`, autenticación integrada y suplantación mediante la cuenta del servicio SSAS. |
| Cuenta del servicio SSAS | `NT Service\MSSQLServerOLAPService`. |
| Cuenta del servicio SQL Server Agent | `NT SERVICE\SQLSERVERAGENT`. |
| Propietario del trabajo exportado | `Rob\SIayM`. |
| Power BI | Conexión en vivo a `ROB` → `ElectroHogarNorte_OLAP` → `CuboVentas`. |

Al usar otro equipo, adaptar las instancias, las cuentas Windows y las conexiones. `localhost` en SSIS se refiere al equipo donde se ejecuta el paquete.

## Reconstrucción en un entorno nuevo

Los scripts de creación corresponden a una instalación inicial. Conservar la base y el trabajo que ya funcionan durante la demostración del proyecto.

1. Ejecutar los scripts de `01_SQL_Origen` en su orden numérico: estructura; procedimientos y vistas; datos; validación; pruebas de reglas. Revisar las condiciones de uso de cada script.
2. Ejecutar `02_SQL_Datamart/01_Estructura_DM.sql` para crear el Datamart vacío. Utiliza las rutas predeterminadas de la instancia y mantiene compatibilidad 170 para SQL Server 2025.
3. Ejecutar `02_SQL_Datamart/02_Cargar_DimFecha.sql` sobre la dimensión fecha vacía. Carga 1096 días de calendario, desde el 1 de enero de 2023 hasta el 31 de diciembre de 2025.
4. Abrir `T2.slnx` dentro de `04_SSIS`, comprobar `CN_Origen` y `CN_Datamart`, compilar y ejecutar el paquete. El ETL carga las dimensiones de almacén, cliente, producto y usuario; después carga los detalles de venta y utiliza `DimFecha` para obtener su clave temporal.
5. Crear o preparar el catálogo `SSISDB` con una contraseña de protección elegida para el entorno, y desplegar el proyecto `T2` en la carpeta `ElectroHogarNorte`. Usar las identidades y permisos correspondientes al equipo de destino.
6. Ejecutar `02_SQL_Datamart/03_Permisos_SSAS.sql` desde una conexión al Motor, con una cuenta administradora, una vez instalado SSAS. Confirmar la cuenta del servicio en la variable del script. Este archivo prepara su login, usuario y permisos `SELECT` sobre las seis tablas del Datamart.
7. Abrir la solución de `05_SSAS`, comprobar el origen de datos, el servidor y el nombre de la base de implementación. Desplegar `ElectroHogarNorte_OLAP` y procesar la base.
8. Comprobar el rol incluido en `Rol_Procesamiento_Agent.role`: su identificador y nombre internos son `Role`. La base contiene permisos de procesamiento, lectura de definición y lectura, y el miembro es `NT SERVICE\SQLSERVERAGENT`. Adaptar esa cuenta si el servicio Agent utiliza otra identidad.
9. Revisar las referencias del script `03_Automatizacion/01_JOB_ETL_ElectroHogarNorte.sql`, especialmente propietario, servidor SSIS y servidor SSAS, y ejecutarlo en el Motor. El script conserva un trabajo del mismo nombre si ya existe.
10. Abrir el `.pbix` de `06_PowerBI`. Ajustar la conexión al servidor SSAS si cambia la instancia y actualizar los visuales.

Los proyectos y scripts contienen las definiciones necesarias para revisar la solución. Los archivos `.slnx` son los archivos de solución incluidos en los proyectos entregados.

## Modelo y alcance analítico

El grano de `FactVenta` es una línea de detalle de venta. Se relaciona con `DimFecha`, `DimProducto`, `DimCliente`, `DimUsuario` y `DimAlmacen` mediante claves dimensionales. El número de ventas se calcula con recuento distinto de `IdVentaOrigen`, porque una venta puede tener varios detalles.

Las dimensiones se actualizan mediante SCD tipo 1. La carga de hechos agrega detalles nuevos identificados por su clave de origen; el tratamiento de correcciones o eliminaciones posteriores de hechos requiere ampliar esa lógica.

Los datos comerciales son sintéticos y cubren 2023–2025. El informe desarrolla los seis requerimientos funcionales: evolución temporal; producto, categoría y marca; almacenes; clientes; distritos; y usuarios responsables del registro.

## Automatización configurada

Trabajo: `JOB_ETL_ElectroHogarNorte`.

1. `Ejecutar_ETL`: ejecuta `\SSISDB\ElectroHogarNorte\T2\Package.dtsx` de forma sincronizada. Si termina correctamente, continúa con el segundo paso; si falla, el trabajo termina con error.
2. `Procesar_Cubo_OLAP`: ejecuta XMLA `ProcessFull` sobre la base `ElectroHogarNorte_OLAP`. Su resultado determina la finalización del trabajo.

El horario `Diario_0800` está habilitado para las 08:00, según la hora del servidor. `PRUEBA_T2_AUTOMATIZACION`, utilizado el 23/10/2026 a las 22:22, quedó deshabilitado después de la prueba. La exportación conserva ambas definiciones.

## Resultados registrados en el equipo de referencia

La conciliación SQL compartida el 24/10/2026 muestra los mismos valores en origen y Datamart:

| Control | Resultado en ambas capas |
|---|---:|
| Detalles y detalles únicos | 18 163 |
| Ventas distintas | 13 262 |
| Clientes con compras | 1200 |
| Unidades | 21 436 |
| Ventas netas, PEN | 22 346 846,11 |
| Costo total, PEN | 16 893 452,2239 |
| Utilidad bruta, PEN | 5 453 393,8861 |
| Meses con ventas | 36 |
| Faltantes en Datamart | 0 |
| Sobrantes en Datamart | 0 |
| Detalles con diferencias en los campos comparados | 0 |

El historial del 23/10/2026 a las 22:22 registra los pasos ETL y procesamiento OLAP correctos. La ejecución SSISDB 12, registrada previamente a las 22:03, duró 1,565 segundos; esa duración corresponde únicamente a esa ejecución del paquete ETL.

El equipo confirmó la coincidencia de los indicadores entre SQL, cubo y Power BI. Las evidencias y el informe deben conservar el periodo, los filtros y el formato usados en cada comparación.

## Consulta de las evidencias

- EXP-01: conciliación de origen y Datamart mediante `04_Validacion_Origen_DM.sql`; guardar sus dos cuadrículas de resultados en `08_Evidencias`.
- EXP-02: historial expandido del trabajo, con la activación por programación y ambos pasos correctos; conservar también el registro de SSISDB.
- EXP-03: consulta del indicador en SQL y MDX y su presentación equivalente en Power BI, con el mismo contexto de consulta.

Las capturas acompañan los archivos de la solución. El informe, los scripts, los proyectos completos y el `.pbix` forman parte de la entrega.

## Preparación de la entrega

Completar los campos pendientes del informe y colocar las capturas reales. Registrar los aportes individuales y una versión final identificable. Comprobar la apertura de las soluciones y del `.pbix` en el entorno preparado para la sustentación. Preparar un ZIP de la entrega completa para Blackboard y mantener el enlace al repositorio en el informe.

El repositorio público debe contener archivos de entrega revisados. Excluir credenciales, contraseñas, archivos de configuración personal y las carpetas temporales `.vs`, `bin` y `obj`.
