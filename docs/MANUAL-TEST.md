# Protocole manuel A/B/A

**État actuel : non exécuté. Aucun résultat en jeu n'est acquis.**

## Préparation

1. Conserver une sauvegarde manuelle de référence. Noter jeu 2.5, grade exact de Stalker, grades des armes, compétences, difficulté, FOV et lunettes. Aucun Ping, marquage préalable ou autre effet de révélation pour mesurer Stalker seul.
2. Choisir un ennemi non marqué derrière une couverture, à distance inférieure à la portée affichée de Stalker. Conserver position, orientation, cible et couverture. Aligner soigneusement le centre de visée : les champs de vision de Lizzie et du sniper diffèrent.
3. Préparer Lizzie, Breakthrough et si possible un Nekomata ordinaire. Faire les essais avec les armes existantes, sans créer de nouvelle arme ni changer les paramètres de pénétration.
4. Avant tout candidat, établir le témoin sans CET. Puis, après installation séparée de CET officiel 1.38.0, répéter avec CET seul. Si CET seul change le résultat, arrêter : le témoin n'est plus comparable.

## A — CET seul, candidat absent

Pour chaque arme : viser sans tirer, attendre deux secondes, noter la présence/absence de silhouette ; répéter cinq fois en quittant la visée entre les essais. Tester à courte distance puis à une seconde distance comprise dans la portée de Stalker. Ne pas utiliser le scanner pour révéler la cible avant la mesure.

Avec CET, console ouverte et arme sortie, cette commande en lecture seule permet de relever le record réellement utilisé et son tag (API vérifiée dans les sources ; commande pas encore exécutée dans CET réel) :

```lua
local p = Game.GetPlayer(); local w = p and Game.GetTransactionSystem():GetItemInSlot(p, TweakDBID.new("AttachmentSlots.WeaponRight")); if w then local r = w:GetWeaponRecord(); print(r:GetID().value, r:PreviewEffectName().value, r:PreviewEffectTag().value) else print("Sortir une arme dans une partie chargée.") end
```

Le candidat ne couvre que `Items.Preset_Nekomata_Breakthrough`. Si un autre ID apparaît, transmettre cette sortie et arrêter l'installation du candidat actuel. Il ne faut pas substituer un ID au hasard. Si `.value` ne résout pas le nom, conserver la représentation brute via `tostring(r:GetID())`.

## B — candidat CET

1. Fermer complètement le jeu. Installer avec `Manage-Mod.ps1 -Action Install` après lecture des conclusions.
2. Relancer, charger la sauvegarde de référence. Vérifier le journal CET dans `bin/x64/plugins/cyber_engine_tweaks/` et celui du mod dans son dossier. Rechercher le préfixe `[BreakthroughStalkerFix]` : le message doit annoncer le candidat actif ; tout refus, erreur de relecture ou restauration signifie échec du test.
3. Répéter les mesures de A avec exactement les mêmes paramètres. La commande doit montrer `pierce` pour Breakthrough. Lizzie doit toujours montrer `pierce` et se comporter comme avant.
4. Changer d'arme plusieurs fois, rengainer puis ressortir, recharger la sauvegarde, quitter complètement et relancer. Répéter le test de visée.
5. Contrôles négatifs : retirer Stalker dans un essai distinct, puis utiliser une arme Power témoin avec Stalker. Aucune nouvelle capacité générale de révélation ne doit être introduite. Comparer à leurs comportements témoins réels, sans supposer l'absence de toute révélation fournie par d'autres systèmes.

## Dégâts, pénétration et ricochets

Comparer **Breakthrough avant/après**, pas ses dégâts à ceux de Lizzie. Restaurer la même sauvegarde entre séries pour conserver cible, santé, armure, buffs et distance.

| Essai | À consigner |
|---|---|
| Tir au torse sans couverture | Dégâts, critique ou non, santé restante, niveau de charge |
| Tir au torse à travers la même couverture | Impact, dégâts, critique ou non, niveau de charge |
| Tir non chargé / partiellement chargé / pleinement chargé | Pénétration et nombre d'impacts pour chaque état |
| Couverture déjà traversable et couverture témoin non traversable | Même résultat physique avant/après |
| Situation de ricochet reproductible | Impacts physiques, séparément de l'aperçu visuel |

Faire au moins dix tirs comparables par condition si les valeurs varient. Séparer critiques, tirs chargés et bonus temporaires ; un seul chiffre identique ne prouve pas l'absence de régression. Arrêter si une différence physique reproductible apparaît. Une modification de l'aperçu des ricochets est une limite attendue ; elle ne doit pas être confondue avec la disparition des ricochets eux-mêmes.

## A — retour arrière

Fermer complètement le jeu, exécuter `Manage-Mod.ps1 -Action Uninstall`, relancer et charger la sauvegarde de référence. Vérifier le retour du tag `ricochet` et du comportement initial. Conserver CET pour isoler le retrait du seul candidat. Ses propres fichiers se désinstallent séparément selon sa documentation officielle.

## Feuille de résultats

| Phase | Arme / ID | Stalker grade | Distance / couverture | Détections sur 5 | Tag | Dégâts / pénétration | Remarques |
|---|---|---|---|---|---|---|---|
| A initial | Lizzie | | | | | | |
| A initial | Breakthrough | | | | | | |
| A initial | Nekomata | | | | | | |
| B candidat | Lizzie | | | | | | |
| B candidat | Breakthrough | | | | | | |
| B candidat | Nekomata | | | | | | |
| A retrait | Breakthrough | | | | | | |

Acceptation : amélioration reproductible de la détection avec Breakthrough + Stalker, contrôles inchangés, aucune régression physique détectée, comportement stable après relance et retrait effectif. Sans ces résultats, conserver le statut « candidat non validé en jeu ».
