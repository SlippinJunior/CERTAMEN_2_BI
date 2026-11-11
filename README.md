# Mueblería Albarrán – Solución Integral de Inteligencia de Negocios

**Caso Semestral · Inteligencia de Negocios · Entrega Final: Cubos OLAP (SSAS) y Dashboard en Power BI**

| Metadato | Detalle |
|---|---|
| **Integrantes** | Ivan Papic · Alberto Aguilera |
| **Asignatura / Sección** | Inteligencia de Negocios · Paralelo 300 |
| **Profesor** | Hernán Saavedra González |
| **Institución** | Universidad Técnica Federico Santa María · Departamento de Industrias |
| **Stack Tecnológico** | SQL Server 2019/2017 · SSIS · SSAS (Multidimensional) · Power BI Desktop · SSMS · Visual Studio |

---

## 1. Visión General de la Solución

El presente proyecto implementa una solución de **Business Intelligence (BI) de extremo a extremo** para **Mueblería Albarrán**, una empresa en expansión del rubro del mobiliario para el hogar y oficina en Chile. La solución cubre las cinco capas fundamentales de la disciplina:

```
[ 1. Base OLTP ]  -->  [ 2. ETL SSIS ]  -->  [ 3. Data Warehouse ]  -->  [ 4. Cubo SSAS OLAP ]  -->  [ 5. Power BI Dashboard ]
  Albarran.bak           ETL_Albarran.dtsx      Albarran_DW (Estrella)      OLAP_Albarran (MOLAP)      4 Páginas Ejecutivas
 (9 tablas, 365 v.)     (Limpieza, Lookups)    (Fact + 6 Dimensiones)      (3 MG, 10 KPIs MDX)        (DAX, KPIs, Tema Albarrán)
```

1. **Capa Transaccional (OLTP):** Base de datos relacional `Albarran` (9 tablas en 3FN, 365 ventas en 2017 por $414.022.446).
2. **Capa de Ingesta y ETL:** Paquete SSIS automatizado `ETL_Albarran.dtsx` con control flow transaccional, data flows con caché de lookups, miembro desconocido (`-1`), auditoría en `EtlLog` y conciliación fila a fila sin pérdida de datos.
3. **Capa de Almacenamiento (DW):** Data Warehouse `Albarran_DW` modelado bajo la metodología de **Ralph Kimball** en esquema en estrella puro: tabla de hechos `FactVentas` a grano atómico de línea de producto y 6 dimensiones conformadas.
4. **Capa de Procesamiento Analítico (OLAP):** Cubo multidimensional en **SQL Server Analysis Services (SSAS)** con almacenamiento MOLAP, preagregaciones optimizadas, jerarquías de navegación con orden cronológico estricto, grupos de medidas dedicados para recuentos diferenciados (*DistinctCount*), cálculos MDX de inteligencia temporal y 5 objetos KPI nativos con semáforos (*Traffic Light* y *Gauge*).
5. **Capa de Explotación y Visualización:** Dashboard gerencial en **Power BI Desktop** estructurado en cuatro páginas temáticas para el Propietario y Jefaturas Comerciales, respaldado por un catálogo exhaustivo de medidas DAX y paleta corporativa cálida nogal/marino.

---

## 2. Estructura del Repositorio y Entregables

```
CERTAMEN_2_BI/
├── README.md                                   ← Documentación maestra de toda la solución (Fase 1 y Fase 2)
│
├── database/                                   ← Scripts SQL y MDX de base de datos
│   ├── backup/                                 ← Respaldos .bak de bases de datos
│   │   ├── Albarran.bak                        ← Respaldo de la base OLTP original (365 ventas)
│   │   └── Albarran_DW.bak                     ← Respaldo de la base dimensional Albarran_DW
│   └── scripts/
│       ├── 00_restaurar_bd_transaccional.sql   ← Script de restauración del OLTP
│       ├── 01_crear_modelo_dimensional.sql     ← DDL del DW Albarran_DW (tablas, FKs, SPs)
│       ├── 02_validacion_etl.sql               ← Conciliación origen vs destino
│       ├── 03_backup_modelo_dimensional.sql    ← Generación de backup Albarran_DW.bak
│       ├── 04_consultas_kpi.sql                ← Consultas SQL de los 10 KPIs (Línea base)
│       └── 05_consultas_mdx_cubo.mdx           ← 10 Consultas MDX de validación sobre el Cubo SSAS
│
├── etl/                                        ← Proyecto SSIS (Visual Studio)
│   ├── ETL_Albarran.sln                        ← Solución de Visual Studio para SSIS
│   └── ETL_Albarran/
│       ├── ETL_Albarran.dtproj                 ← Proyecto Integration Services
│       └── ETL_Albarran.dtsx                   ← Paquete ETL principal con flujos de control y datos
│
├── olap/                                       ← Proyecto SSAS Multidimensional (Visual Studio)
│   ├── OLAP_Albarran.sln                       ← Solución de Visual Studio para Analysis Services
│   ├── crear_cubo_ssas.ps1                     ← Script PowerShell/AMO para crear, desplegar y procesar el cubo
│   ├── Deploy_Cubo_Albarran.xmla               ← Script XMLA estándar de despliegue en SSAS
│   └── OLAP_Albarran/
│       ├── OLAP_Albarran.dwproj                ← Proyecto SSAS Multidimensional
│       ├── Albarran_DW.ds                      ← Data Source (conexión a localhost/Albarran_DW)
│       ├── Albarran_DW.dsv                     ← Data Source View (vistas y relaciones estrella)
│       ├── DimTiempo.dim                       ← Dimensión Tiempo con jerarquías y orden cronológico
│       ├── DimSucursal.dim                     ← Dimensión Sucursal con jerarquía geográfica
│       ├── DimProducto.dim                     ← Dimensión Producto con jerarquía de catálogo
│       ├── DimCliente.dim                      ← Dimensión Cliente con jerarquía demográfica
│       ├── DimEmpleado.dim                     ← Dimensión Empleado con costo salarial anual
│       ├── DimTipoDocumento.dim                ← Dimensión Canal de Venta / Documento
│       └── Cubo_Albarran.cube                  ← Definición del Cubo, Measure Groups, MDX y KPIs
│
├── powerbi/                                    ← Capa de Visualización y Dashboard Power BI
│   ├── GUIA_PASO_A_PASO_POWERBI.md             ← Guía completa paso a paso para construir el dashboard en Power BI
│   ├── Tema_Muebleria_Albarran.json            ← Tema corporativo de Power BI (paleta nogal/marino)
│   ├── medidas_dax_kpi.dax                     ← Catálogo formal de todas las medidas DAX para PBI
│   └── datos/                                  ← Archivos CSV exportados desde Albarran_DW para carga directa
│       ├── DimTiempo.csv, DimCliente.csv, DimEmpleado.csv, DimProducto.csv,
│       ├── DimSucursal.csv, DimTipoDocumento.csv, FactVentas.csv
│
└── docs/                                       ← Entregables finales formales e informes
    ├── Informe_Final_Albarran.docx             ← INFORME FINAL (.docx formato formal caso, 845 KB)
    ├── Albarrán BI_Entrega Final.pptx          ← PRESENTACIÓN FINAL (.pptx 17 slides con notas de orador)
    ├── Informe_Fase1_Albarran.docx             ← Informe de entrega de la Fase 1
    ├── Albarrán BI_Fase 1.pptx                 ← Presentación de la Fase 1
    ├── dashboard/                              ← Capturas en alta resolución del Dashboard (Páginas 1 a 4)
    ├── cubo_olap/                              ← Capturas de arquitectura SSAS y consultas MDX
    └── modelo_dimensional/                     ← Diagramas del esquema en estrella
```

---

## 3. Hilo Conductor: Los 10 Indicadores Clave de Desempeño (KPI)

Los 10 indicadores de negocio definidos al inicio del semestre se mantuvieron como el **hilo conductor inmutable** en todas las capas del proyecto. Todas las cifras cuadraron al peso entre SQL relacional, expresiones MDX en SSAS y medidas DAX en Power BI:

| # | Indicador (KPI) | Fórmula Matemática / Lógica | Meta de Negocio | Línea Base 2017 | Utilidad Estratégica para el Dueño |
|---|---|---|---|---|---|
| **1** | **Ventas y Crecimiento Mensual** | $\sum \text{MontoTotal}$; $\frac{\text{Ventas}_t - \text{Ventas}_{t-1}}{\text{Ventas}_{t-1}}$ | $\ge 5,0\%$ mensual | **$414.022.446** (Peak julio: $48,3 MM / +50,8%; valle nov: $25,3 MM / -35,5%) | Anticipar estacionalidad invernal, planificar compras de insumos y liquidez. |
| **2** | **Ticket Promedio por Venta** | $\frac{\sum \text{MontoTotal}}{\text{N° Ventas}}$ | $\ge \$1.150.000$ | **$1.134.308** por compra (Manquehue lidera con $1.214.033) | Evaluar potencial de venta cruzada (*cross-selling*) y combos de mobiliario. |
| **3** | **Participación por Sucursal** | $\frac{\text{Ventas Sucursal}}{\text{Ventas Totales}}$ | $\ge 33,3\%$ por local | **Manquehue: 36,1%** · **Viña: 32,5%** · **Franklin: 31,5%** | Equilibrar inversión en salas de venta y dimensionar dotación. |
| **4** | **Mix de Ventas por Categoría** | $\frac{\text{Ventas Categoría}}{\text{Ventas Totales}}$ | Portafolio diversificado | **Comedores 28,8%** · **Sofás 16,5%** · **Dormitorio 13,4%** (58,7% total) | **Alerta:** *Buffets* y *Modulares* tienen 0 productos y $0 ventas en el año. |
| **5** | **Ranking de Productos Estrella** | Ranking descendente por $\sum \text{MontoTotal}$ | Top 1 consolidado | **Top 1: Living MJO** ($41.600.000 / 32 unidades) | Proteger stock de los artículos más demandados en showroom. |
| **6** | **Productividad Fuerza Ventas** | $\frac{\text{Ventas Vendedor}}{\text{Sueldo Base} \times 12}$ | $\ge 20,0\text{x}$ sueldo anual | **Romina Vásquez: 25,2x** (Verde) · **Pamela Cortez: 15,8x** (Rojo) | Detectar disparidad por sueldos fijos; migrar a comisiones variables. |
| **7** | **% Ventas con Factura (B2B)** | $\frac{\text{Ventas Factura}}{\text{Total Transacciones}}$ | $\ge 20,0\%$ del volumen | **16,2%** de las ventas (59 operaciones, $66.279.778) | Monitorear expansión en el segmento empresas y oficinas de diseño. |
| **8** | **Segmentación de Clientes** | $\sum \text{MontoTotal}$ por Sexo y Rango Etario | Segmentos definidos | **Hombres: 68,7%** ($284,5 MM) · **Adultos (35-59): 78,6%** | Enfocar promociones y diseño de catálogos según perfil demográfico. |
| **9** | **Frecuencia de Compra** | $\frac{\text{N° Ventas}}{\text{Clientes Únicos}}$ | $\ge 12$ compras/año | **18,25 compras/cliente** al año (20 clientes en cartera) | Cartera boutique de alta recurrencia (decoradores, contratistas). |
| **10** | **Control de Descuentos** | $\frac{\sum \text{MontoDescuento}}{\sum \text{MontoBruto}}$ | $\le 5,0\%$ margen | **0,0%** en todo el período 2017 | Comprobar disciplina de precios y cumplimiento de política comercial. |

---

## 4. Fase 2: Motor Analítico OLAP en SSAS

### 4.1 Justificación Técnica: MOLAP vs. ROLAP
La implementación de un Cubo Multidimensional en **SQL Server Analysis Services (SSAS)** en modo **MOLAP** resuelve los cuellos de botella inherentes a las consultas sobre bases relacionales:
* **Preagregaciones Multidimensionales:** Las medidas se precalculan y comprimen en estructuras multidimensionales, logrando tiempos de respuesta en milisegundos sin sobrecargar el motor relacional.
* **Jerarquías Nativas y Navegación:** Soporte automático de operaciones de *Drill-down* (desglose) y *Roll-up* (consolidación) a lo largo de las jerarquías de tiempo, geografía y catálogo.
* **Cálculos MDX Centralizados:** Las fórmulas analíticas complejas (variaciones porcentuales contra el período anterior usando `ParallelPeriod`, ratios de productividad salarial) se definen una única vez en el cubo, garantizando gobierno y consistencia de datos.
* **Objetos KPI Nativos:** Monitoreo dinámico con expresiones de *Valor*, *Meta*, función de *Estado* tricolor (+1, 0, -1) y función de *Tendencia* histórica.

### 4.2 Arquitectura del Proyecto SSAS (`OLAP_Albarran`)
* **Data Source (`Albarran_DW.ds`):** Cadena de conexión OLE DB a `localhost`, base `Albarran_DW`, con permisos asignados para la cuenta de servicio `NT Service\MSSQLServerOLAPService`.
* **Data Source View (`Albarran_DW.dsv`):** Modela la relación lógica estrella entre `FactVentas` y las seis dimensiones mediante claves subrogadas (`TiempoKey`, `SucursalKey`, `ProductoKey`, `ClienteKey`, `EmpleadoKey`, `TipoDocumentoKey`).
* **Columna Calculada en DSV:** Se incorporó `SueldoBaseAnual AS (SueldoBase * 12)` en `DimEmpleado` para permitir el cálculo directo del KPI de productividad.
* **Separación de Grupos de Medidas (Measure Groups):** Siguiendo las mejores prácticas arquitectónicas de SSAS, se definieron tres grupos independientes:
  1. `Fact Ventas` (Partición física principal): Medidas aditivas `Cantidad`, `MontoBruto`, `MontoDescuento`, `MontoTotal`, `MontoNeto`, `MontoIVA`.
  2. `Ventas Distintas` (Partición DistinctCount): Medida `Numero de Ventas` (`DistinctCount` sobre `VentaID`).
  3. `Clientes Activos` (Partición DistinctCount): Medida `Clientes Activos` (`DistinctCount` sobre `ClienteKey`).
* **Dimensiones y Jerarquías:**
  * `DimTiempo`: Jerarquías **Calendario** (`Año -> Semestre -> Trimestre -> Mes -> Fecha`) y **Estacional** (`Año -> Estación -> Mes`). Los atributos de mes y día de semana están ordenados por su clave numérica (`OrderBy = Key`), garantizando un orden cronológico estricto (Enero a Diciembre; Lunes a Domingo).
  * `DimSucursal`: Jerarquía Geográfica (`Región -> Comuna -> Sucursal`).
  * `DimProducto`: Jerarquía de Catálogo (`Categoría -> Rango de Precio -> Producto`).
  * `DimCliente`: Jerarquía Demográfica (`Sexo -> Rango Etario -> Estado Civil -> Cliente`).
  * `DimEmpleado`: Jerarquía Comercial (`Cargo -> Empleado/Vendedor`).
  * `DimTipoDocumento`: Jerarquía de Canal (`Tipo de Venta -> Tipo de Documento`).

### 4.3 Consultas MDX de Validación (`05_consultas_mdx_cubo.mdx`)
El script ubicado en `database/scripts/05_consultas_mdx_cubo.mdx` contiene las 10 consultas formales en lenguaje MDX para probar el cubo en SSMS. Ejemplo de consulta de estacionalidad mensual y ticket promedio:

```mdx
-- Consulta 01: Ventas Mensuales, Variación MoM y Ticket Promedio
WITH 
  MEMBER [Measures].[Crecimiento_MoM] AS
    IIF(
      ISEMPTY(([Measures].[Monto Total], ParallelPeriod([Dim Tiempo].[Calendario].[Mes], 1))),
      NULL,
      (([Measures].[Monto Total] - ([Measures].[Monto Total], ParallelPeriod([Dim Tiempo].[Calendario].[Mes], 1))) 
       / ([Measures].[Monto Total], ParallelPeriod([Dim Tiempo].[Calendario].[Mes], 1)))
    ), FORMAT_STRING = "Percent"
  MEMBER [Measures].[Ticket_Promedio] AS
    [Measures].[Monto Total] / [Measures].[Numero de Ventas],
    FORMAT_STRING = "$#,##0"
SELECT 
  { [Measures].[Numero de Ventas], [Measures].[Monto Total], [Measures].[Crecimiento_MoM], [Measures].[Ticket_Promedio] } ON COLUMNS,
  NON EMPTY [Dim Tiempo].[Calendario].[Mes].Members ON ROWS
FROM [Cubo_Albarran];
```

---

## 5. Fase 2: Dashboard en Power BI

El dashboard en **Power BI** fue concebido como la herramienta de gestión ejecutiva para el Propietario de Mueblería Albarrán y sus Jefes de Local.

### 5.1 Arquitectura en Cuatro Páginas
1. **Página 1: Resumen Ejecutivo y Sucursales (Visión Macro del Negocio)**
   * **Tarjetas KPI Principales:** Ventas Totales ($414,0 MM), Ventas Netas ($347,9 MM), IVA Recaudado ($66,1 MM), Ticket Promedio ($1.134.308) y Descuento Medio (0,0%).
   * **Gráfico Combinado (Barras + Línea):** Ventas brutas mensuales y número de transacciones, destacando el peak de julio ($48,3 MM) y el valle de noviembre ($25,3 MM).
   * **Gráfico de Dona:** Participación de mercado por sucursal (Manquehue 36,1%, Viña del Mar 32,5%, Franklin 31,5%).
   * **Gráfico de Columnas:** Facturación según día de la semana, evidenciando el liderazgo del día sábado ($71,2 MM / 17,2%).
2. **Página 2: Catálogo y Mix de Productos (Auditoría de Portafolio)**
   * **Gráfico de Barras Horizontales:** Concentración por categorías según principio de Pareto (Comedores 28,8%, Sofás 16,5%, Dormitorio 13,4%).
   * **Tabla de Ranking:** Top 10 productos más vendidos liderados por el *Living MJO* ($41,6 MM / 32 unidades).
   * **Alerta Crítica de Catálogo:** Detección de categorías inactivas con 0 ventas y 0 stock (*Buffets* y *Modulares*).
3. **Página 3: Productividad Comercial (Rendimiento de la Fuerza de Ventas)**
   * **Gráfico de Dispersión / Barras de Productividad:** Ratio de ventas respecto al costo salarial anual.
   * **Caso Emblemático de Negocio:**
     * *Romina Vásquez:* Ventas de $77.031.570 con sueldo base anual de $3,06 MM ($255k/mes) $\rightarrow$ **Productividad 25,2x** (Estado Verde).
     * *Pamela Cortez:* Ventas de $76.012.378 con sueldo base anual de $4,80 MM ($400k/mes) $\rightarrow$ **Productividad 15,8x** (Estado Rojo, bajo la meta de 20x).
   * **Recomendación:** Unificar el sueldo base e introducir un esquema de comisiones por venta.
4. **Página 4: Clientes y Canal B2B (Fidelización y Segmentación)**
   * **Tarjetas de Segmento:** 20 clientes únicos con 18,25 compras/cliente al año (compran cada ~20 días, cartera boutique de alta fidelidad).
   * **Gráficos de Composición Demográfica:** Ventas por Sexo (Hombres 68,7% / $284,5 MM) y Rango Etario (Adultos 35-59 concentran el 78,6%).
   * **Canal Factura (Empresas):** 16,2% de transacciones (59 ventas) y $66,3 MM generados.

### 5.2 Catálogo de Medidas DAX (`powerbi/medidas_dax_kpi.dax`)
El modelo semántico incluye medidas DAX explícitas con validación de divisiones seguras (`DIVIDE`) e inteligencia temporal:
* `[Ventas Totales] = SUM(FactVentas[MontoTotal])`
* `[Ventas Mes Anterior] = CALCULATE([Ventas Totales], DATEADD(DimTiempo[Fecha], -1, MONTH))`
* `[Crecimiento MoM Pct] = DIVIDE([Ventas Totales] - [Ventas Mes Anterior], [Ventas Mes Anterior], BLANK())`
* `[Ticket Promedio] = DIVIDE([Ventas Totales], [Numero de Ventas], 0)`
* `[Productividad Vendedor] = DIVIDE([Ventas Totales], [Costo Sueldo Anual], 0)`
* `[Pct Ventas Factura] = DIVIDE([Ventas Factura], [Numero de Ventas], 0)`

---

## 6. Instrucciones de Despliegue y Reproducción

### 6.1 Requisitos Previos
* Windows 10/11 Pro con **SQL Server 2019/2017** (instancia `localhost`).
* **SQL Server Analysis Services (SSAS)** en modo Multidimensional (`localhost:2383`).
* **SQL Server Management Studio (SSMS)** y **Visual Studio** con extensiones SSIS/SSAS.
* Permisos de lectura de `NT Service\MSSQLServerOLAPService` sobre la base `Albarran_DW`.

### 6.2 Pasos de Ejecución (Paso a Paso)

1. **Restaurar el Origen OLTP y Crear el Data Warehouse:**
   * Abrir SSMS y ejecutar `database/scripts/00_restaurar_bd_transaccional.sql` (restaura `Albarran.bak`).
   * Ejecutar `database/scripts/01_crear_modelo_dimensional.sql` (crea la base `Albarran_DW`).
   * *Alternativa rápida:* Restaurar directamente el backup dimensional completo `database/Albarran_DW.bak`.

2. **Ejecutar el Paquete ETL en SSIS:**
   * Abrir `etl/ETL_Albarran.sln` en Visual Studio.
   * Ejecutar el paquete `ETL_Albarran.dtsx` (F5). Validar que todas las tareas finalicen en verde con 365 filas cargadas.
   * Ejecutar `database/scripts/02_validacion_etl.sql` en SSMS para certificar la cuadratura al peso ($414.022.446).

3. **Desplegar y Procesar el Cubo OLAP en SSAS:**
   * **Opción Automatizada (Recomendada):** Abrir PowerShell como Administrador en la raíz del repositorio y ejecutar:
     ```powershell
     powershell -ExecutionPolicy Bypass -File "olap\crear_cubo_ssas.ps1"
     ```
     El script creará la base de datos `OLAP_Albarran`, las 6 dimensiones con sus jerarquías, los grupos de medidas, las fórmulas MDX y los KPIs nativos, procesando el cubo en modo `ProcessFull`.
   * **Opción Manual / Visual Studio:** Abrir `olap/OLAP_Albarran/OLAP_Albarran.sln` en Visual Studio, configurar el servidor en las propiedades del proyecto (`localhost`) y presionar **Build & Deploy**.
   * **Opción XMLA:** Abrir `olap/Deploy_Cubo_Albarran.xmla` en SSMS conectado a Analysis Services y ejecutar (`F5`).

4. **Validar las Consultas MDX en SSMS:**
   * Conectar SSMS al motor **Analysis Services** (`localhost:2383`).
   * Abrir el archivo `database/scripts/05_consultas_mdx_cubo.mdx` y ejecutar cada una de las 10 consultas.

5. **Construir / Abrir el Dashboard en Power BI:**
   * En Power BI Desktop, conectar a la base `Albarran_DW` en `localhost` (o importar los CSVs de `powerbi/datos/`).
   * Importar el tema corporativo `powerbi/Tema_Muebleria_Albarran.json` (Ver -> Temas -> Buscar temas).
   * Crear la tabla de medidas e incorporar las fórmulas DAX desde `powerbi/medidas_dax_kpi.dax`.
   * Seguir las instrucciones visuales de `powerbi/GUIA_PASO_A_PASO_POWERBI.md` para replicar las 4 páginas y guardar como `powerbi/Dashboard_Albarran.pbix`.

---

## 7. Plan de Demostración y Defensa de la Presentación Final

La presentación formal de la defensa (`docs/Albarrán BI_Entrega Final.pptx`) cuenta con **17 diapositivas** calibradas para una sesión de **15 minutos de exposición + 5 minutos de preguntas del profesor**:

* **Minutos 0 - 3 (Contexto y Cimientos DW):** Portada, arquitectura de 5 capas, los 10 KPIs y síntesis de la Fase 1 ($414 MM conciliados al peso en `FactVentas`).
* **Minutos 4 - 8 (Demostración SSAS en Vivo):** Conexión en SSMS al servicio SSAS local, recorrido por el explorador de objetos de `OLAP_Albarran`, jerarquías de tiempo cronológicas, grupos de medidas con DistinctCount y ejecución en vivo de las consultas del script `05_consultas_mdx_cubo.mdx`.
* **Minutos 9 - 13 (Demostración Power BI en Vivo):** Navegación interactiva por las cuatro páginas del dashboard, filtrado cruzado por sucursales y categorías, visualización de los semáforos de KPIs y análisis del caso de productividad de Romina vs. Pamela.
* **Minutos 14 - 15 (Conclusiones y Recomendaciones):** Exposición de las recomendaciones de negocio para el propietario (reactivar stock de Buffets/Modulares, rediseñar comisiones de venta y fidelizar cartera B2B).
* **Minutos 16 - 20 (Ronda de Preguntas):** Respuestas técnicas a las preguntas del profesor sobre optimización MOLAP, granularidad Kimball y medidas DAX.

---

## 8. Conformidad de los Entregables con las Pautas de Evaluación

| Criterio de Evaluación | Requisito Exigido en el Caso | Implementación en la Solución | Entregable Asociado |
|---|---|---|---|
| **Formato de Informe** | Carta, Calibri 11, interlineado 1,5, márgenes normales, numeración inf. der., redacción 3ra persona, max 50 págs. | Cumplimiento estricto al 100% de márgenes (2,5 cm), estilos tipográficos, portadas, índices y bibliografía APA 7. | `docs/Informe_Final_Albarran.docx` (845 KB) |
| **Cubo OLAP (SSAS)** | Proyecto OLAP funcional sobre el DW, dimensiones conformadas, jerarquías y medidas de los 10 KPIs. | Proyecto SSAS Multidimensional desplegado y procesado en `localhost:2383` con 3 Measure Groups, DistinctCounts aislados y script MDX. | `olap/OLAP_Albarran/`, `Deploy_Cubo_Albarran.xmla`, `05_consultas_mdx_cubo.mdx` |
| **Dashboard Power BI** | Panel interactivo orientado al usuario final con soporte a la toma de decisiones gerenciales. | 4 páginas interactivas (Resumen, Catálogo Pareto, Productividad Comercial y Clientes B2B), DAX explícito y tema corporativo. | `powerbi/`, `medidas_dax_kpi.dax`, `GUIA_PASO_A_PASO_POWERBI.md` |
| **Presentación y Defensa** | Estructurada para 15 min de defensa + 5 min de preguntas, con notas de orador en cada diapositiva. | 17 diapositivas panorámicas 16:9 con tarjetas de métricas, capturas de pantalla integradas y notas de orador completas. | `docs/Albarrán BI_Entrega Final.pptx` (366 KB) |
| **Consistencia de Datos** | Trazabilidad numérica absoluta entre origen relacional y capas analíticas. | Conciliación al 100% en $414.022.446, 365 ventas y 724 unidades en SQL, SSAS MDX y Power BI DAX. | Certificado en informes y scripts de validación |

---
*Trabajo realizado por Ivan Papic y Alberto Aguilera para la asignatura Inteligencia de Negocios (Paralelo 300), Universidad Técnica Federico Santa María.*
