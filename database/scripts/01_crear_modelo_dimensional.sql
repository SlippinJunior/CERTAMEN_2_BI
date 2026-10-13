/* =====================================================================
   01 - Creación del modelo dimensional (esquema ESTRELLA) "Albarran_DW"
   Mueblería Albarrán - Caso Semestral Inteligencia de Negocios - Fase 1
   ---------------------------------------------------------------------
   Proceso de negocio : Ventas
   Granularidad       : una fila por producto vendido en cada venta
                        (línea de detalle_ventas)
   Dimensiones        : DimTiempo, DimCliente, DimEmpleado, DimProducto,
                        DimSucursal, DimTipoDocumento
   Hechos             : FactVentas
   Soporte ETL        : FactVentas_Rechazos, EtlLog,
                        usp_PrepararCarga, usp_CargarDimTiempo
   ---------------------------------------------------------------------
   El script es re-ejecutable: elimina y vuelve a crear la base.
   ===================================================================== */
USE master;
GO
IF DB_ID(N'Albarran_DW') IS NOT NULL
BEGIN
    ALTER DATABASE Albarran_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Albarran_DW;
END
GO
CREATE DATABASE Albarran_DW;
GO
ALTER DATABASE Albarran_DW SET RECOVERY SIMPLE;
GO
USE Albarran_DW;
GO

/* ---------------------------------------------------------------------
   DIMENSIÓN TIEMPO  (clave inteligente AAAAMMDD, granularidad = día)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.DimTiempo (
    TiempoKey        int           NOT NULL,           -- AAAAMMDD (-1 = desconocido)
    Fecha            date          NOT NULL,
    Anio             smallint      NOT NULL,
    Semestre         tinyint       NOT NULL,
    NombreSemestre   nvarchar(20)  NOT NULL,           -- '1er Semestre'
    Trimestre        tinyint       NOT NULL,
    NombreTrimestre  nvarchar(20)  NOT NULL,           -- 'T1'
    Mes              tinyint       NOT NULL,
    NombreMes        nvarchar(20)  NOT NULL,           -- 'Enero'
    AnioMes          char(7)       NOT NULL,           -- '2017-01'
    SemanaAnio       tinyint       NOT NULL,           -- ISO
    DiaMes           tinyint       NOT NULL,
    DiaSemana        tinyint       NOT NULL,           -- 1 = Lunes ... 7 = Domingo
    NombreDia        nvarchar(20)  NOT NULL,
    EsFinDeSemana    bit           NOT NULL,
    Estacion         nvarchar(20)  NOT NULL,           -- estación del año (hemisferio sur)
    CONSTRAINT PK_DimTiempo PRIMARY KEY CLUSTERED (TiempoKey),
    CONSTRAINT UQ_DimTiempo_Fecha UNIQUE (Fecha)
);
GO

/* ---------------------------------------------------------------------
   DIMENSIÓN CLIENTE
   --------------------------------------------------------------------- */
CREATE TABLE dbo.DimCliente (
    ClienteKey       int IDENTITY(1,1) NOT NULL,       -- clave subrogada
    ClienteID        int           NOT NULL,           -- clave natural (clientes.cliente_id)
    Nombre           nvarchar(100) NOT NULL,
    ApellidoPaterno  nvarchar(100) NOT NULL,
    ApellidoMaterno  nvarchar(100) NOT NULL,
    NombreCompleto   nvarchar(300) NOT NULL,
    Sexo             nvarchar(20)  NOT NULL,           -- 'Masculino' / 'Femenino'
    FechaNacimiento  date          NULL,
    Edad             int           NULL,               -- a la fecha de carga
    RangoEtario      nvarchar(30)  NOT NULL,
    EstadoCivil      nvarchar(30)  NOT NULL,
    CONSTRAINT PK_DimCliente PRIMARY KEY CLUSTERED (ClienteKey)
);
CREATE UNIQUE INDEX UX_DimCliente_ClienteID ON dbo.DimCliente (ClienteID);
GO

/* ---------------------------------------------------------------------
   DIMENSIÓN EMPLEADO (vendedor)  -- cargos desnormalizado
   --------------------------------------------------------------------- */
CREATE TABLE dbo.DimEmpleado (
    EmpleadoKey      int IDENTITY(1,1) NOT NULL,
    EmpleadoID       int           NOT NULL,           -- empleados.empleado_id
    Nombre           nvarchar(100) NOT NULL,
    ApellidoPaterno  nvarchar(100) NOT NULL,
    ApellidoMaterno  nvarchar(100) NOT NULL,
    NombreCompleto   nvarchar(300) NOT NULL,
    CargoID          int           NOT NULL,
    Cargo            nvarchar(100) NOT NULL,           -- cargos.nombre
    FechaContrato    date          NULL,
    AniosAntiguedad  int           NULL,               -- a la fecha de carga
    SueldoBase       decimal(18,2) NOT NULL,
    CONSTRAINT PK_DimEmpleado PRIMARY KEY CLUSTERED (EmpleadoKey)
);
CREATE UNIQUE INDEX UX_DimEmpleado_EmpleadoID ON dbo.DimEmpleado (EmpleadoID);
GO

/* ---------------------------------------------------------------------
   DIMENSIÓN PRODUCTO  -- categorias desnormalizado
   --------------------------------------------------------------------- */
CREATE TABLE dbo.DimProducto (
    ProductoKey      int IDENTITY(1,1) NOT NULL,
    ProductoID       int           NOT NULL,           -- productos.producto_id
    NombreProducto   nvarchar(255) NOT NULL,
    Descripcion      nvarchar(255) NOT NULL,           -- 'Sin descripción' si NULL
    CategoriaID      int           NOT NULL,
    Categoria        nvarchar(100) NOT NULL,
    PrecioLista      decimal(18,2) NOT NULL,
    RangoPrecio      nvarchar(40)  NOT NULL,
    CONSTRAINT PK_DimProducto PRIMARY KEY CLUSTERED (ProductoKey)
);
CREATE UNIQUE INDEX UX_DimProducto_ProductoID ON dbo.DimProducto (ProductoID);
GO

/* ---------------------------------------------------------------------
   DIMENSIÓN SUCURSAL  -- comunas desnormalizado + región derivada
   --------------------------------------------------------------------- */
CREATE TABLE dbo.DimSucursal (
    SucursalKey      int IDENTITY(1,1) NOT NULL,
    SucursalID       int           NOT NULL,           -- sucursales.sucursal_id
    NombreSucursal   nvarchar(100) NOT NULL,
    ComunaID         int           NOT NULL,
    Comuna           nvarchar(100) NOT NULL,
    Region           nvarchar(100) NOT NULL,
    CONSTRAINT PK_DimSucursal PRIMARY KEY CLUSTERED (SucursalKey)
);
CREATE UNIQUE INDEX UX_DimSucursal_SucursalID ON dbo.DimSucursal (SucursalID);
GO

/* ---------------------------------------------------------------------
   DIMENSIÓN TIPO DE DOCUMENTO  (boleta / factura)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.DimTipoDocumento (
    TipoDocumentoKey     int IDENTITY(1,1) NOT NULL,
    TipoDocumentoCodigo  nvarchar(20)  NOT NULL,       -- valor original normalizado ('boleta')
    TipoDocumento        nvarchar(50)  NOT NULL,       -- 'Boleta'
    TipoVenta            nvarchar(50)  NOT NULL,       -- 'Persona natural' / 'Empresa'
    CONSTRAINT PK_DimTipoDocumento PRIMARY KEY CLUSTERED (TipoDocumentoKey)
);
CREATE UNIQUE INDEX UX_DimTipoDocumento_Codigo ON dbo.DimTipoDocumento (TipoDocumentoCodigo);
GO

/* ---------------------------------------------------------------------
   TABLA DE HECHOS: FactVentas
   Grano: 1 fila = 1 producto en 1 venta (detalle_ventas)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.FactVentas (
    FactVentaKey         bigint IDENTITY(1,1) NOT NULL,
    TiempoKey            int           NOT NULL,
    ClienteKey           int           NOT NULL,
    EmpleadoKey          int           NOT NULL,
    ProductoKey          int           NOT NULL,
    SucursalKey          int           NOT NULL,
    TipoDocumentoKey     int           NOT NULL,
    -- dimensiones degeneradas
    VentaID              int           NOT NULL,
    NumeroDocumento      int           NOT NULL,
    ProductoID           int           NOT NULL,
    -- medidas
    Cantidad             int           NOT NULL,       -- aditiva
    PrecioUnitario       decimal(18,2) NOT NULL,       -- no aditiva
    PrecioLista          decimal(18,2) NOT NULL,       -- no aditiva
    PorcentajeDescuento  decimal(9,4)  NOT NULL,       -- no aditiva (fracción 0-1)
    MontoBruto           decimal(18,2) NOT NULL,       -- Cantidad * PrecioUnitario
    MontoDescuento       decimal(18,2) NOT NULL,       -- MontoBruto * PorcentajeDescuento
    MontoTotal           decimal(18,2) NOT NULL,       -- MontoBruto - MontoDescuento (IVA incluido)
    MontoNeto            decimal(18,2) NOT NULL,       -- MontoTotal / 1.19 (sin IVA)
    MontoIVA             decimal(18,2) NOT NULL,       -- MontoTotal - MontoNeto
    FechaCarga           datetime      NOT NULL CONSTRAINT DF_FactVentas_FechaCarga DEFAULT (GETDATE()),
    CONSTRAINT PK_FactVentas PRIMARY KEY CLUSTERED (FactVentaKey),
    CONSTRAINT UQ_FactVentas_Grano UNIQUE (VentaID, ProductoID),
    CONSTRAINT FK_FactVentas_DimTiempo        FOREIGN KEY (TiempoKey)        REFERENCES dbo.DimTiempo (TiempoKey),
    CONSTRAINT FK_FactVentas_DimCliente       FOREIGN KEY (ClienteKey)       REFERENCES dbo.DimCliente (ClienteKey),
    CONSTRAINT FK_FactVentas_DimEmpleado      FOREIGN KEY (EmpleadoKey)      REFERENCES dbo.DimEmpleado (EmpleadoKey),
    CONSTRAINT FK_FactVentas_DimProducto      FOREIGN KEY (ProductoKey)      REFERENCES dbo.DimProducto (ProductoKey),
    CONSTRAINT FK_FactVentas_DimSucursal      FOREIGN KEY (SucursalKey)      REFERENCES dbo.DimSucursal (SucursalKey),
    CONSTRAINT FK_FactVentas_DimTipoDocumento FOREIGN KEY (TipoDocumentoKey) REFERENCES dbo.DimTipoDocumento (TipoDocumentoKey),
    CONSTRAINT CK_FactVentas_Cantidad CHECK (Cantidad > 0)
);
GO
CREATE INDEX IX_FactVentas_TiempoKey        ON dbo.FactVentas (TiempoKey);
CREATE INDEX IX_FactVentas_ClienteKey       ON dbo.FactVentas (ClienteKey);
CREATE INDEX IX_FactVentas_EmpleadoKey      ON dbo.FactVentas (EmpleadoKey);
CREATE INDEX IX_FactVentas_ProductoKey      ON dbo.FactVentas (ProductoKey);
CREATE INDEX IX_FactVentas_SucursalKey      ON dbo.FactVentas (SucursalKey);
CREATE INDEX IX_FactVentas_TipoDocumentoKey ON dbo.FactVentas (TipoDocumentoKey);
GO

/* ---------------------------------------------------------------------
   TABLAS DE SOPORTE DEL ETL (calidad de datos y auditoría)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.FactVentas_Rechazos (
    RechazoID        int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    VentaID          int           NULL,
    ProductoID       int           NULL,
    Fecha            date          NULL,
    Cantidad         int           NULL,
    PrecioUnitario   decimal(18,2) NULL,
    FechaRechazo     datetime      NOT NULL DEFAULT (GETDATE())
);
GO
CREATE TABLE dbo.EtlLog (
    EjecucionID      int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Paquete          nvarchar(100) NOT NULL,
    FechaInicio      datetime      NOT NULL,
    FechaFin         datetime      NOT NULL,
    FilasLeidas      int           NOT NULL,
    FilasCargadas    int           NOT NULL,
    FilasRechazadas  int           NOT NULL,
    Estado           nvarchar(20)  NOT NULL
);
GO

/* ---------------------------------------------------------------------
   PROCEDIMIENTO: usp_PrepararCarga
   Vacía el modelo (carga completa), reinicia identidades e inserta los
   miembros "Desconocido" (-1) usados cuando un Lookup no encuentra clave.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_PrepararCarga
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE dbo.FactVentas;            -- reinicia IDENTITY (ninguna tabla la referencia)
    TRUNCATE TABLE dbo.FactVentas_Rechazos;
    DELETE FROM dbo.DimCliente;
    DELETE FROM dbo.DimEmpleado;
    DELETE FROM dbo.DimProducto;
    DELETE FROM dbo.DimSucursal;
    DELETE FROM dbo.DimTipoDocumento;
    DELETE FROM dbo.DimTiempo;

    -- Miembros desconocidos (clave -1)
    INSERT INTO dbo.DimTiempo VALUES
        (-1, '19000101', 1900, 0, N'Desconocido', 0, N'Desconocido', 0, N'Desconocido', '0000-00', 0, 0, 0, N'Desconocido', 0, N'Desconocido');

    SET IDENTITY_INSERT dbo.DimCliente ON;
    INSERT INTO dbo.DimCliente (ClienteKey, ClienteID, Nombre, ApellidoPaterno, ApellidoMaterno, NombreCompleto, Sexo, FechaNacimiento, Edad, RangoEtario, EstadoCivil)
    VALUES (-1, -1, N'Desconocido', N'', N'', N'Desconocido', N'No informado', NULL, NULL, N'No informado', N'No informado');
    SET IDENTITY_INSERT dbo.DimCliente OFF;

    SET IDENTITY_INSERT dbo.DimEmpleado ON;
    INSERT INTO dbo.DimEmpleado (EmpleadoKey, EmpleadoID, Nombre, ApellidoPaterno, ApellidoMaterno, NombreCompleto, CargoID, Cargo, FechaContrato, AniosAntiguedad, SueldoBase)
    VALUES (-1, -1, N'Desconocido', N'', N'', N'Desconocido', -1, N'Desconocido', NULL, NULL, 0);
    SET IDENTITY_INSERT dbo.DimEmpleado OFF;

    SET IDENTITY_INSERT dbo.DimProducto ON;
    INSERT INTO dbo.DimProducto (ProductoKey, ProductoID, NombreProducto, Descripcion, CategoriaID, Categoria, PrecioLista, RangoPrecio)
    VALUES (-1, -1, N'Desconocido', N'Sin descripción', -1, N'Desconocida', 0, N'No informado');
    SET IDENTITY_INSERT dbo.DimProducto OFF;

    SET IDENTITY_INSERT dbo.DimSucursal ON;
    INSERT INTO dbo.DimSucursal (SucursalKey, SucursalID, NombreSucursal, ComunaID, Comuna, Region)
    VALUES (-1, -1, N'Desconocida', -1, N'Desconocida', N'Desconocida');
    SET IDENTITY_INSERT dbo.DimSucursal OFF;

    SET IDENTITY_INSERT dbo.DimTipoDocumento ON;
    INSERT INTO dbo.DimTipoDocumento (TipoDocumentoKey, TipoDocumentoCodigo, TipoDocumento, TipoVenta)
    VALUES (-1, N'desconocido', N'Desconocido', N'Desconocido');
    SET IDENTITY_INSERT dbo.DimTipoDocumento OFF;

    -- Reinicia las identidades: la próxima clave generada será 1
    -- (se hace después de insertar el -1 para que el comportamiento sea igual
    --  en la primera ejecución y en las siguientes)
    DBCC CHECKIDENT ('dbo.DimCliente',       RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.DimEmpleado',      RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.DimProducto',      RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.DimSucursal',      RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.DimTipoDocumento', RESEED, 0) WITH NO_INFOMSGS;
END
GO

/* ---------------------------------------------------------------------
   PROCEDIMIENTO: usp_CargarDimTiempo
   Genera un día por fila entre @FechaInicio y @FechaFin.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_CargarDimTiempo
    @FechaInicio date,
    @FechaFin    date
AS
BEGIN
    SET NOCOUNT ON;
    SET DATEFIRST 1;   -- lunes = 1

    DELETE FROM dbo.DimTiempo
    WHERE TiempoKey <> -1 AND Fecha BETWEEN @FechaInicio AND @FechaFin;

    ;WITH Numeros AS (
        SELECT TOP (DATEDIFF(DAY, @FechaInicio, @FechaFin) + 1)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
        FROM sys.all_objects a CROSS JOIN sys.all_objects b
    ), Fechas AS (
        SELECT DATEADD(DAY, n, @FechaInicio) AS Fecha FROM Numeros
    )
    INSERT INTO dbo.DimTiempo
        (TiempoKey, Fecha, Anio, Semestre, NombreSemestre, Trimestre, NombreTrimestre,
         Mes, NombreMes, AnioMes, SemanaAnio, DiaMes, DiaSemana, NombreDia, EsFinDeSemana, Estacion)
    SELECT
        CONVERT(int, CONVERT(char(8), Fecha, 112)),
        Fecha,
        YEAR(Fecha),
        CASE WHEN MONTH(Fecha) <= 6 THEN 1 ELSE 2 END,
        CASE WHEN MONTH(Fecha) <= 6 THEN N'1er Semestre' ELSE N'2do Semestre' END,
        DATEPART(QUARTER, Fecha),
        N'T' + CAST(DATEPART(QUARTER, Fecha) AS nvarchar(1)),
        MONTH(Fecha),
        CHOOSE(MONTH(Fecha), N'Enero', N'Febrero', N'Marzo', N'Abril', N'Mayo', N'Junio',
                             N'Julio', N'Agosto', N'Septiembre', N'Octubre', N'Noviembre', N'Diciembre'),
        CONVERT(char(7), Fecha, 126),
        DATEPART(ISO_WEEK, Fecha),
        DAY(Fecha),
        DATEPART(WEEKDAY, Fecha),
        CHOOSE(DATEPART(WEEKDAY, Fecha), N'Lunes', N'Martes', N'Miércoles', N'Jueves', N'Viernes', N'Sábado', N'Domingo'),
        CASE WHEN DATEPART(WEEKDAY, Fecha) IN (6, 7) THEN 1 ELSE 0 END,
        -- Estaciones hemisferio sur (aprox. 21 de cada mes de cambio)
        CASE
            WHEN (MONTH(Fecha) = 12 AND DAY(Fecha) >= 21) OR MONTH(Fecha) IN (1, 2) OR (MONTH(Fecha) = 3 AND DAY(Fecha) < 21) THEN N'Verano'
            WHEN (MONTH(Fecha) = 3 AND DAY(Fecha) >= 21) OR MONTH(Fecha) IN (4, 5) OR (MONTH(Fecha) = 6 AND DAY(Fecha) < 21) THEN N'Otoño'
            WHEN (MONTH(Fecha) = 6 AND DAY(Fecha) >= 21) OR MONTH(Fecha) IN (7, 8) OR (MONTH(Fecha) = 9 AND DAY(Fecha) < 21) THEN N'Invierno'
            ELSE N'Primavera'
        END
    FROM Fechas;
END
GO

PRINT 'Modelo dimensional Albarran_DW creado correctamente.';
GO
