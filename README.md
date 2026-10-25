# Breakthrough / Kiroshi Stalker — candidat 0.1.0

**Investigation terminée, candidat préparé, aucun fichier installé dans Cyberpunk 2077. Validation en jeu encore nécessaire.**

Dans les deux bases locales du jeu 2.5, Breakthrough sélectionne l'aperçu `ricochet`, tandis que Lizzie sélectionne `pierce`. Le script local `DefaultTransition.ShowAttackPreview` réserve la branche liée à `TechPierceHighlightsEnabled` au tag `pierce`. Le candidat change uniquement `Items.Preset_Nekomata_Breakthrough.previewEffectTag` de `ricochet` à `pierce`.

Lire [l'investigation](docs/INVESTIGATION.md) avant installation, puis suivre le [protocole en jeu](docs/MANUAL-TEST.md). Les paramètres de dégâts, pénétration, charge et ricochet ne sont pas écrits. L'aperçu visuel des ricochets peut être remplacé : c'est une limite explicite de cette solution minimale.

## Contenu

- `package/cet/BreakthroughStalkerFix/init.lua` : candidat à un seul champ, préconditions et restauration en mémoire.
- `Manage-Mod.ps1` : état, installation sans écrasement, désinstallation avec contrôle SHA-256.
- `package/tweakxl-future/BreakthroughStalkerFix.yaml` : alternative pour une future version stable compatible ; **non déployée par le script**.
- `research/metadata/` : versions, empreintes et comparaisons locales.
- `scripts/inspect-tweakdb.mjs` : lecteur partiel en lecture seule du format TweakDB 8/4.
- `tests/` : tests Lua simulés, preuves et installation dans un dossier de test.

## Compatibilité vérifiée au 25 octobre 2026

Jeu local : produit **2.5**, version PE **3.0.88.46235**, build Steam **26161058**. La chaîne textuelle Windows `3.0.5813403` désigne ici le même exécutable ; les quatre composants PE servent au contrôle.

Utiliser [CET officiel 1.38.0](https://github.com/maximegmd/CyberEngineTweaks/releases/tag/v1.38.0), dont l'auteur annonce le support de cette version. CET n'est pas installé et n'est pas fourni ici. Le candidat vérifie sa version à l'exécution. RED4ext et redscript ne sont pas nécessaires pour ce candidat CET.

[TweakXL stable 1.11.5](https://github.com/psiberx/cp2077-tweak-xl/releases/tag/v1.11.5) précède le patch ; son [portage 2.5 est une PR ouverte](https://github.com/psiberx/cp2077-tweak-xl/pull/23) au moment de la vérification. C'est la raison du recours à CET. Ne pas installer de build non officiel pour ce projet. Ne pas cumuler les variantes CET et YAML.

## Commandes PowerShell

Depuis ce dossier, avec PowerShell 7 (`pwsh`) :

```powershell
.\Manage-Mod.ps1 -Action Status
# Après lecture des conclusions et installation séparée de CET officiel :
.\Manage-Mod.ps1 -Action Install -WhatIf
.\Manage-Mod.ps1 -Action Install
# Jeu complètement fermé :
.\Manage-Mod.ps1 -Action Uninstall -WhatIf
.\Manage-Mod.ps1 -Action Uninstall
```

`-GamePath` permet de préciser l'installation. Le script n'élève pas ses privilèges et ne télécharge rien. Si Windows refuse l'écriture sous Program Files, relancer uniquement l'opération d'installation/retrait avec les droits nécessaires. Un dossier existant ou un `init.lua` modifié provoque un refus ; aucun fichier original n'est remplacé. La désinstallation conserve CET et les journaux éventuels. Quitter puis relancer le jeu pour garantir le retour aux données chargées depuis le disque ; le simple rechargement d'une sauvegarde ne suffit pas.

## Vérification hors jeu

Node.js 22 a été utilisé ; la dépendance Fengari ne sert qu'aux tests, pas au mod.

```powershell
npm ci --ignore-scripts --no-audit --no-fund
npm test
.\tests\Test-Installer.ps1
.\scripts\Verify-LocalEvidence.ps1
```

Les 17 tests Node/Lua passent. Le scénario PowerShell passe dans une installation factice sous `.test-output`, avec copie locale de l'exécutable pour contrôler ses métadonnées ; il ne lance jamais cet exécutable. Les tests Lua simulent CET et ne prouvent ni le chargement dans CET réel ni le rendu en jeu.

La décompilation locale a utilisé [redscript-cli 0.5.32 officiel](https://github.com/jac3km4/redscript/releases/tag/v0.5.32), sans installer redscript dans le jeu. Les scripts décompilés, copies du jeu, sources tierces et outils restent locaux et sont exclus par `.gitignore`. Ne pas distribuer le dossier de travail complet ; seuls le candidat, ses scripts et sa documentation constituent le projet à partager.

## Limites et informations à relever

Le candidat cible le preset courant uniquement. Les six autres enregistrements historiques Breakthrough observés ne sont pas modifiés. Il faut confirmer que votre arme équipée utilise `Items.Preset_Nekomata_Breakthrough`, noter le grade exact de Stalker et exécuter le test A/B/A. L'identifiant exact du cyberware équipé et ses statistiques actives n'ont pas été lus dans une partie. Aucun identifiant Stalker n'est supposé ou créé.

Si le tag passe bien à `pierce` mais que la détection reste absente, arrêter les changements : fournir les résultats du protocole, l'identifiant de l'arme équipée, le grade Stalker et les journaux CET. Il faudra alors examiner les statistiques actives et l'effet natif de prévisualisation ; ne pas tenter de corriger cela en modifiant la pénétration.
