# Investigation du 25 octobre 2026

## Révision après le premier relevé en jeu

L'utilisateur a observé `Items.Uncommon_Nekomata_Breakthrough ricochet`. Une nouvelle lecture directe des deux bases locales confirme ce record, `weaponPreview` et `ricochet` : voir `research/metadata/targeting-verification.json`.

Le candidat cible désormais ce seul record au lieu du preset. Préconditions, journaux et restauration sont conservés ; le journal de succès précise la cible. Un test vérifie que l'ancien preset et Lizzie restent inchangés. Le YAML inactif est aligné. Aucun déploiement effectué pendant cette révision.

Le prochain critère est uniquement `Items.Uncommon_Nekomata_Breakthrough pierce` avec l'arme équipée. Voir [la réinstallation](REINSTALL-TARGETING.md). Tester la détection ensuite seulement.

**Le reste de ce rapport conserve l'investigation initiale : ses mentions de ciblage du preset décrivent le premier candidat, remplacé par cette révision.**

## Conclusion et niveau de preuve

**Cause statique suffisamment établie pour un candidat ciblé : Breakthrough emprunte la branche de prévisualisation des ricochets au lieu de celle de la pénétration. L'efficacité du candidat n'est pas encore démontrée en jeu.**

Ce résultat vient des fichiers de l'installation indiquée, pas d'une supposition sur les armes techniques. L'observation Lizzie fonctionne / Breakthrough échoue est fournie par l'utilisateur ; elle n'a pas été reproduite par l'agent. Aucun lancement du jeu, aucune écriture dans son installation et aucune modification de sauvegarde n'ont été effectués.

## Environnement et méthode

Installation : `C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077`.

- Produit 2.5, composants PE 3.0.88.46235, build Steam 26161058.
- `r6/cache/final.redscripts`, `tweakdb.bin` et `tweakdb_ep1.bin` présents ; empreintes dans `research/metadata/local-installation.json`.
- Aucun framework trouvé aux emplacements habituels CET / TweakXL / RED4ext, ni dossiers usuels de mods. Cela ne certifie pas l'intégrité Steam complète et n'exclut pas un gestionnaire externe.
- Le dossier `tools` ne contient pas les sources REDmod `.tweak` nécessaires.
- Décompilation de `final.redscripts` avec redscript-cli officiel v0.5.32 : succès, sortie dans `research/local-scripts`. SHA-256 du CLI vérifié contre le digest de l'asset GitHub : `C8665C40199FB784A78B980DB3A304A7F0B14A9494B3B59A125FF5618BF13F6C`.
- Lecture des deux bases avec un lecteur Node partiel, sans écriture : en-tête 8/4, tables de types, CName, références, tableaux et valeurs scalaires nécessaires. Contrôles de bornes, indices et fins des blocs. Les types non nécessaires sont ignorés, pas interprétés.

Le format est vérifié dans les sources publiques de [WolvenKit TweakDBReader](https://github.com/WolvenKit/WolvenKit/blob/main/WolvenKit.RED4/TweakDB/TweakDBReader.cs), [Header](https://github.com/WolvenKit/WolvenKit/blob/main/WolvenKit.RED4/TweakDB/Header.cs) et [TweakDB](https://github.com/WolvenKit/WolvenKit/blob/main/WolvenKit.RED4/TweakDB/TweakDB.cs). **WolvenKit n'a été ni installé ni exécuté** : seules ses sources ont servi de référence du format. L'ancienne [spécification flibdev](https://github.com/flibdev/010_CP77_TweakDB) décrit le format 5 ; elle ne suffit pas à interpréter le format 8 local. Le lecteur reste un outil d'investigation partiel, pas un exporteur général validé de TweakDB.

## Signalements et correctifs publics

Des joueurs signalent Breakthrough dans la [discussion Steam commencée en septembre 2023](https://steamcommunity.com/app/1091500/discussions/7/3878218563606354789/). Certains évoquent la lunette ; il s'agit de leurs observations ou hypothèses, pas d'une preuve technique. La [demande Nexus de novembre 2023](https://forums.nexusmods.com/topic/13436987-kiroshi-stlaker-fix/) n'apporte pas de correctif démontré.

Le remplacement de lunette n'est pas retenu : un [testeur rapporte un échec même avec la même lunette qu'un Nekomata ordinaire](https://www.reddit.com/r/cyberpunkgame/comments/1vhfyx9/kiroshi_stalker_fix_for_iconic_weapons/). Ce témoignage est contradictoire avec le contournement proposé et n'établit pas davantage la cause.

Les résultats consultés incluent [Cyberware Improved](https://www.nexusmods.com/cyberpunk2077/mods/23554) et [Eye In The Sky Highlight Fix](https://www.nexusmods.com/cyberpunk2077/mods/30246). Le premier modifie largement les cyberwares ; le second vise les appareils surlignés. Aucun correctif minimal et vérifié de cette incompatibilité précise n'a été identifié dans les sources consultées. Cela ne prouve pas qu'aucun n'existe.

## Conditions effectivement lues dans le jeu installé

`research/local-scripts/cyberpunk/player/psm/defaultTransition.script`, lignes 1881–1909, méthode `DefaultTransition.ShowAttackPreview` :

1. `showIfAiming` doit être vrai et l'état UpperBody doit être `aimingState`.
2. Un enregistrement d'arme doit exister et `PreviewEffectName()` doit différer de `None`.
3. Si `PreviewEffectTag()` vaut `ricochet`, l'activation dépend de `CanSeeRicochetVisuals` sur le joueur et `RicochetCount` sur l'arme.
4. Si le tag vaut `pierce`, il faut `TechPierceEnabled > 0` sur l'arme et `TechPierceHighlightsEnabled > 0` sur le joueur.
5. Le résultat est transmis à `weaponObject.GetCurrentAttack().SetPreviewActive(show)`.

Les symboles sont des noms présents dans les scripts locaux, pas des identifiants TweakDB inventés. Cette méthode ne contient pas de liste d'armes autorisées et ne teste pas directement une lunette. La sélection du tag est donc une explication plus précise qu'un hypothétique tag `TechWeapon` manquant.

`research/local-scripts/core/gameplay/effectors/custom/kiroshiHighlightEffector.script`, lignes 7–11 et 87–118 : l'effector générique Kiroshi suit l'évolution Tech, la visée et `TechPierceHighlightsEnabled`. Lorsque ces trois conditions sont actives, il quitte `ContinuousAction` avant `ProcessEffector`. Cela peut expliquer l'absence de surbrillance de repli pendant la visée. **Le rattachement de cet effector à chaque variante de Stalker n'a pas été reconstitué** : ne pas présenter ce mécanisme générique comme le graphe complet de cet implant.

La [source publique de DefaultTransition](https://github.com/CDPR-Modding-Documentation/Cyberpunk-Scripts/blob/cfcf5071e5363962a44c33cb7cab749688b0ca51/scripts/cyberpunk/player/psm/defaultTransition.script) corrobore les deux branches. Elle diffère sur certains détails, notamment l'objet lu pour RicochetCount ; **la décompilation locale prévaut**. Les [déclarations WeaponItem](https://github.com/WolvenKit/WolvenKit/blob/main/WolvenKit.RED4/Types/ClassesExt/Tweak/gamedataWeaponItem_Record.cs) confirment les noms `previewEffectName` et `previewEffectTag` et leur type CName.

## Comparaison des bases locales

Les résultats suivants sont identiques dans `tweakdb.bin` et `tweakdb_ep1.bin` :

| Enregistrement vérifié | previewEffectName | previewEffectTag | Tag TechWeapon |
|---|---|---|---|
| `Items.Preset_Nekomata_Breakthrough` | weaponPreview | **ricochet** | présent |
| `Items.Preset_Omaha_Suzie` | weaponPreview | **pierce** | présent |
| `Items.Preset_Omaha_Suzie_Epic` | weaponPreview | pierce | présent |
| `Items.Preset_Omaha_Suzie_Legendary` | weaponPreview | pierce | présent |
| `Items.Craftable_Uncommon_Nekomata` | weaponPreview | pierce | présent |

Breakthrough et Lizzie partagent aussi la référence `evolution` numérique `0x1481d10fe7`. Son nom textuel n'a pas été résolu et n'est pas supposé. Les tableaux de statistiques diffèrent ; **aucun n'est copié**. L'identification de Lizzie comme `Items.Preset_Omaha_Suzie` est corroborée par les données publiées par l'auteur de [Netrunner's Data Dump](https://github.com/emdCatalyst/netrunners-data-dump) puis par la présence du record dans les deux bases locales. Les anciens noms de Lizzie apparaissent aussi dans la logique locale `LegendaryLizzieFixed` de craftingSystem.

Autres records Breakthrough lus avec `ricochet` : `Items.Common_Nekomata_Breakthrough`, `Items.Uncommon_Nekomata_Breakthrough`, `Items.Rare_Nekomata_Breakthrough`, `Items.Epic_Nekomata_Breakthrough`, `Items.Legendary_Nekomata_Breakthrough`, `Items.Preset_Nekomata_Breakthrough_Legendary`. Leurs noms viennent du script local de fabrication, leur existence et leurs propriétés sont vérifiées dans les bases. Ils restent hors du correctif minimal tant que l'arme équipée ne les exige pas.

`Items.Breakthrough_scope` existe et est référencé par les scripts locaux de réserve/fabrication. Aucune modification de lunette n'est nécessaire au candidat.

Exports reproductibles : `research/metadata/tweakdb-comparison.json` et `tweakdb-ep1-comparison.json`. Les références non résolues restent numériques ; aucune chaîne d'identifiant n'est fabriquée à partir d'un hash inconnu.

Commandes utilisées depuis la racine du projet (outil téléchargé uniquement dans le projet) :

```powershell
.\research\tools\redscript-cli.exe decompile -i 'C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077\r6\cache\final.redscripts' -o '.\research\local-scripts' -f
node scripts/inspect-tweakdb.mjs 'C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077\r6\cache\tweakdb.bin' research/local-scripts research/metadata/tweakdb-comparison.json
node scripts/inspect-tweakdb.mjs 'C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077\r6\cache\tweakdb_ep1.bin' research/local-scripts research/metadata/tweakdb-ep1-comparison.json
```

## Choix du candidat

Une seule modification : le champ CName `previewEffectTag` du preset courant, de `ricochet` vers `pierce`. Le CName est lu sur Lizzie et réutilisé tel quel. L'API [TweakDB documentée](https://wiki.redmodding.org/scripting-cyberpunk/scripting/game-systems/tweakdb) et les sources [CET v1.38.0 Scripting.cpp](https://github.com/maximegmd/CyberEngineTweaks/blob/v1.38.0/src/scripting/Scripting.cpp), [ScriptContext.cpp](https://github.com/maximegmd/CyberEngineTweaks/blob/v1.38.0/src/scripting/ScriptContext.cpp) et [TweakDB.cpp](https://github.com/maximegmd/CyberEngineTweaks/blob/v1.38.0/src/reverse/TweakDB/TweakDB.cpp) ont été consultées pour les événements, CName.value, GetVersion, GetRecord, GetFlat, SetFlat et Update.

Préconditions : CET 1.38.0, records existants, aperçu `weaponPreview` sur les deux armes, tag original `ricochet`, donneur `pierce`. Le script vérifie ensuite le flat et le getter du record. Au retrait en mémoire, il restaure l'ancienne valeur seulement si la valeur courante correspond toujours à la sienne. Un autre mod écrivant exactement la même valeur reste indiscernable ; éviter les mods concurrents sur ce champ.

Le candidat ne modifie ni `TechPierceEnabled`, ni charge, ni dégâts, ni projectiles, ni RicochetCount, ni caractéristiques de l'implant. Il peut substituer l'aperçu visuel de pénétration à celui des ricochets. L'effet natif derrière `weaponPreview/pierce` n'a pas été inspecté dans les ressources ; son fonctionnement sur Breakthrough doit être confirmé par le protocole. Ne pas annoncer une correction validée avant ce test.

## Faits, hypothèses et inconnues

- **Vérifié hors jeu** : version locale, propriétés et types dans les deux bases, branche de décision du script, API du candidat, absence d'écritures balistiques dans le candidat.
- **Conclusion étayée** : le mauvais choix de prévisualisation explique pourquoi l'activation Stalker n'est pas prise en compte par Breakthrough dans cette méthode.
- **À tester** : suffisance du changement, rendu dans la lunette, conservation du comportement physique et comportement au rechargement.
- **Non déterminé** : record exact et grade de l'implant équipé, statistiques calculées du joueur et de son arme, ID de l'instance équipée, éventuels conflits injectés à l'exécution.

Si les préconditions ou les tests échouent, suspendre toute extension du correctif. Les données nécessaires seront : ID d'arme équipée, grade Stalker, valeurs actives des deux statistiques de la branche `pierce`, nom/tag d'aperçu, résultat Lizzie/Breakthrough dans une même scène et journaux CET. La lunette et les dégâts ne doivent pas être modifiés pour masquer un échec.
