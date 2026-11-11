# =====================================================================
# Script de Creación, Despliegue y Procesamiento del Cubo OLAP (SSAS)
# Mueblería Albarrán - Inteligencia de Negocios
# =====================================================================
param(
    [string]$ServerName = "localhost",
    [string]$DatabaseName = "OLAP_Albarran",
    [string]$DwDatabase = "Albarran_DW"
)

Write-Host "Iniciando despliegue de SSAS en $ServerName..." -ForegroundColor Cyan

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices") | Out-Null
$server = New-Object Microsoft.AnalysisServices.Server
$server.Connect($ServerName)

if (-not $server.Connected) {
    throw "No se pudo conectar a la instancia de SSAS en $ServerName"
}

Write-Host "Conectado a SSAS $($server.Name) (Modo: $($server.ServerMode))" -ForegroundColor Green

# 1. Eliminar base si ya existe para recrearla limpia
if ($server.Databases.Contains($DatabaseName)) {
    Write-Host "Eliminando base de datos previa $DatabaseName..." -ForegroundColor Yellow
    $server.Databases[$DatabaseName].Drop()
}

$db = New-Object Microsoft.AnalysisServices.Database($DatabaseName, $DatabaseName)
$server.Databases.Add($db)
$db.Update()
Write-Host "Base de datos SSAS $DatabaseName creada." -ForegroundColor Green

# 2. Data Source
$ds = New-Object Microsoft.AnalysisServices.RelationalDataSource("Albarran_DW", "Albarran_DW")
$ds.ConnectionString = "Provider=SQLNCLI11.1;Data Source=$ServerName;Integrated Security=SSPI;Initial Catalog=$DwDatabase;"
$ds.ImpersonationInfo = New-Object Microsoft.AnalysisServices.ImpersonationInfo([Microsoft.AnalysisServices.ImpersonationMode]::ImpersonateServiceAccount)
$db.DataSources.Add($ds)
$ds.Update()
Write-Host "Data Source Albarran_DW creado." -ForegroundColor Green

# 3. Data Source View (DSV)
$dsv = New-Object Microsoft.AnalysisServices.DataSourceView("Albarran_DW", "Albarran_DW")
$dsv.DataSourceID = "Albarran_DW"

$schemaXml = @"
<xs:schema id="Albarran_DW" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata" xmlns:msprop="urn:schemas-microsoft-com:xml-msprop">
  <xs:element name="Albarran_DW" msdata:IsDataSet="true" msdata:UseCurrentLocale="true">
    <xs:complexType>
      <xs:choice minOccurs="0" maxOccurs="unbounded">
        <xs:element name="dbo_DimTiempo" msprop:DbTableName="DimTiempo" msprop:TableType="Table">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="TiempoKey" type="xs:int" />
              <xs:element name="Fecha" type="xs:dateTime" />
              <xs:element name="Anio" type="xs:short" />
              <xs:element name="Semestre" type="xs:unsignedByte" />
              <xs:element name="NombreSemestre" type="xs:string" />
              <xs:element name="Trimestre" type="xs:unsignedByte" />
              <xs:element name="NombreTrimestre" type="xs:string" />
              <xs:element name="Mes" type="xs:unsignedByte" />
              <xs:element name="NombreMes" type="xs:string" />
              <xs:element name="AnioMes" type="xs:string" />
              <xs:element name="SemanaAnio" type="xs:unsignedByte" />
              <xs:element name="DiaMes" type="xs:unsignedByte" />
              <xs:element name="DiaSemana" type="xs:unsignedByte" />
              <xs:element name="NombreDia" type="xs:string" />
              <xs:element name="EsFinDeSemana" type="xs:boolean" />
              <xs:element name="Estacion" type="xs:string" />
            </xs:sequence>
          </xs:complexType>
        </xs:element>
        <xs:element name="dbo_DimCliente" msprop:DbTableName="DimCliente" msprop:TableType="Table">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="ClienteKey" type="xs:int" />
              <xs:element name="ClienteID" type="xs:int" />
              <xs:element name="Nombre" type="xs:string" />
              <xs:element name="ApellidoPaterno" type="xs:string" />
              <xs:element name="ApellidoMaterno" type="xs:string" />
              <xs:element name="NombreCompleto" type="xs:string" />
              <xs:element name="Sexo" type="xs:string" />
              <xs:element name="FechaNacimiento" type="xs:dateTime" minOccurs="0" />
              <xs:element name="Edad" type="xs:int" minOccurs="0" />
              <xs:element name="RangoEtario" type="xs:string" />
              <xs:element name="EstadoCivil" type="xs:string" />
            </xs:sequence>
          </xs:complexType>
        </xs:element>
        <xs:element name="dbo_DimEmpleado" msprop:DbTableName="DimEmpleado" msprop:TableType="Table">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="EmpleadoKey" type="xs:int" />
              <xs:element name="EmpleadoID" type="xs:int" />
              <xs:element name="Nombre" type="xs:string" />
              <xs:element name="ApellidoPaterno" type="xs:string" />
              <xs:element name="ApellidoMaterno" type="xs:string" />
              <xs:element name="NombreCompleto" type="xs:string" />
              <xs:element name="CargoID" type="xs:int" />
              <xs:element name="Cargo" type="xs:string" />
              <xs:element name="FechaContrato" type="xs:dateTime" minOccurs="0" />
              <xs:element name="AniosAntiguedad" type="xs:int" minOccurs="0" />
              <xs:element name="SueldoBase" type="xs:decimal" />
              <xs:element name="SueldoBaseAnual" type="xs:decimal" minOccurs="0" />
            </xs:sequence>
          </xs:complexType>
        </xs:element>
        <xs:element name="dbo_DimProducto" msprop:DbTableName="DimProducto" msprop:TableType="Table">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="ProductoKey" type="xs:int" />
              <xs:element name="ProductoID" type="xs:int" />
              <xs:element name="NombreProducto" type="xs:string" />
              <xs:element name="Descripcion" type="xs:string" />
              <xs:element name="CategoriaID" type="xs:int" />
              <xs:element name="Categoria" type="xs:string" />
              <xs:element name="PrecioLista" type="xs:decimal" />
              <xs:element name="RangoPrecio" type="xs:string" />
            </xs:sequence>
          </xs:complexType>
        </xs:element>
        <xs:element name="dbo_DimSucursal" msprop:DbTableName="DimSucursal" msprop:TableType="Table">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="SucursalKey" type="xs:int" />
              <xs:element name="SucursalID" type="xs:int" />
              <xs:element name="NombreSucursal" type="xs:string" />
              <xs:element name="ComunaID" type="xs:int" />
              <xs:element name="Comuna" type="xs:string" />
              <xs:element name="Region" type="xs:string" />
            </xs:sequence>
          </xs:complexType>
        </xs:element>
        <xs:element name="dbo_DimTipoDocumento" msprop:DbTableName="DimTipoDocumento" msprop:TableType="Table">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="TipoDocumentoKey" type="xs:int" />
              <xs:element name="TipoDocumentoCodigo" type="xs:string" />
              <xs:element name="TipoDocumento" type="xs:string" />
              <xs:element name="TipoVenta" type="xs:string" />
            </xs:sequence>
          </xs:complexType>
        </xs:element>
        <xs:element name="dbo_FactVentas" msprop:DbTableName="FactVentas" msprop:TableType="Table">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="FactVentaKey" type="xs:long" />
              <xs:element name="TiempoKey" type="xs:int" />
              <xs:element name="ClienteKey" type="xs:int" />
              <xs:element name="EmpleadoKey" type="xs:int" />
              <xs:element name="ProductoKey" type="xs:int" />
              <xs:element name="SucursalKey" type="xs:int" />
              <xs:element name="TipoDocumentoKey" type="xs:int" />
              <xs:element name="VentaID" type="xs:int" />
              <xs:element name="NumeroDocumento" type="xs:int" />
              <xs:element name="ProductoID" type="xs:int" />
              <xs:element name="Cantidad" type="xs:int" />
              <xs:element name="PrecioUnitario" type="xs:decimal" />
              <xs:element name="PrecioLista" type="xs:decimal" />
              <xs:element name="PorcentajeDescuento" type="xs:decimal" />
              <xs:element name="MontoBruto" type="xs:decimal" />
              <xs:element name="MontoDescuento" type="xs:decimal" />
              <xs:element name="MontoTotal" type="xs:decimal" />
              <xs:element name="MontoNeto" type="xs:decimal" />
              <xs:element name="MontoIVA" type="xs:decimal" />
              <xs:element name="FechaCarga" type="xs:dateTime" />
            </xs:sequence>
          </xs:complexType>
        </xs:element>
      </xs:choice>
    </xs:complexType>
    <xs:unique name="PK_DimTiempo" msdata:PrimaryKey="true">
      <xs:selector xpath=".//dbo_DimTiempo" />
      <xs:field xpath="TiempoKey" />
    </xs:unique>
    <xs:unique name="PK_DimCliente" msdata:PrimaryKey="true">
      <xs:selector xpath=".//dbo_DimCliente" />
      <xs:field xpath="ClienteKey" />
    </xs:unique>
    <xs:unique name="PK_DimEmpleado" msdata:PrimaryKey="true">
      <xs:selector xpath=".//dbo_DimEmpleado" />
      <xs:field xpath="EmpleadoKey" />
    </xs:unique>
    <xs:unique name="PK_DimProducto" msdata:PrimaryKey="true">
      <xs:selector xpath=".//dbo_DimProducto" />
      <xs:field xpath="ProductoKey" />
    </xs:unique>
    <xs:unique name="PK_DimSucursal" msdata:PrimaryKey="true">
      <xs:selector xpath=".//dbo_DimSucursal" />
      <xs:field xpath="SucursalKey" />
    </xs:unique>
    <xs:unique name="PK_DimTipoDocumento" msdata:PrimaryKey="true">
      <xs:selector xpath=".//dbo_DimTipoDocumento" />
      <xs:field xpath="TipoDocumentoKey" />
    </xs:unique>
    <xs:unique name="PK_FactVentas" msdata:PrimaryKey="true">
      <xs:selector xpath=".//dbo_FactVentas" />
      <xs:field xpath="FactVentaKey" />
    </xs:unique>
    <xs:keyref name="FK_FactVentas_DimTiempo" refer="PK_DimTiempo">
      <xs:selector xpath=".//dbo_FactVentas" />
      <xs:field xpath="TiempoKey" />
    </xs:keyref>
    <xs:keyref name="FK_FactVentas_DimCliente" refer="PK_DimCliente">
      <xs:selector xpath=".//dbo_FactVentas" />
      <xs:field xpath="ClienteKey" />
    </xs:keyref>
    <xs:keyref name="FK_FactVentas_DimEmpleado" refer="PK_DimEmpleado">
      <xs:selector xpath=".//dbo_FactVentas" />
      <xs:field xpath="EmpleadoKey" />
    </xs:keyref>
    <xs:keyref name="FK_FactVentas_DimProducto" refer="PK_DimProducto">
      <xs:selector xpath=".//dbo_FactVentas" />
      <xs:field xpath="ProductoKey" />
    </xs:keyref>
    <xs:keyref name="FK_FactVentas_DimSucursal" refer="PK_DimSucursal">
      <xs:selector xpath=".//dbo_FactVentas" />
      <xs:field xpath="SucursalKey" />
    </xs:keyref>
    <xs:keyref name="FK_FactVentas_DimTipoDocumento" refer="PK_DimTipoDocumento">
      <xs:selector xpath=".//dbo_FactVentas" />
      <xs:field xpath="TipoDocumentoKey" />
    </xs:keyref>
  </xs:element>
</xs:schema>
"@

$dataSet = New-Object System.Data.DataSet
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($schemaXml))
$dataSet.ReadXmlSchema($reader)
$dsv.Schema = $dataSet
$db.DataSourceViews.Add($dsv)
$dsv.Update()
Write-Host "Data Source View Albarran_DW creado." -ForegroundColor Green

# 4. Función de creación de dimensiones
function Add-Dimension($db, [string]$dimName, [string]$tableName, [string]$keyCol, [string]$nameCol, [hashtable]$attribs, [hashtable]$hierarchies) {
    $dim = New-Object Microsoft.AnalysisServices.Dimension($dimName, $dimName)
    $dim.Source = New-Object Microsoft.AnalysisServices.DataSourceViewBinding("Albarran_DW")

    # Clave primaria
    $keyAttr = $dim.Attributes.Add($dimName, $dimName)
    $keyAttr.Usage = [Microsoft.AnalysisServices.AttributeUsage]::Key
    $keyItem = New-Object Microsoft.AnalysisServices.DataItem($tableName, $keyCol, [System.Data.OleDb.OleDbType]::Integer)
    $keyAttr.KeyColumns.Add($keyItem)
    if ($nameCol -and $nameCol -ne $keyCol) {
        $nameItem = New-Object Microsoft.AnalysisServices.DataItem($tableName, $nameCol, [System.Data.OleDb.OleDbType]::WChar, 255)
        $keyAttr.NameColumn = $nameItem
    }

    # Atributos adicionales
    foreach ($attrName in $attribs.Keys) {
        $colName = $attribs[$attrName]
        $attr = $dim.Attributes.Add($attrName, $attrName)
        $attrItem = New-Object Microsoft.AnalysisServices.DataItem($tableName, $colName)
        $attr.KeyColumns.Add($attrItem)
    }

    # Jerarquías
    if ($hierarchies) {
        foreach ($hName in $hierarchies.Keys) {
            $h = $dim.Hierarchies.Add($hName, $hName)
            $levels = $hierarchies[$hName]
            foreach ($lvl in $levels) {
                $level = $h.Levels.Add($lvl)
                $level.SourceAttributeID = $lvl
            }
        }
    }

    $db.Dimensions.Add($dim)
    $dim.Update()
    Write-Host "Dimensión $dimName creada." -ForegroundColor Green
    return $dim
}

# DimTiempo
$dimTiempo = New-Object Microsoft.AnalysisServices.Dimension("Dim Tiempo", "Dim Tiempo")
$dimTiempo.Source = New-Object Microsoft.AnalysisServices.DataSourceViewBinding("Albarran_DW")

$keyAttr = $dimTiempo.Attributes.Add("Dim Tiempo", "Dim Tiempo")
$keyAttr.Usage = [Microsoft.AnalysisServices.AttributeUsage]::Key
$keyAttr.KeyColumns.Add((New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "TiempoKey", [System.Data.OleDb.OleDbType]::Integer)))
$keyAttr.NameColumn = New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "Fecha", [System.Data.OleDb.OleDbType]::WChar, 10)

# Atributos con orden cronológico
$attrAnio = $dimTiempo.Attributes.Add("Año", "Año")
$attrAnio.KeyColumns.Add((New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "Anio", [System.Data.OleDb.OleDbType]::SmallInt)))

$attrSem = $dimTiempo.Attributes.Add("Semestre", "Semestre")
$attrSem.KeyColumns.Add((New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "Semestre", [System.Data.OleDb.OleDbType]::UnsignedTinyInt)))
$attrSem.NameColumn = New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "NombreSemestre", [System.Data.OleDb.OleDbType]::WChar, 20)
$attrSem.OrderBy = [Microsoft.AnalysisServices.OrderBy]::Key

$attrTrim = $dimTiempo.Attributes.Add("Trimestre", "Trimestre")
$attrTrim.KeyColumns.Add((New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "Trimestre", [System.Data.OleDb.OleDbType]::UnsignedTinyInt)))
$attrTrim.NameColumn = New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "NombreTrimestre", [System.Data.OleDb.OleDbType]::WChar, 20)
$attrTrim.OrderBy = [Microsoft.AnalysisServices.OrderBy]::Key

$attrMes = $dimTiempo.Attributes.Add("Mes", "Mes")
$attrMes.KeyColumns.Add((New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "Mes", [System.Data.OleDb.OleDbType]::UnsignedTinyInt)))
$attrMes.NameColumn = New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "NombreMes", [System.Data.OleDb.OleDbType]::WChar, 20)
$attrMes.OrderBy = [Microsoft.AnalysisServices.OrderBy]::Key

$attrAnioMes = $dimTiempo.Attributes.Add("Año Mes", "Año Mes")
$attrAnioMes.KeyColumns.Add((New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "AnioMes", [System.Data.OleDb.OleDbType]::WChar, 7)))

$attrDiaSem = $dimTiempo.Attributes.Add("Día de Semana", "Día de Semana")
$attrDiaSem.KeyColumns.Add((New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "DiaSemana", [System.Data.OleDb.OleDbType]::UnsignedTinyInt)))
$attrDiaSem.NameColumn = New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "NombreDia", [System.Data.OleDb.OleDbType]::WChar, 20)
$attrDiaSem.OrderBy = [Microsoft.AnalysisServices.OrderBy]::Key

$attrEstacion = $dimTiempo.Attributes.Add("Estación", "Estación")
$attrEstacion.KeyColumns.Add((New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "Estacion", [System.Data.OleDb.OleDbType]::WChar, 20)))

$attrFinSem = $dimTiempo.Attributes.Add("Es Fin de Semana", "Es Fin de Semana")
$attrFinSem.KeyColumns.Add((New-Object Microsoft.AnalysisServices.DataItem("dbo_DimTiempo", "EsFinDeSemana", [System.Data.OleDb.OleDbType]::Boolean)))

# Jerarquía Calendario
$hCal = $dimTiempo.Hierarchies.Add("Calendario", "Calendario")
$hCal.Levels.Add("Año").SourceAttributeID = "Año"
$hCal.Levels.Add("Semestre").SourceAttributeID = "Semestre"
$hCal.Levels.Add("Trimestre").SourceAttributeID = "Trimestre"
$hCal.Levels.Add("Mes").SourceAttributeID = "Mes"
$hCal.Levels.Add("Fecha").SourceAttributeID = "Dim Tiempo"

# Jerarquía Estacional
$hEst = $dimTiempo.Hierarchies.Add("Estacional", "Estacional")
$hEst.Levels.Add("Año").SourceAttributeID = "Año"
$hEst.Levels.Add("Estación").SourceAttributeID = "Estación"
$hEst.Levels.Add("Mes").SourceAttributeID = "Mes"

$db.Dimensions.Add($dimTiempo)
$dimTiempo.Update()
Write-Host "Dimensión Dim Tiempo creada con orden cronológico." -ForegroundColor Green

# DimSucursal
$sucursalAttrs = @{
    "Región" = "Region"
    "Comuna" = "Comuna"
}
$sucursalHierarchies = @{
    "Geografía" = @("Región", "Comuna", "Dim Sucursal")
}
$dimSucursal = Add-Dimension $db "Dim Sucursal" "dbo_DimSucursal" "SucursalKey" "NombreSucursal" $sucursalAttrs $sucursalHierarchies

# DimProducto
$productoAttrs = @{
    "Categoría" = "Categoria"
    "Rango de Precio" = "RangoPrecio"
    "Descripción" = "Descripcion"
}
$productoHierarchies = @{
    "Catálogo de Productos" = @("Categoría", "Rango de Precio", "Dim Producto")
}
$dimProducto = Add-Dimension $db "Dim Producto" "dbo_DimProducto" "ProductoKey" "NombreProducto" $productoAttrs $productoHierarchies

# DimCliente
$clienteAttrs = @{
    "Sexo" = "Sexo"
    "Rango Etario" = "RangoEtario"
    "Estado Civil" = "EstadoCivil"
}
$clienteHierarchies = @{
    "Segmento Demográfico" = @("Sexo", "Rango Etario", "Estado Civil", "Dim Cliente")
}
$dimCliente = Add-Dimension $db "Dim Cliente" "dbo_DimCliente" "ClienteKey" "NombreCompleto" $clienteAttrs $clienteHierarchies

# DimEmpleado
$empleadoAttrs = @{
    "Cargo" = "Cargo"
    "Sueldo Base" = "SueldoBase"
    "Sueldo Base Anual" = "SueldoBaseAnual"
}
$empleadoHierarchies = @{
    "Dotación Comercial" = @("Cargo", "Dim Empleado")
}
$dimEmpleado = Add-Dimension $db "Dim Empleado" "dbo_DimEmpleado" "EmpleadoKey" "NombreCompleto" $empleadoAttrs $empleadoHierarchies

# DimTipoDocumento
$tipoDocAttrs = @{
    "Tipo de Venta" = "TipoVenta"
}
$tipoDocHierarchies = @{
    "Canal de Venta" = @("Tipo de Venta", "Dim Tipo Documento")
}
$dimTipoDoc = Add-Dimension $db "Dim Tipo Documento" "dbo_DimTipoDocumento" "TipoDocumentoKey" "TipoDocumento" $tipoDocAttrs $tipoDocHierarchies

# 5. Cubo
$cube = $db.Cubes.Add("Cubo_Albarran", "Cubo_Albarran")
$cube.Source = New-Object Microsoft.AnalysisServices.DataSourceViewBinding("Albarran_DW")

# Dimensiones del cubo
foreach ($d in @($dimTiempo, $dimSucursal, $dimProducto, $dimCliente, $dimEmpleado, $dimTipoDoc)) {
    $cubeDim = $cube.Dimensions.Add($d.ID)
}

# Grupo de Medidas: Fact Ventas
$mg = $cube.MeasureGroups.Add("Fact Ventas", "Fact Ventas")
$mg.StorageMode = [Microsoft.AnalysisServices.StorageMode]::Molap

# Medidas Físicas
function Add-Measure($mg, [string]$name, [string]$colName, [string]$aggType, [string]$format, $dataType) {
    $m = $mg.Measures.Add($name, $name)
    $dataItem = New-Object Microsoft.AnalysisServices.DataItem("dbo_FactVentas", $colName, $dataType)
    $m.Source = $dataItem
    $m.AggregateFunction = [Microsoft.AnalysisServices.AggregationFunction]::$aggType
    $m.FormatString = $format
}

Add-Measure $mg "Cantidad" "Cantidad" "Sum" "#,##0" ([System.Data.OleDb.OleDbType]::Integer)
Add-Measure $mg "Monto Bruto" "MontoBruto" "Sum" "Currency" ([System.Data.OleDb.OleDbType]::Currency)
Add-Measure $mg "Monto Descuento" "MontoDescuento" "Sum" "Currency" ([System.Data.OleDb.OleDbType]::Currency)
Add-Measure $mg "Monto Total" "MontoTotal" "Sum" "Currency" ([System.Data.OleDb.OleDbType]::Currency)
Add-Measure $mg "Monto Neto" "MontoNeto" "Sum" "Currency" ([System.Data.OleDb.OleDbType]::Currency)
Add-Measure $mg "Monto IVA" "MontoIVA" "Sum" "Currency" ([System.Data.OleDb.OleDbType]::Currency)
Add-Measure $mg "Recuento Fact Ventas" "FactVentaKey" "Count" "#,##0" ([System.Data.OleDb.OleDbType]::BigInt)

# Grupo de Medidas Distinct Count 1: Numero de Ventas
$mgNumVentas = $cube.MeasureGroups.Add("Ventas Distintas", "Ventas Distintas")
$mgNumVentas.StorageMode = [Microsoft.AnalysisServices.StorageMode]::Molap

$mNumVentas = $mgNumVentas.Measures.Add("Numero de Ventas", "Numero de Ventas")
$mNumVentas.Source = New-Object Microsoft.AnalysisServices.DataItem("dbo_FactVentas", "VentaID", [System.Data.OleDb.OleDbType]::Integer)
$mNumVentas.AggregateFunction = [Microsoft.AnalysisServices.AggregationFunction]::DistinctCount
$mNumVentas.FormatString = "#,##0"

# Grupo de Medidas Distinct Count 2: Clientes Activos
$mgClientesActivos = $cube.MeasureGroups.Add("Clientes Activos", "Clientes Activos")
$mgClientesActivos.StorageMode = [Microsoft.AnalysisServices.StorageMode]::Molap

$mClientesActivos = $mgClientesActivos.Measures.Add("Clientes Activos", "Clientes Activos")
$mClientesActivos.Source = New-Object Microsoft.AnalysisServices.DataItem("dbo_FactVentas", "ClienteKey", [System.Data.OleDb.OleDbType]::Integer)
$mClientesActivos.AggregateFunction = [Microsoft.AnalysisServices.AggregationFunction]::DistinctCount
$mClientesActivos.FormatString = "#,##0"

# Enlazar dimensiones a los grupos de medidas
function Link-Dimension($measureGroup, [string]$cubeDimId, [string]$dimKeyAttrId, [string]$fkCol) {
    $mgDim = New-Object Microsoft.AnalysisServices.RegularMeasureGroupDimension($cubeDimId)
    $attr = $mgDim.Attributes.Add($dimKeyAttrId)
    $attr.Type = [Microsoft.AnalysisServices.MeasureGroupAttributeType]::Granularity
    $col = New-Object Microsoft.AnalysisServices.DataItem("dbo_FactVentas", $fkCol, [System.Data.OleDb.OleDbType]::Integer)
    $attr.KeyColumns.Add($col)
    $measureGroup.Dimensions.Add($mgDim)
}

foreach ($group in @($mg, $mgNumVentas, $mgClientesActivos)) {
    Link-Dimension $group "Dim Tiempo" "Dim Tiempo" "TiempoKey"
    Link-Dimension $group "Dim Sucursal" "Dim Sucursal" "SucursalKey"
    Link-Dimension $group "Dim Producto" "Dim Producto" "ProductoKey"
    Link-Dimension $group "Dim Cliente" "Dim Cliente" "ClienteKey"
    Link-Dimension $group "Dim Empleado" "Dim Empleado" "EmpleadoKey"
    Link-Dimension $group "Dim Tipo Documento" "Dim Tipo Documento" "TipoDocumentoKey"
}

# Particiones
$part = $mg.Partitions.Add("Fact Ventas", "Fact Ventas")
$part.Source = New-Object Microsoft.AnalysisServices.DsvTableBinding("Albarran_DW", "dbo_FactVentas")
$part.StorageMode = [Microsoft.AnalysisServices.StorageMode]::Molap

$partVentas = $mgNumVentas.Partitions.Add("Ventas Distintas", "Ventas Distintas")
$partVentas.Source = New-Object Microsoft.AnalysisServices.DsvTableBinding("Albarran_DW", "dbo_FactVentas")
$partVentas.StorageMode = [Microsoft.AnalysisServices.StorageMode]::Molap

$partClientes = $mgClientesActivos.Partitions.Add("Clientes Activos", "Clientes Activos")
$partClientes.Source = New-Object Microsoft.AnalysisServices.DsvTableBinding("Albarran_DW", "dbo_FactVentas")
$partClientes.StorageMode = [Microsoft.AnalysisServices.StorageMode]::Molap

# 6. MDX Script con Cálculos y 10 KPIs
$mdxScript = New-Object Microsoft.AnalysisServices.MdxScript("MdxScript", "MdxScript")

$mdxText = @"
CALCULATE;

/* -------------------------------------------------------------------------
   KPI 1: Crecimiento Mensual de Ventas (%)
   ------------------------------------------------------------------------- */
CREATE MEMBER CURRENTCUBE.[Measures].[Ventas Mes Anterior]
AS ([Measures].[Monto Total], ParallelPeriod([Dim Tiempo].[Calendario].[Mes], 1, [Dim Tiempo].[Calendario].CurrentMember)),
FORMAT_STRING = "Currency",
VISIBLE = 1;

CREATE MEMBER CURRENTCUBE.[Measures].[Crecimiento Mensual Ventas %]
AS IIF(IsEmpty([Measures].[Ventas Mes Anterior]) OR [Measures].[Ventas Mes Anterior] = 0,
       NULL,
       ([Measures].[Monto Total] - [Measures].[Ventas Mes Anterior]) / [Measures].[Ventas Mes Anterior]),
FORMAT_STRING = "Percent",
VISIBLE = 1;

/* -------------------------------------------------------------------------
   KPI 2: Ticket Promedio por Venta
   ------------------------------------------------------------------------- */
CREATE MEMBER CURRENTCUBE.[Measures].[Ticket Promedio]
AS IIF([Measures].[Numero de Ventas] = 0, NULL, [Measures].[Monto Total] / [Measures].[Numero de Ventas]),
FORMAT_STRING = "Currency",
VISIBLE = 1;

/* -------------------------------------------------------------------------
   KPI 3: Participación de Ventas por Sucursal (%)
   ------------------------------------------------------------------------- */
CREATE MEMBER CURRENTCUBE.[Measures].[Participacion Sucursal %]
AS IIF(([Dim Sucursal].[Geografía].[All], [Measures].[Monto Total]) = 0, NULL,
       [Measures].[Monto Total] / ([Dim Sucursal].[Geografía].[All], [Measures].[Monto Total])),
FORMAT_STRING = "Percent",
VISIBLE = 1;

/* -------------------------------------------------------------------------
   KPI 4: Mix de Ventas por Categoría (%)
   ------------------------------------------------------------------------- */
CREATE MEMBER CURRENTCUBE.[Measures].[Participacion Categoria %]
AS IIF(([Dim Producto].[Catálogo de Productos].[All], [Measures].[Monto Total]) = 0, NULL,
       [Measures].[Monto Total] / ([Dim Producto].[Catálogo de Productos].[All], [Measures].[Monto Total])),
FORMAT_STRING = "Percent",
VISIBLE = 1;

/* -------------------------------------------------------------------------
   KPI 5: Ranking de Productos por Ventas
   ------------------------------------------------------------------------- */
CREATE MEMBER CURRENTCUBE.[Measures].[Ranking Producto]
AS IIF(IsEmpty([Measures].[Monto Total]), NULL,
       Rank([Dim Producto].[Dim Producto].CurrentMember,
            Order([Dim Producto].[Dim Producto].[Dim Producto].Members, [Measures].[Monto Total], BDESC))),
FORMAT_STRING = "#,##0",
VISIBLE = 1;

/* -------------------------------------------------------------------------
   KPI 6: Productividad del Vendedor (Ventas / Costo Sueldo Anual)
   ------------------------------------------------------------------------- */
CREATE MEMBER CURRENTCUBE.[Measures].[Costo Sueldo Anual]
AS ([Dim Empleado].[Dim Empleado].CurrentMember.Properties("Sueldo Base Anual", TYPED)),
FORMAT_STRING = "Currency",
VISIBLE = 1;

CREATE MEMBER CURRENTCUBE.[Measures].[Productividad Vendedor]
AS IIF([Measures].[Costo Sueldo Anual] = 0 OR IsEmpty([Measures].[Costo Sueldo Anual]),
       NULL,
       ([Measures].[Monto Total] / [Measures].[Costo Sueldo Anual]) * 100),
FORMAT_STRING = "#,##0.0 \x",
VISIBLE = 1;

/* -------------------------------------------------------------------------
   KPI 7: Porcentaje de Ventas con Factura (Canal B2B Empresa)
   ------------------------------------------------------------------------- */
CREATE MEMBER CURRENTCUBE.[Measures].[Pct Ventas Factura]
AS IIF([Measures].[Numero de Ventas] = 0, NULL,
       ([Dim Tipo Documento].[Tipo de Venta].&[Empresa], [Measures].[Numero de Ventas])
       / ([Dim Tipo Documento].[Tipo de Venta].[All], [Measures].[Numero de Ventas])),
FORMAT_STRING = "Percent",
VISIBLE = 1;

/* -------------------------------------------------------------------------
   KPI 8: Participación por Segmento Demográfico de Cliente (%)
   ------------------------------------------------------------------------- */
CREATE MEMBER CURRENTCUBE.[Measures].[Participacion Segmento Cliente %]
AS IIF(([Dim Cliente].[Segmento Demográfico].[All], [Measures].[Monto Total]) = 0, NULL,
       [Measures].[Monto Total] / ([Dim Cliente].[Segmento Demográfico].[All], [Measures].[Monto Total])),
FORMAT_STRING = "Percent",
VISIBLE = 1;

/* -------------------------------------------------------------------------
   KPI 9: Frecuencia de Compra por Cliente (Transacciones / Cliente Activo)
   ------------------------------------------------------------------------- */
CREATE MEMBER CURRENTCUBE.[Measures].[Frecuencia de Compra]
AS IIF([Measures].[Clientes Activos] = 0, NULL,
       [Measures].[Numero de Ventas] / [Measures].[Clientes Activos]),
FORMAT_STRING = "#,##0.00",
VISIBLE = 1;

/* -------------------------------------------------------------------------
   KPI 10: Descuento Promedio Otorgado (%)
   ------------------------------------------------------------------------- */
CREATE MEMBER CURRENTCUBE.[Measures].[Descuento Promedio %]
AS IIF([Measures].[Monto Bruto] = 0, 0,
       [Measures].[Monto Descuento] / [Measures].[Monto Bruto]),
FORMAT_STRING = "Percent",
VISIBLE = 1;
"@

$mdxCmd = New-Object Microsoft.AnalysisServices.Command($mdxText)
$mdxScript.Commands.Add($mdxCmd)
$cube.MdxScripts.Add($mdxScript)

# 7. Objetos KPI Nativos de SSAS
function Add-CubeKpi($cube, [string]$name, [string]$valExp, [string]$goalExp, [string]$statusExp, [string]$trendExp, [string]$graphic) {
    $k = $cube.Kpis.Add($name, $name)
    $k.Value = $valExp
    $k.Goal = $goalExp
    $k.Status = $statusExp
    $k.Trend = $trendExp
    $k.StatusGraphic = $graphic
    $k.TrendGraphic = "Standard Arrow"
}

Add-CubeKpi $cube "KPI 01 - Crecimiento Mensual" `
    "[Measures].[Crecimiento Mensual Ventas %]" `
    "0.05" `
    "Case When [Measures].[Crecimiento Mensual Ventas %] >= 0.05 Then 1 When [Measures].[Crecimiento Mensual Ventas %] >= 0 Then 0 Else -1 End" `
    "Case When [Measures].[Crecimiento Mensual Ventas %] > ( [Dim Tiempo].[Calendario].PrevMember, [Measures].[Crecimiento Mensual Ventas %] ) Then 1 When [Measures].[Crecimiento Mensual Ventas %] < ( [Dim Tiempo].[Calendario].PrevMember, [Measures].[Crecimiento Mensual Ventas %] ) Then -1 Else 0 End" `
    "Traffic Light"

Add-CubeKpi $cube "KPI 02 - Ticket Promedio" `
    "[Measures].[Ticket Promedio]" `
    "1150000" `
    "Case When [Measures].[Ticket Promedio] >= 1150000 Then 1 When [Measures].[Ticket Promedio] >= 1000000 Then 0 Else -1 End" `
    "Case When [Measures].[Ticket Promedio] > ( [Dim Tiempo].[Calendario].PrevMember, [Measures].[Ticket Promedio] ) Then 1 Else -1 End" `
    "Gauge"

Add-CubeKpi $cube "KPI 03 - Participacion Sucursal" `
    "[Measures].[Participacion Sucursal %]" `
    "0.333" `
    "Case When [Measures].[Participacion Sucursal %] >= 0.333 Then 1 When [Measures].[Participacion Sucursal %] >= 0.300 Then 0 Else -1 End" `
    "0" `
    "Traffic Light"

Add-CubeKpi $cube "KPI 06 - Productividad Vendedor" `
    "[Measures].[Productividad Vendedor]" `
    "20.0" `
    "Case When [Measures].[Productividad Vendedor] >= 20.0 Then 1 When [Measures].[Productividad Vendedor] >= 15.0 Then 0 Else -1 End" `
    "1" `
    "Gauge"

Add-CubeKpi $cube "KPI 07 - Pct Ventas Factura" `
    "[Measures].[Pct Ventas Factura]" `
    "0.20" `
    "Case When [Measures].[Pct Ventas Factura] >= 0.20 Then 1 When [Measures].[Pct Ventas Factura] >= 0.15 Then 0 Else -1 End" `
    "0" `
    "Traffic Light"

$cube.Update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull)
Write-Host "Cubo Cubo_Albarran creado con 10 KPIs y cálculos MDX." -ForegroundColor Green

# 8. Procesamiento completo del Cubo
Write-Host "Procesando la base de datos OLAP (ProcessFull)..." -ForegroundColor Cyan
$db.Process([Microsoft.AnalysisServices.ProcessType]::ProcessFull)
Write-Host "¡Procesamiento exitoso! Cubo OLAP listo para consultas." -ForegroundColor Green

# 9. Exportar XMLA completo
$xmlaPath = [System.IO.Path]::Combine((Get-Location).Path, "olap\Deploy_Cubo_Albarran.xmla")
$writer = [System.Xml.XmlWriter]::Create($xmlaPath, (New-Object System.Xml.XmlWriterSettings))
$scripter = New-Object Microsoft.AnalysisServices.Scripter
$scripter.ScriptCreate([Microsoft.AnalysisServices.MajorObject[]]@($db), $writer, $true)
$writer.Close()
Write-Host "Script XMLA exportado a $xmlaPath" -ForegroundColor Green

$server.Disconnect()
Write-Host "Despliegue finalizado con éxito." -ForegroundColor Cyan
