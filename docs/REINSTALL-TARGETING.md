# Réinstallation de la révision de ciblage

Seul `Items.Uncommon_Nekomata_Breakthrough.previewEffectTag` est désormais ciblé. L'ancien preset ne l'est plus. Préconditions, relecture et restauration sont conservées. Aucun déploiement effectué par l'agent.

1. **Quitter complètement Cyberpunk 2077** pour effacer la modification en mémoire de l'ancien preset. Ne pas utiliser seulement « Reload all mods ».
2. Dans PowerShell, depuis `C:\Users\angan\Desktop\BreakthroughStalkerFix` :

```powershell
.\Manage-Mod.ps1 -Action Uninstall -WhatIf
.\Manage-Mod.ps1 -Action Uninstall
```

Si le reçu est invalide ou le fichier modifié, arrêter et transmettre l'erreur, sans contourner le contrôle.

3. Le dossier installé contient aussi `BreakthroughStalkerFix.log` et `db.sqlite3`, conservés par le désinstallateur. Après retrait réussi, déplacer le dossier résiduel `C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077\bin\x64\plugins\cyber_engine_tweaks\mods\BreakthroughStalkerFix` vers un nouveau dossier de sauvegarde hors du jeu, par exemple sur le Bureau. Il ne doit plus contenir `init.lua` ni `installation.json`. Ne rien écraser. Cette étape libère le chemin que l'installateur refuse volontairement d'écraser.
4. Installer la révision préparée :

```powershell
.\Manage-Mod.ps1 -Action Install -WhatIf
.\Manage-Mod.ps1 -Action Install
```

CET reste installé. En cas de refus d'accès à Program Files, utiliser les droits nécessaires uniquement pour ces opérations. Aucun fichier original du jeu n'est remplacé.

## Contrôle du ciblage uniquement

Relancer, charger la partie et sortir Breakthrough. Reprendre la commande CET du premier test, ou exécuter :

```lua
local p = Game.GetPlayer(); local w = p and Game.GetTransactionSystem():GetItemInSlot(p, TweakDBID.new("AttachmentSlots.WeaponRight")); if w then local r = w:GetWeaponRecord(); print(r:GetID().value .. " " .. r:PreviewEffectTag().value) else print("Sortir Breakthrough dans une partie chargée.") end
```

Résultat attendu :

```text
Items.Uncommon_Nekomata_Breakthrough pierce
```

Le journal du mod doit nommer cette cible et annoncer `ricochet -> pierce`. Si le résultat diffère ou si une précondition échoue, conserver console et journal et arrêter ici. **Tester la détection Kiroshi Stalker seulement après confirmation de ce résultat.** Les tests simulés ne prouvent pas l'effet en jeu.
