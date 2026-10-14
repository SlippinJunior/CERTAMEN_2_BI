/* =====================================================================
   00 - Restaurar la base transaccional (OLTP) "Albarran" desde Albarran.bak
   Mueblería Albarrán - Caso Semestral Inteligencia de Negocios - Fase 1

   ===================================================================== */
USE master;
GO
DECLARE @RutaBak  nvarchar(400) = N'C:\BI\Albarran.bak';
DECLARE @RutaData nvarchar(400) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS nvarchar(400));
DECLARE @RutaLog  nvarchar(400) = CAST(SERVERPROPERTY('InstanceDefaultLogPath')  AS nvarchar(400));
DECLARE @mdf nvarchar(400) = @RutaData + N'Albarran.mdf';
DECLARE @ldf nvarchar(400) = @RutaLog  + N'Albarran_log.ldf';

-- RESTORE FILELISTONLY FROM DISK = @RutaBak;   -- (opcional) ver nombres lógicos

RESTORE DATABASE Albarran
    FROM DISK = @RutaBak
    WITH MOVE N'Albarran1'     TO @mdf,
         MOVE N'Albarran1_log' TO @ldf,
         REPLACE, STATS = 10;
GO
-- Verificación
SELECT 'ventas' AS tabla, COUNT(*) AS filas FROM Albarran.dbo.ventas
UNION ALL SELECT 'detalle_ventas', COUNT(*) FROM Albarran.dbo.detalle_ventas
UNION ALL SELECT 'clientes', COUNT(*) FROM Albarran.dbo.clientes
UNION ALL SELECT 'empleados', COUNT(*) FROM Albarran.dbo.empleados
UNION ALL SELECT 'productos', COUNT(*) FROM Albarran.dbo.productos;

GO
