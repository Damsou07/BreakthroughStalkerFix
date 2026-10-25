[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Status', 'Install', 'Uninstall')][string]$Action = 'Status',
    [string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Aucun téléchargement, remplacement de fichier existant ou effacement récursif.
$gameRoot = [IO.Path]::GetFullPath($GamePath).TrimEnd('\', '/')
$relativeFolder = 'bin\x64\plugins\cyber_engine_tweaks\mods\BreakthroughStalkerFix'
$modFolder = [IO.Path]::GetFullPath((Join-Path $gameRoot $relativeFolder))
if (-not $modFolder.StartsWith($gameRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'La destination sort du dossier du jeu.'
}
$ancestor = $modFolder
while ($ancestor) {
    if (Test-Path -LiteralPath $ancestor) {
        if ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Lien ou jonction non pris en charge : $ancestor"
        }
    }
    $ancestor = [IO.Path]::GetDirectoryName($ancestor)
}
$targetFile = Join-Path $modFolder 'init.lua'
$receiptFile = Join-Path $modFolder 'installation.json'
$sourceFile = Join-Path $PSScriptRoot 'package\cet\BreakthroughStalkerFix\init.lua'
$cetFile = Join-Path $gameRoot 'bin\x64\plugins\cyber_engine_tweaks.asi'

if ($Action -eq 'Status') {
    [pscustomobject]@{
        GamePath = $gameRoot
        CETPresent = Test-Path -LiteralPath $cetFile -PathType Leaf
        ModPresent = Test-Path -LiteralPath $targetFile -PathType Leaf
        ReceiptPresent = Test-Path -LiteralPath $receiptFile -PathType Leaf
        Status = 'Candidat : validation en jeu requise'
    }
    return
}
if (Get-Process -Name Cyberpunk2077 -ErrorAction SilentlyContinue) {
    throw 'Fermer complètement Cyberpunk 2077 avant de continuer.'
}

if ($Action -eq 'Install') {
    $gameExe = Get-Item -LiteralPath (Join-Path $gameRoot 'bin\x64\Cyberpunk2077.exe')
    $info = $gameExe.VersionInfo
    $parts = '{0}.{1}.{2}.{3}' -f $info.FileMajorPart, $info.FileMinorPart, $info.FileBuildPart, $info.FilePrivatePart
    if ($info.ProductVersion -ne '2.5' -or $parts -ne '3.0.88.46235') {
        throw "Version non étudiée : produit $($info.ProductVersion), fichier $parts."
    }
    if (-not (Test-Path -LiteralPath $cetFile -PathType Leaf)) {
        throw 'CET absent. Installer séparément CET officiel 1.38.0 avant ce candidat.'
    }
    if (Test-Path -LiteralPath $modFolder) {
        throw 'Dossier du mod déjà présent : aucun écrasement. Utiliser Status ou Uninstall.'
    }
    $sourceHash = (Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash
    if ($PSCmdlet.ShouldProcess($modFolder, 'Installer le candidat CET, une seule propriété visuelle')) {
        New-Item -ItemType Directory -Path $modFolder | Out-Null
        try {
            Copy-Item -LiteralPath $sourceFile -Destination $targetFile
            if ((Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash -ne $sourceHash) {
                throw 'Copie non conforme.'
            }
            [pscustomobject]@{Mod='BreakthroughStalkerFix';Version='0.1.0';SHA256=$sourceHash} |
                ConvertTo-Json | Set-Content -LiteralPath $receiptFile -Encoding UTF8
        } catch {
            # Seuls les deux fichiers de cette opération sont concernés.
            foreach ($ownedFile in @($targetFile, $receiptFile)) {
                if (Test-Path -LiteralPath $ownedFile) { Remove-Item -LiteralPath $ownedFile }
            }
            if (@(Get-ChildItem -LiteralPath $modFolder -Force).Count -eq 0) { Remove-Item -LiteralPath $modFolder }
            throw
        }
        Write-Output 'Candidat installé. Aucune sauvegarde ni base du jeu modifiée sur disque.'
    }
    return
}

if (-not (Test-Path -LiteralPath $modFolder)) { Write-Output 'Mod absent : aucune action.'; return }
foreach ($ownedFile in @($targetFile, $receiptFile)) {
    if (-not (Test-Path -LiteralPath $ownedFile -PathType Leaf)) { throw "Fichier attendu absent : $ownedFile. Retrait automatique arrêté." }
    if ((Get-Item -LiteralPath $ownedFile -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Lien interdit : $ownedFile" }
}
$receipt = Get-Content -LiteralPath $receiptFile -Raw | ConvertFrom-Json
if ($receipt.Mod -ne 'BreakthroughStalkerFix' -or $receipt.Version -ne '0.1.0' -or
    $receipt.SHA256 -notmatch '^[A-Fa-f0-9]{64}$' -or
    (Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash -ne $receipt.SHA256) {
    throw 'Reçu invalide ou init.lua modifié : retrait arrêté pour préserver les changements.'
}
if ($PSCmdlet.ShouldProcess($modFolder, 'Retirer les deux fichiers appartenant au candidat')) {
    Remove-Item -LiteralPath $targetFile
    Remove-Item -LiteralPath $receiptFile
    if (@(Get-ChildItem -LiteralPath $modFolder -Force).Count -eq 0) {
        Remove-Item -LiteralPath $modFolder
    } else {
        Write-Output 'Les autres fichiers, notamment les journaux, ont été conservés.'
    }
    Write-Output 'Candidat retiré. Le prochain lancement utilisera les données originales.'
}
