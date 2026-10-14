/* =====================================================================
   03 - Validación de la carga ETL (ejecutar después del paquete SSIS)
   ---------------------------------------------------------------------
   Compara origen (Albarran) vs destino (Albarran_DW). Cada consulta
   indica el valor ESPERADO según el análisis de los datos de origen.
   ===================================================================== */
USE Albarran_DW;
GO

/* V1. Conteo de filas por tabla (excluye miembro desconocido -1) */
SELECT 'DimCliente'       AS Tabla, (SELECT COUNT(*) FROM Albarran.dbo.clientes)   AS Origen, COUNT(*) AS Destino FROM dbo.DimCliente       WHERE ClienteKey <> -1
UNION ALL
SELECT 'DimEmpleado',      (SELECT COUNT(*) FROM Albarran.dbo.empleados),  COUNT(*) FROM dbo.DimEmpleado      WHERE EmpleadoKey <> -1
UNION ALL
SELECT 'DimProducto',      (SELECT COUNT(*) FROM Albarran.dbo.productos),  COUNT(*) FROM dbo.DimProducto      WHERE ProductoKey <> -1
UNION ALL
SELECT 'DimSucursal',      (SELECT COUNT(*) FROM Albarran.dbo.sucursales), COUNT(*) FROM dbo.DimSucursal      WHERE SucursalKey <> -1
UNION ALL
SELECT 'DimTipoDocumento', (SELECT COUNT(DISTINCT tipo_documento) FROM Albarran.dbo.ventas), COUNT(*) FROM dbo.DimTipoDocumento WHERE TipoDocumentoKey <> -1
UNION ALL
SELECT 'DimTiempo (días 2017-2018)', 730, COUNT(*) FROM dbo.DimTiempo WHERE TiempoKey <> -1
UNION ALL
SELECT 'FactVentas',       (SELECT COUNT(*) FROM Albarran.dbo.detalle_ventas), COUNT(*) FROM dbo.FactVentas;
-- Esperado: 20/20, 15/15, 20/20, 3/3, 2/2, 730/730, 365/365

/* V2. Conciliación de montos y unidades */
SELECT
    (SELECT SUM(CAST(cantidad AS bigint) * precio_unitario) FROM Albarran.dbo.detalle_ventas) AS MontoOrigen,
    SUM(MontoBruto)  AS MontoBrutoDW,
    (SELECT SUM(cantidad) FROM Albarran.dbo.detalle_ventas) AS UnidadesOrigen,
    SUM(Cantidad)    AS UnidadesDW,
    SUM(MontoNeto)   AS MontoNetoDW,
    SUM(MontoIVA)    AS MontoIVADW
FROM dbo.FactVentas;
-- Esperado: 414.022.446 = 414.022.446 ; 724 = 724 ; Neto 347.918.028 ; IVA 66.104.418

/* V3. Integridad referencial: hechos sin clave (miembro desconocido) */
SELECT
    SUM(CASE WHEN TiempoKey        = -1 THEN 1 ELSE 0 END) AS SinTiempo,
    SUM(CASE WHEN ClienteKey       = -1 THEN 1 ELSE 0 END) AS SinCliente,
    SUM(CASE WHEN EmpleadoKey      = -1 THEN 1 ELSE 0 END) AS SinEmpleado,
    SUM(CASE WHEN ProductoKey      = -1 THEN 1 ELSE 0 END) AS SinProducto,
    SUM(CASE WHEN SucursalKey      = -1 THEN 1 ELSE 0 END) AS SinSucursal,
    SUM(CASE WHEN TipoDocumentoKey = -1 THEN 1 ELSE 0 END) AS SinTipoDocumento
FROM dbo.FactVentas;
-- Esperado: todo 0

/* V4. Filas rechazadas por calidad y bitácora de ejecución */
SELECT COUNT(*) AS FilasRechazadas FROM dbo.FactVentas_Rechazos;   -- Esperado: 0
SELECT TOP (5) * FROM dbo.EtlLog ORDER BY EjecucionID DESC;        -- Esperado: 365 leídas / 365 cargadas / 0 rechazadas

/* V5. Comparación fila a fila (debe devolver 0 filas) */
SELECT v.venta_id, d.producto_id, d.cantidad, d.precio_unitario
FROM Albarran.dbo.ventas v
JOIN Albarran.dbo.detalle_ventas d ON d.venta_id = v.venta_id
EXCEPT
SELECT f.VentaID, f.ProductoID, f.Cantidad, CAST(f.PrecioUnitario AS int)
FROM dbo.FactVentas f;

/* V6. Consistencia de claves: la fecha, cliente y sucursal de cada hecho coinciden con el origen (debe devolver 0) */
SELECT COUNT(*) AS Inconsistencias
FROM dbo.FactVentas f
JOIN Albarran.dbo.ventas v      ON v.venta_id = f.VentaID
JOIN dbo.DimTiempo t            ON t.TiempoKey = f.TiempoKey
JOIN dbo.DimCliente c           ON c.ClienteKey = f.ClienteKey
JOIN dbo.DimSucursal s          ON s.SucursalKey = f.SucursalKey
JOIN dbo.DimEmpleado e          ON e.EmpleadoKey = f.EmpleadoKey
WHERE t.Fecha <> CAST(v.fecha AS date)
   OR c.ClienteID <> v.cliente_id
   OR s.SucursalID <> v.sucursal_id
   OR e.EmpleadoID <> v.vendedor_id;

/* V7. Muestra de transformaciones aplicadas */
SELECT TOP (5) ClienteID, NombreCompleto, Sexo, Edad, RangoEtario, EstadoCivil FROM dbo.DimCliente WHERE ClienteKey <> -1 ORDER BY ClienteID;
SELECT EmpleadoID, NombreCompleto, Cargo, AniosAntiguedad, SueldoBase FROM dbo.DimEmpleado WHERE EmpleadoKey <> -1 ORDER BY EmpleadoID;
SELECT ProductoID, NombreProducto, Categoria, Descripcion, PrecioLista, RangoPrecio FROM dbo.DimProducto WHERE ProductoKey <> -1 ORDER BY ProductoID;
SELECT * FROM dbo.DimSucursal;
SELECT * FROM dbo.DimTipoDocumento;
GO
