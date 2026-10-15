# Bluff Game

Jeu multijoueur en ligne (5 à 10 joueurs, PC) : une succession de mini-jeux de mensonge, de trahison et de collaboration. Le joueur qui a le plus de Points à la fin de la partie gagne.

## Sommaire

- [Pitch](#pitch)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Lancer le projet](#lancer-le-projet)
- [Tests et qualité du code](#tests-et-qualité-du-code)
- [Structure du projet](#structure-du-projet)
- [Documentation](#documentation)
- [Contribuer](#contribuer)

## Pitch

Dans Bluff Game, les joueurs rejoignent un lobby, se retrouvent dans une salle globale où ils peuvent discuter, former des alliances ou se trahir, puis participent à des épreuves sous forme de mini-jeux. Entre chaque épreuve, ils peuvent dépenser leurs Points pour acheter des quêtes secrètes ou des avantages. Le solde de chacun reste caché : tout repose sur la communication et le bluff à l'oral.

Inspirations : *L'Épreuve du Diable*, *Scam Line*, *Among Us*, *Loup-Garou*, *Avalon*.

## Prérequis

- **Godot Engine 4.7** (moteur utilisé pour le projet, version configurée dans `project.godot`) - [télécharger Godot](https://godotengine.org/download/)
- **Git** - pour cloner le dépôt
- **Python 3.x** *(optionnel)* - uniquement si vous voulez lancer le linter/formatteur en local (voir [Tests et qualité du code](#tests-et-qualité-du-code))

Aucune dépendance externe n'est à installer côté Godot : le plugin de tests [GUT](https://github.com/bitwes/Gut) est déjà présent dans `addons/`.

## Installation

1. **Cloner le dépôt**

   ```bash
   git clone git@github.com:Ismerie/bluff_game.git
   cd bluff_game
   ```

   Si vous n'avez pas de clé SSH configurée sur GitHub, utilisez plutôt :

   ```bash
   git clone https://github.com/Ismerie/bluff_game.git
   cd bluff_game
   ```

2. **Se placer sur la branche de travail**

   La branche d'intégration est `develop`. Pour travailler sur une nouvelle fonctionnalité, partez de `develop` (voir [CONTRIBUTING.md](docs/CONTRIBUTING.md)) :

   ```bash
   git checkout develop
   git pull origin develop
   ```

3. **Ouvrir le projet dans Godot**

   - Lancez Godot 4.7.
   - Dans le gestionnaire de projets, cliquez sur **Importer** (ou **Scanner**).
   - Sélectionnez le fichier `project.godot` à la racine du dépôt.
   - Ouvrez le projet.

   Au premier lancement, Godot génère le dossier `.godot/` et les fichiers `.import` : c'est normal, ils sont ignorés par Git.

## Lancer le projet

- Dans l'éditeur, appuyez sur **F5** (ou le bouton ▶︎ *Lancer le projet*).
- La scène d'entrée est le **menu principal** (`assets/scenes/MainMenu.tscn`).
- Pour lancer une scène précise, utilisez **F6** (*Lancer la scène courante*).

Le multijoueur en ligne est en cours de développement : pour tester une fonctionnalité réseau, lancez plusieurs instances du projet (depuis l'éditeur ou en exécutable exporté).

## Tests et qualité du code

### Tests unitaires (GUT)

Les tests sont dans `assets/tests/` et s'exécutent avec le plugin GUT. Depuis l'éditeur, ouvrez le panneau **GUT** (en bas de l'écran) et lancez les tests.

En ligne de commande (headless) :

```bash
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://assets/tests -gprefix= -gsuffix=.test.gd -gexit
```

> Remplacez `godot` par le chemin de votre exécutable Godot si la commande n'est pas dans votre `PATH`.

### Lint et formatage (gdtoolkit)

Le code GDScript est vérifié par la CI avec [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit). Pour l'installer en local :

```bash
pip install "gdtoolkit==4.*"
```

Puis, à la racine du projet :

```bash
gdformat --check .   # vérifie le formatage
gdformat .           # formate automatiquement
gdlint .             # lint
```

Le dossier `addons/` est exclu de ces vérifications (voir `.gdlintrc` et `.gdformatrc`).

## Structure du projet

```
bluff_game/
├── assets/
│   ├── image/        # Images (ex. fond du menu)
│   ├── models/       # Modèles 3D (ex. le joueur)
│   ├── prefab/       # Scènes réutilisables (ex. Player.tscn)
│   ├── scenes/       # Scènes principales (MainMenu, Main)
│   ├── scripts/      # Scripts GDScript
│   ├── tests/        # Tests GUT
│   └── themes/       # Thèmes d'interface
├── addons/           # Plugins (GUT)
├── docs/             # Documentation du projet (CONTRIBUTING.md)
├── .github/          # Workflows CI/CD et modèles d'issues
├── project.godot     # Configuration du projet Godot
└── README.md
```

## Documentation

- **Game Design Document (GDD)** : [Game Design Document — Bluff Game (Notion)](https://app.notion.com/p/Game-Design-Document-Bluff-Game-37a3d64a20ff8172bd6ddbb1daad4136?source=copy_link)
  Référence partagée des règles, mécaniques et de la direction artistique. Il évolue avec le projet.
- **Guide de contribution** : [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)
  Conventions de branches, de commits, de Pull Requests et Definition of Done.

## Contribuer

Avant d'ouvrir une branche ou une Pull Request, lisez le [guide de contribution](docs/CONTRIBUTING.md). En résumé :

- Une branche par issue, nommée `type/[numero-issue]-[description-courte]` (ex. `feature/14-systeme-bluff`).
- Commits au format `type: description courte` (ex. `feature: ajout du système de bluff`).
- Les Pull Requests se font vers `develop`, jamais directement vers `main`.
- La CI (lint, format, tests GUT) doit passer avant la review.
