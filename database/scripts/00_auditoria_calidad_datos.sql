USE Albarran;
GO

SELECT 
    '1. Total Ventas 2017' AS Prueba, 
    CAST(COUNT(*) AS VARCHAR) AS Resultado, 
    '365' AS Esperado 
FROM ventas

UNION ALL

SELECT 
    '2. Monto Total (IVA incl.)', 
    FORMAT(SUM((cantidad * precio_unitario) - descuento), 'C', 'es-CL'), 
    '$414.022.446' 
FROM detalle_ventas

UNION ALL

SELECT 
    '3. FK Nulas en Ventas', 
    CAST(COUNT(*) AS VARCHAR), 
    '0' 
FROM ventas 
WHERE cliente_id IS NULL 
   OR vendedor_id IS NULL 
   OR sucursal_id IS NULL

UNION ALL

SELECT 
    '4. Ventas sin Detalle', 
    CAST(COUNT(*) AS VARCHAR), 
    '0' 
FROM ventas v 
LEFT JOIN detalle_ventas dv 
    ON v.venta_id = dv.venta_id 
WHERE dv.venta_id IS NULL

UNION ALL

SELECT 
    '5. Detalles sin Venta', 
    CAST(COUNT(*) AS VARCHAR), 
    '0' 
FROM detalle_ventas dv 
LEFT JOIN ventas v 
    ON dv.venta_id = v.venta_id 
WHERE v.venta_id IS NULL

UNION ALL

SELECT 
    '6. Diferencias Precio Venta vs Lista', 
    CAST(COUNT(*) AS VARCHAR), 
    '0' 
FROM detalle_ventas dv 
INNER JOIN productos p 
    ON dv.producto_id = p.producto_id 
WHERE dv.precio_unitario <> p.precio;