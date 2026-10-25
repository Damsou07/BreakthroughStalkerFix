param([string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$evidence = Get-Content -LiteralPath (Join-Path $projectRoot 'research\metadata\local-installation.json') -Raw | ConvertFrom-Json
foreach ($file in $evidence.Files) {
    $current = Get-FileHash -LiteralPath (Join-Path $GamePath $file.RelativePath) -Algorithm SHA256
    if ($current.Hash -ne $file.SHA256) { throw "Données différentes de l'analyse : $($file.RelativePath). Refaire l'investigation." }
}
Write-Output "OK : les quatre fichiers de référence correspondent aux empreintes de l’investigation."
