/* =====================================================================
   04 - Backup de la base dimensional con los datos cargados
   ---------------------------------------------------------------------
   Ejecutar DESPUÉS de correr el paquete SSIS y validar (script 03).
   El archivo resultante (Albarran_DW.bak) se sube a la carpeta /backup
   del repositorio. Ajustar la ruta a una carpeta con permisos para el
   servicio de SQL Server.
   ===================================================================== */
USE master;
GO
BACKUP DATABASE Albarran_DW
    TO DISK = N'C:\BI\Albarran_DW.bak'
    WITH FORMAT, INIT, COMPRESSION,
         NAME = N'Albarran_DW - Full (Fase 1, datos cargados por SSIS)',
         STATS = 10;
GO
-- Verificar que el backup es legible
RESTORE VERIFYONLY FROM DISK = N'C:\BI\Albarran_DW.bak';
GO
/* Nota: si la edición de SQL Server no admite COMPRESSION (p. ej. Express),
   quitar esa opción. */
