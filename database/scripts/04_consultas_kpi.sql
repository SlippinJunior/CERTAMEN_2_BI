/* =====================================================================
   05 - Consultas de los KPI sobre el modelo dimensional
   ---------------------------------------------------------------------
   Demuestran que el modelo responde a los indicadores definidos.
   (En la Fase 2 estas métricas se implementarán en el cubo OLAP.)
   Valores de referencia (año 2017) entre comentarios.
   ===================================================================== */
USE Albarran_DW;
GO

/* KPI 1 - Ventas totales y crecimiento mensual (%) */
WITH m AS (
    SELECT t.Anio, t.Mes, t.NombreMes, SUM(f.MontoTotal) AS Ventas, COUNT(DISTINCT f.VentaID) AS NumVentas
    FROM dbo.FactVentas f JOIN dbo.DimTiempo t ON t.TiempoKey = f.TiempoKey
    GROUP BY t.Anio, t.Mes, t.NombreMes
)
SELECT Anio, Mes, NombreMes, Ventas, NumVentas,
       CAST(100.0 * (Ventas - LAG(Ventas) OVER (ORDER BY Anio, Mes))
            / NULLIF(LAG(Ventas) OVER (ORDER BY Anio, Mes), 0) AS decimal(9,1)) AS CrecimientoPct
FROM m ORDER BY Anio, Mes;


/* KPI 2 - Ticket promedio por venta (global y por sucursal) */
SELECT s.NombreSucursal,
       SUM(f.MontoTotal) AS Ventas,
       COUNT(DISTINCT f.VentaID) AS NumVentas,
       CAST(SUM(f.MontoTotal) / COUNT(DISTINCT f.VentaID) AS decimal(18,0)) AS TicketPromedio
FROM dbo.FactVentas f JOIN dbo.DimSucursal s ON s.SucursalKey = f.SucursalKey
GROUP BY ROLLUP (s.NombreSucursal);

/* KPI 3 - Participación de ventas por sucursal (%) */
SELECT s.NombreSucursal, s.Comuna, s.Region,
       SUM(f.MontoTotal) AS Ventas,
       CAST(100.0 * SUM(f.MontoTotal) / SUM(SUM(f.MontoTotal)) OVER () AS decimal(5,1)) AS ParticipacionPct
FROM dbo.FactVentas f JOIN dbo.DimSucursal s ON s.SucursalKey = f.SucursalKey
GROUP BY s.NombreSucursal, s.Comuna, s.Region
ORDER BY Ventas DESC;


/* KPI 4 - Ventas y unidades por categoría de producto (mix de ventas) */
SELECT p.Categoria,
       SUM(f.Cantidad) AS Unidades,
       SUM(f.MontoTotal) AS Ventas,
       CAST(100.0 * SUM(f.MontoTotal) / SUM(SUM(f.MontoTotal)) OVER () AS decimal(5,1)) AS ParticipacionPct
FROM dbo.FactVentas f JOIN dbo.DimProducto p ON p.ProductoKey = f.ProductoKey
GROUP BY p.Categoria
ORDER BY Ventas DESC;


/* KPI 5 - Ranking de productos (top / bottom) */
SELECT TOP (5) p.NombreProducto, p.Categoria, SUM(f.Cantidad) AS Unidades, SUM(f.MontoTotal) AS Ventas
FROM dbo.FactVentas f JOIN dbo.DimProducto p ON p.ProductoKey = f.ProductoKey
GROUP BY p.NombreProducto, p.Categoria ORDER BY Ventas DESC;

/* KPI 6 - Desempeño y productividad de vendedores
   Productividad = Ventas anuales / Costo anual de sueldo base */
SELECT e.NombreCompleto, e.SueldoBase,
       COUNT(DISTINCT f.VentaID) AS NumVentas,
       SUM(f.MontoTotal) AS Ventas,
       CAST(SUM(f.MontoTotal) / COUNT(DISTINCT f.VentaID) AS decimal(18,0)) AS TicketPromedio,
       CAST(SUM(f.MontoTotal) / (e.SueldoBase * 12) AS decimal(9,1)) AS ProductividadVecesSueldo
FROM dbo.FactVentas f JOIN dbo.DimEmpleado e ON e.EmpleadoKey = f.EmpleadoKey
GROUP BY e.NombreCompleto, e.SueldoBase
ORDER BY Ventas DESC;


/* KPI 7 - Mix de documentos: % ventas con factura (clientes empresa) */
SELECT d.TipoDocumento, d.TipoVenta,
       COUNT(DISTINCT f.VentaID) AS NumVentas,
       CAST(100.0 * COUNT(DISTINCT f.VentaID) / SUM(COUNT(DISTINCT f.VentaID)) OVER () AS decimal(5,1)) AS PctTransacciones,
       CAST(100.0 * SUM(f.MontoTotal) / SUM(SUM(f.MontoTotal)) OVER () AS decimal(5,1)) AS PctMonto
FROM dbo.FactVentas f JOIN dbo.DimTipoDocumento d ON d.TipoDocumentoKey = f.TipoDocumentoKey
GROUP BY d.TipoDocumento, d.TipoVenta;


/* KPI 8 - Ventas por segmento de cliente (sexo, rango etario, estado civil) */
SELECT c.Sexo, c.RangoEtario, c.EstadoCivil,
       COUNT(DISTINCT c.ClienteKey) AS Clientes,
       SUM(f.MontoTotal) AS Ventas,
       CAST(100.0 * SUM(f.MontoTotal) / SUM(SUM(f.MontoTotal)) OVER () AS decimal(5,1)) AS ParticipacionPct
FROM dbo.FactVentas f JOIN dbo.DimCliente c ON c.ClienteKey = f.ClienteKey
GROUP BY c.Sexo, c.RangoEtario, c.EstadoCivil
ORDER BY Ventas DESC;

/* KPI 9 - Frecuencia de compra por cliente */
SELECT COUNT(DISTINCT ClienteKey) AS ClientesActivos,
       CAST(1.0 * COUNT(DISTINCT VentaID) / COUNT(DISTINCT ClienteKey) AS decimal(9,2)) AS ComprasPorCliente
FROM dbo.FactVentas;


/* KPI 10 - Descuento promedio otorgado (%) */
SELECT CAST(100.0 * SUM(MontoDescuento) / NULLIF(SUM(MontoBruto), 0) AS decimal(5,2)) AS DescuentoPromedioPct
FROM dbo.FactVentas;


/* Ventas por día de semana / estación */
SELECT t.DiaSemana, t.NombreDia, SUM(f.MontoTotal) AS Ventas
FROM dbo.FactVentas f JOIN dbo.DimTiempo t ON t.TiempoKey = f.TiempoKey
GROUP BY t.DiaSemana, t.NombreDia ORDER BY t.DiaSemana;
GO
