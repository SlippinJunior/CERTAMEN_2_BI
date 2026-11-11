# Guía Paso a Paso: Construcción del Dashboard en Power BI Desktop
**Mueblería Albarrán · Inteligencia de Negocios · Fase 2**

Esta guía proporciona el procedimiento detallado, clic a clic, para construir el archivo **`Dashboard_Albarran.pbix`** en Power BI Desktop a partir del Data Warehouse `Albarran_DW` (o de los archivos CSV ya exportados y limpios en la carpeta `powerbi/datos/`).

---

## 1. Conexión de Datos y Preparación del Modelo

### Opción A: Conexión Directa a SQL Server (Recomendada)
1. Abrir **Power BI Desktop**.
2. En la cinta de opciones superior (**Inicio**), hacer clic en **Obtener datos** $\rightarrow$ **SQL Server**.
3. Configurar la conexión:
   * **Servidor:** `localhost` (o `.` o el nombre de tu equipo).
   * **Base de datos:** `Albarran_DW`.
   * **Modo de conectividad:** Seleccionar **Importar** (para máxima velocidad y cálculos DAX completos).
4. En la ventana del Navegador, marcar las 7 tablas del modelo en estrella:
   * `dbo.DimTiempo`
   * `dbo.DimSucursal`
   * `dbo.DimProducto`
   * `dbo.DimCliente`
   * `dbo.DimEmpleado`
   * `dbo.DimTipoDocumento`
   * `dbo.FactVentas`
5. Hacer clic en **Cargar**.

### Opción B: Carga desde Archivos CSV (Contingencia / Sin SQL Server)
1. Si no se tiene acceso directo a la instancia local, en **Inicio** $\rightarrow$ **Obtener datos** $\rightarrow$ **Texto o CSV**.
2. Cargar uno a uno los 7 archivos ubicados en la carpeta `powerbi/datos/`:
   `DimTiempo.csv`, `DimSucursal.csv`, `DimProducto.csv`, `DimCliente.csv`, `DimEmpleado.csv`, `DimTipoDocumento.csv`, `FactVentas.csv`.
3. Hacer clic en **Cargar**.

---

## 2. Aplicar el Tema Corporativo de Mueblería Albarrán

1. En la cinta de opciones superior, ir a la pestaña **Ver** (View).
2. En la sección **Temas** (Themes), desplegar la flecha hacia abajo y seleccionar **Buscar temas...** (Browse for themes).
3. Navegar hasta la carpeta `powerbi/` del proyecto y seleccionar el archivo:
   **`Tema_Muebleria_Albarran.json`**
4. Aparecerá un mensaje confirmando que el tema corporativo (Nogal cálido `#A35C2B`, Azul marino `#1B2A4A`, Gris `#F8F9FA`) se importó con éxito.

---

## 3. Verificación de Relaciones en la Vista de Modelo

1. Hacer clic en el icono **Vista de modelo** (a la izquierda, tercer botón).
2. Verificar que existan las 6 relaciones en esquema estrella con cardinalidad **Uno a varios (1:*)** y dirección de filtro **Única**, uniendo las dimensiones con `FactVentas`:
   * `DimTiempo[TiempoKey]` $\rightarrow$ `FactVentas[TiempoKey]`
   * `DimSucursal[SucursalKey]` $\rightarrow$ `FactVentas[SucursalKey]`
   * `DimProducto[ProductoKey]` $\rightarrow$ `FactVentas[ProductoKey]`
   * `DimCliente[ClienteKey]` $\rightarrow$ `FactVentas[ClienteKey]`
   * `DimEmpleado[EmpleadoKey]` $\rightarrow$ `FactVentas[EmpleadoKey]`
   * `DimTipoDocumento[TipoDocumentoKey]` $\rightarrow$ `FactVentas[TipoDocumentoKey]`

---

## 4. Crear la Tabla de Medidas y Copiar las Medidas DAX

Para mantener el proyecto ordenado según las mejores prácticas de Power BI:
1. En la pestaña **Inicio**, hacer clic en **Especificar datos** (Enter Data).
2. Asignar el nombre `_Medidas` a la tabla y hacer clic en **Cargar**.
3. Abrir el archivo **`powerbi/medidas_dax_kpi.dax`** y crear una a una las medidas haciendo clic derecho en la tabla `_Medidas` $\rightarrow$ **Nueva medida**:

### Principales Medidas DAX a Crear:
```dax
Ventas Totales = SUM(FactVentas[MontoTotal])
Ventas Netas = SUM(FactVentas[MontoNeto])
IVA Total = SUM(FactVentas[MontoIVA])
Unidades Vendidas = SUM(FactVentas[Cantidad])
Numero de Ventas = DISTINCTCOUNT(FactVentas[VentaID])
Clientes Activos = DISTINCTCOUNT(FactVentas[ClienteKey])
Ticket Promedio = DIVIDE([Ventas Totales], [Numero de Ventas], 0)

Ventas Mes Anterior = 
CALCULATE(
    [Ventas Totales],
    DATEADD(DimTiempo[Fecha], -1, MONTH)
)

Crecimiento MoM Pct = 
VAR VentasActual = [Ventas Totales]
VAR VentasPrev = [Ventas Mes Anterior]
RETURN
DIVIDE(VentasActual - VentasPrev, VentasPrev, BLANK())

Costo Sueldo Anual = SUM(DimEmpleado[SueldoBaseAnual])

Productividad Vendedor = 
DIVIDE([Ventas Totales], [Costo Sueldo Anual], 0)

Ventas Factura = 
CALCULATE(
    [Numero de Ventas],
    DimTipoDocumento[TipoDocumento] = "Factura"
)

Pct Ventas Factura = 
DIVIDE([Ventas Factura], [Numero de Ventas], 0)
```

---

## 5. Construcción de las 4 Páginas del Reporte

### Página 1: Resumen Ejecutivo y Sucursales (Renombrar página a "Resumen Ejecutivo")
1. **Encabezado Superior:**
   * Insertar un cuadro de texto: *"MUEBLERÍA ALBARRÁN · RESUMEN EJECUTIVO & SUCURSALES"*, fondo Azul Marino `#1B2A4A`, texto blanco, Calibri 18pt negrita.
2. **Fila de Tarjetas KPI (Cards):**
   * Crear 5 visuales tipo **Tarjeta (Card)** alineados horizontalmente:
     * Card 1: `[Ventas Totales]` (Formato Moneda `$414.022.446`).
     * Card 2: `[Ventas Netas]` (`$347.918.028`).
     * Card 3: `[IVA Total]` (`$66.104.418`).
     * Card 4: `[Ticket Promedio]` (`$1.134.308`).
     * Card 5: `[Numero de Ventas]` (`365 ventas`).
3. **Gráfico Combinado (Línea y Columnas Apiladas):**
   * *Eje X:* `DimTiempo[MesNombre]` (asegurar que en la vista de datos `MesNombre` esté ordenado por `MesNumero`).
   * *Eje de columnas:* `[Ventas Totales]`.
   * *Eje de líneas:* `[Numero de Ventas]`.
   * *Título:* *"Evolución de Ventas y Transacciones Mensuales (Estacionalidad 2017)"*.
   * *Hallazgo visual:* Se apreciará el peak en Julio ($48,3 MM / 41 transacciones) y el valle en Noviembre ($25,3 MM / 21 transacciones).
4. **Gráfico de Dona (Sucursales):**
   * *Leyenda:* `DimSucursal[Sucursal]`.
   * *Valores:* `[Ventas Totales]`.
   * *Título:* *"Participación de Ventas por Sucursal"*.
   * *Resultado:* Manquehue (36,1%), Viña del Mar (32,5%), Franklin (31,5%).
5. **Gráfico de Columnas Agrupadas (Ventas por Día):**
   * *Eje X:* `DimTiempo[DiaSemanaNombre]` (ordenado por `DiaSemanaNumero`).
   * *Eje Y:* `[Ventas Totales]`.
   * *Título:* *"Ventas según Día de la Semana"*.
   * *Resultado:* Liderazgo del día Sábado ($71,2 MM / 17,2%).

---

### Página 2: Catálogo y Mix de Productos (Renombrar a "Catálogo y Productos")
1. **Encabezado Superior:** *"MUEBLERÍA ALBARRÁN · CATÁLOGO & MIX DE PRODUCTOS"*.
2. **Gráfico de Barras Horizontales:**
   * *Eje Y:* `DimProducto[Categoria]`.
   * *Eje X:* `[Ventas Totales]`.
   * *Etiquetas de datos:* Activadas con porcentaje del total.
   * *Título:* *"Mix de Ventas por Categoría (Concentración Pareto)"*.
   * *Resultado:* Comedores (28,8%), Sofás (16,5%), Dormitorio (13,4%).
3. **Tabla de Ranking Top Productos:**
   * *Columnas:* `DimProducto[Producto]`, `DimProducto[Categoria]`, `[Unidades Vendidas]`, `[Ventas Totales]`.
   * *Ordenar:* Por `[Ventas Totales]` descendente.
   * *Resultado:* Primer lugar indiscutido para el producto *"Living MJO"* ($41.600.000 / 32 unidades).
4. **Cuadro de Alerta Crítica de Negocio:**
   * Insertar una tarjeta o cuadro de texto con borde rojo:
     > ⚠️ **ALERTA CRÍTICA DE CATÁLOGO:** Las categorías **Buffets** y **Modulares** registran **0 productos en catálogo** y **$0 ventas** en todo 2017. Representan una oportunidad de abastecimiento perdida frente a la competencia.

---

### Página 3: Productividad Comercial (Renombrar a "Productividad Comercial")
1. **Encabezado Superior:** *"MUEBLERÍA ALBARRÁN · PRODUCTIVIDAD DE LA FUERZA DE VENTAS"*.
2. **Tarjetas Superiores:**
   * Meta de Productividad: `20,0x sueldo anual`.
   * Vendedor Líder: `Romina Vásquez` (`25,2x`).
3. **Gráfico de Barras Horizontales:**
   * *Eje Y:* `DimEmpleado[Empleado]`.
   * *Eje X:* `[Productividad Vendedor]`.
   * *Línea de referencia / constante:* Agregar línea de meta en `20.0` (color rojo punteado).
4. **Tabla de Auditoría Salarial y Desempeño:**
   * *Columnas:*
     - `DimEmpleado[Empleado]`
     - `DimEmpleado[Cargo]`
     - `[Ventas Totales]`
     - `[Costo Sueldo Anual]`
     - `[Productividad Vendedor]`
   * *Hallazgo Clave:*
     - **Romina Vásquez:** Ventas $77.031.570 | Sueldo $3.060.000 | **Productividad 25,2x** (Verde).
     - **Pamela Cortez:** Ventas $76.012.378 | Sueldo $4.800.000 | **Productividad 15,8x** (Rojo, ineficiencia salarial).

---

### Página 4: Clientes y Canal B2B (Renombrar a "Clientes y Canal B2B")
1. **Encabezado Superior:** *"MUEBLERÍA ALBARRÁN · CLIENTES & CANAL EMPRESAS B2B"*.
2. **Fila de Tarjetas:**
   * Clientes en Cartera: `20 clientes`.
   * Frecuencia Media: `18,25 compras/cliente al año`.
   * % Ventas Factura B2B: `16,2%` (Meta: `20,0%`).
3. **Gráfico de Dona (Segmentación por Género):**
   * *Leyenda:* `DimCliente[Sexo]`.
   * *Valores:* `[Ventas Totales]`.
   * *Resultado:* Masculino (68,7% / $284,5 MM) vs. Femenino (31,3% / $129,5 MM).
4. **Gráfico de Columnas (Rango Etario):**
   * *Eje X:* `DimCliente[RangoEtario]`.
   * *Eje Y:* `[Ventas Totales]`.
   * *Resultado:* Adultos (35 a 59 años) concentran el 78,6% de las compras.
5. **Tabla de Canal de Venta:**
   * *Columnas:* `DimTipoDocumento[TipoDocumento]`, `[Numero de Ventas]`, `[Ventas Totales]`, `[Ticket Promedio]`.
   * *Resultado:* Factura genera $66.279.778 en 59 transacciones con ticket promedio de $1.124.000.

---

## 6. Guardar el Archivo

1. En la pestaña **Archivo** (File), hacer clic en **Guardar como...** (Save As).
2. Guardar el archivo en la carpeta `powerbi/` con el nombre:
   **`Dashboard_Albarran.pbix`**
3. El archivo queda listo en tu equipo para la defensa y presentación.
   *(Nota: El archivo `.pbix` está excluido en el `.gitignore` por solicitud, de modo que el repositorio de GitHub se mantiene liviano y limpio, conteniendo las medidas DAX, datos limpios, tema corporativo y capturas en alta resolución).*
