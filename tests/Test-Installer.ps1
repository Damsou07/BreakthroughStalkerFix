param([string]$ReferenceGamePath = 'C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path $PSScriptRoot -Parent
$fixtureRoot = Join-Path $projectRoot ('.test-output\game-' + [guid]::NewGuid().ToString('N'))
$binaryRoot = Join-Path $fixtureRoot 'bin\x64'
New-Item -ItemType Directory -Path (Join-Path $binaryRoot 'plugins') -Force | Out-Null
# Copie locale de référence pour tester les métadonnées PE ; jamais exécutée ni distribuée.
Copy-Item -LiteralPath (Join-Path $ReferenceGamePath 'bin\x64\Cyberpunk2077.exe') -Destination (Join-Path $binaryRoot 'Cyberpunk2077.exe')
Set-Content -LiteralPath (Join-Path $binaryRoot 'plugins\cyber_engine_tweaks.asi') -Value 'Test uniquement'
$manager = Join-Path $projectRoot 'Manage-Mod.ps1'
$target = Join-Path $binaryRoot 'plugins\cyber_engine_tweaks\mods\BreakthroughStalkerFix'
function Assert-Condition([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Rejected([scriptblock]$Operation) {
    $rejected = $false
    try { & $Operation | Out-Null } catch { $rejected = $true }
    Assert-Condition $rejected 'Une opération qui devait être refusée a été acceptée.'
}
# Vérifier le refus sans CET avant le scénario nominal.
$cetPath = Join-Path $binaryRoot 'plugins\cyber_engine_tweaks.asi'
Remove-Item -LiteralPath $cetPath
Assert-Rejected { & $manager -Action Install -GamePath $fixtureRoot }
Assert-Condition (-not (Test-Path -LiteralPath $target)) 'Le refus a créé le dossier du mod.'
Set-Content -LiteralPath $cetPath -Value 'Test uniquement'
& $manager -Action Install -GamePath $fixtureRoot -WhatIf
Assert-Condition (-not (Test-Path -LiteralPath $target)) 'WhatIf a écrit des fichiers.'
& $manager -Action Install -GamePath $fixtureRoot
Assert-Condition (Test-Path -LiteralPath (Join-Path $target 'init.lua')) 'Installation absente.'
Assert-Rejected { & $manager -Action Install -GamePath $fixtureRoot }
$luaPath = Join-Path $target 'init.lua'
$originalBytes = [IO.File]::ReadAllBytes($luaPath)
Add-Content -LiteralPath $luaPath -Value '-- Modification utilisateur'
Assert-Rejected { & $manager -Action Uninstall -GamePath $fixtureRoot }
Assert-Condition (Test-Path -LiteralPath $luaPath) 'Le fichier modifié a été supprimé.'
[IO.File]::WriteAllBytes($luaPath, $originalBytes)
$logPath = Join-Path $target 'user.log'
Set-Content -LiteralPath $logPath -Value 'À conserver'
& $manager -Action Uninstall -GamePath $fixtureRoot -WhatIf
Assert-Condition (Test-Path -LiteralPath $luaPath) 'WhatIf a supprimé le mod.'
& $manager -Action Uninstall -GamePath $fixtureRoot
Assert-Condition (-not (Test-Path -LiteralPath $luaPath)) 'Le mod est encore installé.'
Assert-Condition (Test-Path -LiteralPath $logPath) 'Le journal utilisateur a été supprimé.'
# Sans reçu, un dossier restant ne doit pas être supprimé.
Assert-Rejected { & $manager -Action Uninstall -GamePath $fixtureRoot }
Write-Output "OK : simulation, installation, refus d’écrasement, préservation des modifications, désinstallation et conservation des journaux."
Write-Output "Fixture conservée dans $fixtureRoot"
