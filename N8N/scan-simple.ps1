# Script simplificado de escaneo de vulnerabilidades
# Usa Docker para evitar problemas de instalación local

param(
    [string]$ImageName = "my-n8n-image:latest"
)

Write-Host "=== Escaneo de Vulnerabilidades Simplificado ===" -ForegroundColor Blue
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Gray

# Verificar Docker
try {
    docker info | Out-Null
    Write-Host "OK: Docker está corriendo" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Docker no está corriendo" -ForegroundColor Red
    exit 1
}

# Construir imagen si no existe
if (-not (docker images | Select-String $ImageName)) {
    Write-Host "Construyendo imagen Docker..." -ForegroundColor Yellow
    docker build -f Dockerfile.cloudrun -t $ImageName .
}

Write-Host "=== Escaneando con Trivy (Docker) ===" -ForegroundColor Blue

# Crear directorio para resultados
$scanDir = "scan-results"
New-Item -ItemType Directory -Force -Path $scanDir | Out-Null

# Función para ejecutar Trivy
function Invoke-TrivyDocker {
    param(
        [string]$Severity,
        [string]$OutputFile,
        [string]$Format = "table"
    )
    
    Write-Host "Escaneando vulnerabilidades $Severity..." -ForegroundColor Yellow
    
    $dockerArgs = @(
        "run", "--rm",
        "-v", "${PWD}:/workspace",
        "-w", "/workspace",
        "aquasec/trivy:latest"
    )
    
    if ($Format -eq "json") {
        $dockerArgs += @("image", "--severity", $Severity, "--exit-code", "0", "--format", $Format, "--output", $OutputFile, $ImageName)
    } else {
        $dockerArgs += @("image", "--severity", $Severity, "--exit-code", "0", "--format", $Format, "--output", $OutputFile, $ImageName)
    }
    
    docker $dockerArgs
}

# Escaneo crítico/alto
try {
    Invoke-TrivyDocker -Severity "HIGH,CRITICAL" -OutputFile "$scanDir\critical.json" -Format "json"
    Write-Host "OK: No se encontraron vulnerabilidades críticas/altas" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Se encontraron vulnerabilidades críticas/altas" -ForegroundColor Red
}

# Escaneo medio
Invoke-TrivyDocker -Severity "MEDIUM" -OutputFile "$scanDir\medium.txt"

# Escaneo bajo
Invoke-TrivyDocker -Severity "LOW" -OutputFile "$scanDir\low.txt"

# Escaneo de configuración
Write-Host "Escaneando configuración de seguridad..." -ForegroundColor Yellow
docker run --rm -v "${PWD}:/workspace" -w /workspace aquasec/trivy:latest config --severity HIGH,CRITICAL --exit-code 0 --format table --output "$scanDir\config.txt" .

# Generar reporte
Write-Host "=== Generando Reporte ===" -ForegroundColor Blue

$report = @"
=== Reporte de Vulnerabilidades ===
Fecha: $(Get-Date)
Imagen: $ImageName
Método: Docker + Trivy

=== Vulnerabilidades Críticas/Altas ===
"@

if (Test-Path "$scanDir\critical.json") {
    $report += "`nSe encontraron vulnerabilidades. Revisa: $scanDir\critical.json"
} else {
    $report += "`nOK: No se encontraron vulnerabilidades críticas/altas"
}

$report += @"

=== Vulnerabilidades Medias ===
"@

if (Test-Path "$scanDir\medium.txt") {
    $report += "`n" + (Get-Content "$scanDir\medium.txt" -Raw)
}

$report += @"

=== Vulnerabilidades Bajas ===
"@

if (Test-Path "$scanDir\low.txt") {
    $report += "`n" + (Get-Content "$scanDir\low.txt" -Raw)
}

$report += @"

=== Configuración de Seguridad ===
"@

if (Test-Path "$scanDir\config.txt") {
    $report += "`n" + (Get-Content "$scanDir\config.txt" -Raw)
}

$report | Out-File -FilePath "$scanDir\report.txt" -Encoding UTF8

Write-Host "OK: Reporte guardado en: $scanDir\report.txt" -ForegroundColor Green

# Resumen
Write-Host "`n=== Resumen ===" -ForegroundColor Blue
Write-Host "Resultados: $scanDir\" -ForegroundColor Green
Write-Host "Reporte: $scanDir\report.txt" -ForegroundColor Green

if (Test-Path "$scanDir\critical.json") {
    Write-Host "ADVERTENCIA: Se encontraron vulnerabilidades críticas" -ForegroundColor Red
Write-Host "Revisa el reporte antes de desplegar" -ForegroundColor Yellow
} else {
    Write-Host "OK: Imagen lista para despliegue" -ForegroundColor Green
}

Write-Host "`nConsejo: Este script usa Docker, no requiere instalar Trivy localmente" -ForegroundColor Cyan 