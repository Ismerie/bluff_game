# Architecture — bluff_game

> **Statut :** proposition (v0) — à valider à deux, puis à faire vivre.
> Ce document décrit *comment le code est organisé* et *qui a le droit de décider quoi* en réseau.
> Les règles du jeu, elles, restent dans le GDD.

---

## 1. Les 5 principes à retenir

1. **Le multijoueur n'est pas une feature, c'est la fondation.**
   Tout système qui touche à l'état de la partie (phase, timer, scores, rôles, secrets, résultats d'un mini-jeu) est écrit *dès le départ* en mode « le serveur décide, les clients affichent ». Ajouter le réseau à la fin = tout réécrire.
2. **Le serveur (l'hôte) est la seule source de vérité.**
   Un client ne fait que *demander* (`request_...`). Le serveur valide, applique, puis *annonce* le résultat.
3. **Un client ne reçoit jamais une info qu'il n'a pas le droit de connaître.**
   C'est un jeu de bluff : si un rôle secret est envoyé à tout le monde « mais caché dans l'UI », n'importe qui peut tricher. Les secrets partent en `rpc_id(peer_id, ...)` uniquement.
4. **Un mini-jeu = un dossier autonome** qui respecte un contrat commun (§6). Ajouter un mini-jeu ne doit pas demander de toucher au reste du jeu.
5. **Une feature = un dossier.** La scène, son script, ses ressources et ses tests sont rangés ensemble.

---

## 2. Arborescence proposée

```
res://
├── addons/                  # plugins tiers (GUT, ...) — on n'y touche pas
├── assets/                  # fichiers « bruts » importés, partagés par plusieurs features
│   ├── models/
│   ├── textures/
│   ├── audio/  (sfx/, music/)
│   └── fonts/
├── src/
│   ├── autoload/            # singletons globaux (§4)
│   │   ├── net.gd
│   │   ├── players.gd
│   │   ├── match.gd
│   │   ├── events.gd
│   │   └── settings.gd
│   ├── main/                # scène racine persistante (§3)
│   │   ├── main.tscn
│   │   └── main.gd
│   ├── player/              # personnage FPS réseau
│   │   ├── player.tscn
│   │   ├── player.gd
│   │   └── player_camera.gd
│   ├── interaction/         # composant « appuyer sur E » réutilisable
│   │   ├── interactable.gd
│   │   └── interactor.gd
│   ├── rooms/
│   │   ├── global_room/     # salle globale (hub social)
│   │   └── results_room/    # écran / salle de fin de partie
│   ├── minigames/
│   │   ├── _framework/      # contrat commun : minigame.gd, minigame_definition.gd, minigame_result.gd, registry
│   │   ├── debug_button/    # mini-jeu jetable pour tester la boucle
│   │   └── <nom_du_minijeu>/
│   │       ├── definition.tres
│   │       ├── <nom>.tscn
│   │       └── <nom>.gd
│   └── ui/
│       ├── main_menu/
│       ├── lobby/
│       ├── hud/             # timer, phase, scores, prompt d'interaction
│       └── common/          # thème, boutons, transitions
└── test/                    # tests GUT, même arborescence que src/
    ├── player/test_player.gd
    └── minigames/...
```

**Migration depuis l'existant** (à faire une fois, dans une PR dédiée, avec l'éditeur Godot ouvert pour qu'il mette à jour les chemins) :

| Aujourd'hui | Demain |
| --- | --- |
| `assets/prefab/Player.tscn` + `assets/scripts/player.gd` | `src/player/player.tscn` + `player.gd` |
| `assets/scenes/Main.tscn` | `src/main/main.tscn` (le sol de test part dans une scène de test) |
| `assets/tests/player.test.gd` | `test/player/test_player.gd` |
| `assets/models/player/` | reste dans `assets/models/player/` |

> ⚠️ La CI lance GUT sur `res://test` avec le préfixe `test_`. Aujourd'hui le test est dans `assets/tests/player.test.gd` : **il n'est jamais exécuté en CI** (l'étape affiche « Aucun dossier test/ trouvé »). La CI télécharge aussi Godot **4.6** alors que le projet est en **4.7**.

**Conventions de nommage** (alignées sur le guide de style Godot et `gdlint`) : fichiers et dossiers en `snake_case`, classes en `PascalCase` (`class_name Minigame`), signaux au passé (`phase_changed`, `player_joined`), RPC client→serveur préfixés `request_`.

---

## 3. Les scènes et le flux de navigation

On **ne fait pas** de `get_tree().change_scene_to_file()` une fois en partie : en réseau, changer la scène racine casse les chemins de nœuds sur lesquels reposent les RPC et les `MultiplayerSpawner`. On garde une **scène racine persistante** et on remplace seulement son contenu.

```
Main (Node)                         ← ne change jamais pendant la partie
├── World (Node3D)                  ← la salle courante est instanciée ici
│   └── <GlobalRoom | Minigame | ResultsRoom>
├── WorldSpawner (MultiplayerSpawner, spawn_path = World)
└── UI (CanvasLayer)
    ├── <MainMenu | Lobby | HUD>
    └── Transition (fondu au noir)
```

- Le **serveur** choisit la salle et l'instancie sous `World` ; le `MultiplayerSpawner` la recrée automatiquement chez tous les clients.
- Chaque salle a son propre `Players` + `MultiplayerSpawner` qui fait apparaître un `Player` par joueur connecté. Une salle peut fournir *son* type de joueur (ex. un mini-jeu « assis à une table » n'utilise pas le contrôleur FPS).
- Menu principal et lobby sont de l'UI pure (pas de 3D nécessaire au début).

Flux complet :

```
MainMenu ──Héberger / Rejoindre──▶ Lobby ──(hôte) Lancer──▶ [ partie : machine à états §5 ] ──▶ ResultsRoom ──▶ Lobby
```

---

## 4. Autoloads (singletons)

Peu d'autoloads, chacun avec une seule responsabilité. Règle : **un autoload ne référence jamais une scène précise** ; il émet des signaux, les scènes s'y abonnent.

| Autoload | Rôle | Tourne sur |
| --- | --- | --- |
| `Net` | Héberger / rejoindre / quitter, gère le `MultiplayerPeer` (ENet au début, Steam plus tard — §7), signaux `connected`, `connection_failed`, `server_closed`. Cache le type de transport au reste du jeu. | tous |
| `Players` | Registre des joueurs : `{peer_id: PlayerInfo}` (pseudo, couleur, prêt, score, connecté). Le serveur le modifie, puis le diffuse. Signaux `player_joined`, `player_left`, `player_updated`. | serveur = écrit, clients = lisent |
| `Match` | **Le meneur de jeu** : machine à états de la partie (§5), timers, enchaînement des épreuves, calcul des points. Toute la logique ne s'exécute que si `multiplayer.is_server()`. Les clients reçoivent `phase_changed(phase, data)`. | serveur = décide |
| `Events` | Bus de signaux **locaux** pour découpler l'UI du gameplay (`interaction_prompt_changed`, `toast_requested`…). Pas de réseau ici. | tous |
| `Settings` | Sensibilité souris, volumes, pseudo, dernière IP — sauvegardé dans `user://settings.cfg`. | tous |

`PlayerInfo` est une petite classe (`class_name PlayerInfo extends RefCounted`) avec `to_dict()` / `from_dict()` pour passer dans les RPC (les RPC ne transportent que des types simples : `Dictionary`, `Array`, `int`, `String`…).

---

## 5. Machine à états de la partie (`Match`)

```
            ┌────────────────────────────────────────────────────────────┐
            ▼                                                            │
LOBBY ─▶ INTRO ─▶ ANNOUNCE ─▶ PREP ─▶ MINIGAME_INTRO ─▶ MINIGAME ─▶ ROUND_RESULTS
                  (épreuve     (salle     (règles,        (le mini-jeu   │
                   annoncée)    globale,   « prêt »)       tourne)       │
                               5 min ou                                  │
                               tous prêts)              reste des épreuves ? ─┘
                                                                 │ non
                                                                 ▼
                                                           FINAL_RESULTS ─▶ LOBBY
```

| Phase | Où sont les joueurs | Sortie |
| --- | --- | --- |
| `LOBBY` | menu lobby | l'hôte clique « Lancer » (≥ min joueurs) |
| `INTRO` | salle globale | timer court (cinématique / texte) |
| `ANNOUNCE` | salle globale | timer court, affiche l'épreuve suivante |
| `PREP` | salle globale (libre) | 5 min **ou** tous les joueurs « prêts » |
| `MINIGAME_INTRO` | salle du mini-jeu | timer / tous prêts |
| `MINIGAME` | salle du mini-jeu | le mini-jeu émet `finished(result)` ou timeout (max 20 min) |
| `ROUND_RESULTS` | salle du mini-jeu ou globale | timer court, révélation (« qui a trahi qui ») |
| `FINAL_RESULTS` | salle de fin | l'hôte revient au lobby |

Implémentation conseillée : un simple `enum Phase` + une fonction `_enter_phase(phase)` côté serveur, avec un `match` qui fait le travail de chaque phase. Pas besoin d'un framework de state machine avec un nœud par état tant qu'il y a < 10 phases.

```gdscript
# src/autoload/match.gd (extrait)
enum Phase { LOBBY, INTRO, ANNOUNCE, PREP, MINIGAME_INTRO, MINIGAME, ROUND_RESULTS, FINAL_RESULTS }

signal phase_changed(phase: Phase, data: Dictionary)

var phase: Phase = Phase.LOBBY
var round_index := 0
var rounds: Array[MinigameDefinition] = []

func _enter_phase(new_phase: Phase, data := {}) -> void:
	assert(multiplayer.is_server())
	phase = new_phase
	_announce_phase.rpc(new_phase, data)        # tout le monde, serveur compris
	match new_phase:
		Phase.PREP:
			_start_timer(prep_duration_sec, _on_prep_timeout)
		Phase.MINIGAME:
			_current_minigame.finished.connect(_on_minigame_finished, CONNECT_ONE_SHOT)
			_current_minigame.start()
		# ...

@rpc("authority", "call_local", "reliable")
func _announce_phase(new_phase: Phase, data: Dictionary) -> void:
	phase = new_phase
	phase_changed.emit(new_phase, data)
```

**Timers :** le serveur envoie une *durée* (`"duration": 300`) dans `data`, chaque client fait son compte à rebours local. On n'envoie pas d'heure absolue (les horloges des PC ne sont pas synchronisées). Le serveur reste le seul à déclencher la fin.

**Points :** `points_gagnés = points_du_mini_jeu × multiplicateur[round_index]` (le GDD veut que les dernières épreuves rapportent plus). Les multiplicateurs vivent dans une ressource `MatchConfig` (`short.tres` = 3 épreuves, `long.tres` = 5 épreuves) pour pouvoir équilibrer sans toucher au code.

---

## 6. Contrat d'un mini-jeu

### 6.1 La fiche : `MinigameDefinition` (Resource, un `definition.tres` par mini-jeu)

```gdscript
class_name MinigameDefinition extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var rules_text: String
@export var scene: PackedScene
@export var min_players := 5
@export var max_players := 10
@export var max_duration_sec := 20 * 60
@export var base_points := 10
```

Un `MinigameRegistry` charge au démarrage tous les `res://src/minigames/*/definition.tres`. Ajouter un mini-jeu = créer un dossier, aucune autre modification.

### 6.2 La scène : classe de base `Minigame`

```gdscript
class_name Minigame extends Node3D

## Émis UNIQUEMENT par le serveur quand le mini-jeu est terminé.
signal finished(result: MinigameResult)

var definition: MinigameDefinition
var participants: Array[int] = []   # peer_ids

## Serveur : appelé avant start(). Distribuer rôles / infos secrètes ici (rpc_id).
func setup(p_participants: Array[int], rng_seed: int) -> void:
	participants = p_participants

## Serveur : la partie commence.
func start() -> void:
	pass

## Serveur : un joueur a quitté en cours de route. Le mini-jeu doit pouvoir continuer.
func on_player_left(_peer_id: int) -> void:
	pass

## Serveur : temps max écoulé, on force un résultat.
func force_end() -> MinigameResult:
	return MinigameResult.new()
```

### 6.3 Le résultat : `MinigameResult`

```gdscript
class_name MinigameResult extends RefCounted

var points := {}        # {peer_id: int} — points AVANT multiplicateur
var reveal: Array = []  # lignes de révélation : [{"text": "Alice a trahi Bob", ...}]
```

`Match` ne connaît **que** ce contrat : il instancie `definition.scene`, appelle `setup()` puis `start()`, attend `finished`, applique les points. Il ne sait rien des règles internes.

### 6.4 Outil de dev indispensable

Lancer un mini-jeu directement, sans passer par lobby + salle globale : argument `--minigame=<id>` (via *Débogage › Personnaliser les instances de lancement*) qui démarre l'hôte, attend N joueurs et saute en phase `MINIGAME_INTRO`. Sinon tester un mini-jeu prendra 10 minutes à chaque fois.

---

## 7. Modèle réseau

**API :** le multijoueur haut niveau de Godot 4 (`MultiplayerAPI`, `@rpc`, `MultiplayerSpawner`, `MultiplayerSynchronizer`).

**Topologie :** *listen server* — un joueur héberge (il est serveur **et** joueur, `peer_id = 1`), les autres se connectent à lui. Pas de serveur dédié à payer/maintenir.

**Transport :**
- **Maintenant :** `ENetMultiplayerPeer` — marche en local (plusieurs instances sur le même PC) et en LAN. Sur Internet, il faut ouvrir un port chez l'hôte ou passer par un VPN type Tailscale/ZeroTier : suffisant pour jouer entre amis pendant le dev.
- **Plus tard (à décider, cf. questions) :** Steam (GodotSteam : lobbies, invitations d'amis, relais réseau sans ouvrir de port, voix) — l'autoload `Net` est là pour que ce changement ne touche que lui.

**Qui a l'autorité sur quoi :**

| Donnée | Autorité | Mécanisme |
| --- | --- | --- |
| Position / rotation / animation de *mon* personnage | le client propriétaire | `set_multiplayer_authority(peer_id)` sur le Player + `MultiplayerSynchronizer` |
| Phase, timers, round, scores | serveur | RPC `authority` → tous |
| Registre des joueurs (pseudo, prêt…) | serveur | `Players` : `request_set_ready.rpc_id(1, true)` → le serveur valide → diffuse |
| Règles et état d'un mini-jeu | serveur | RPC + `MultiplayerSynchronizer` dans la scène du mini-jeu |
| Infos secrètes (rôle, carte, indice) | serveur | **`rpc_id(peer_id, ...)` uniquement**, ou filtres de visibilité du `MultiplayerSynchronizer` |
| Objets ramassables, échanges, achats | serveur | le client fait `request_pickup(id)`, le serveur vérifie distance/dispo |

On fait confiance au client pour son déplacement (c'est un jeu entre amis, pas un FPS compétitif) : c'est beaucoup plus simple et sans latence ressentie.

**Conventions RPC :**

```gdscript
# Client → serveur : une DEMANDE. Toujours vérifier l'émetteur.
@rpc("any_peer", "call_remote", "reliable")
func request_set_ready(is_ready: bool) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	Players.set_ready(sender, is_ready)

# Serveur → clients : une ANNONCE.
@rpc("authority", "call_local", "reliable")
func _announce_ready(peer_id: int, is_ready: bool) -> void:
	...
```

**Côté Player** (ce qui change par rapport au `player.gd` actuel) : le nœud s'appelle `str(peer_id)`, les entrées clavier/souris, la capture de la souris et `camera.current = true` ne s'exécutent que si `is_multiplayer_authority()`. Le modèle reste visible pour les autres joueurs, caché seulement pour soi.

---

## 8. Tests et workflow

- **Tests GUT** dans `test/`, fichiers `test_*.gd`. Tester en priorité la logique pure, sans réseau : calcul des points, transitions de la machine à états, règles d'un mini-jeu (`MinigameResult` attendu pour une suite d'actions donnée). Pour ça, garder la logique des règles dans des fonctions qui ne dépendent pas de `multiplayer`.
- **Tester à plusieurs en local :** *Débogage › Personnaliser les instances de lancement* → 3 instances, la 1ʳᵉ avec l'argument `--host`, les autres avec `--join=127.0.0.1`. `Net` lit `OS.get_cmdline_user_args()` et se connecte tout seul.
- **Definition of Done** (déjà dans CONTRIBUTING) : « testé à deux joueurs si la feature touche au réseau » → en pratique, *toutes* les features de gameplay.

---

## 9. Décisions encore ouvertes (impact technique)

| Question | Impact |
| --- | --- |
| Chat vocal **dans le jeu** (proximité, salles isolées) ou Discord à côté ? | Énorme : le vocal de proximité conditionne tout le design de la salle globale et pousse vers Steam. |
| Steam ou pas (sortie Steam, relais, invitations) ? | Choix du transport réseau final. |
| Bluff / vote / élimination : mécaniques **globales** ou propres à certains mini-jeux ? | Si globales, il faut un système commun (vote, élimination, spectateur) dans `Match`. |
| Que fait un joueur éliminé / déconnecté ? | Mode spectateur, reconnexion, gestion des points. |
| Monnaie / objets / bonus de la salle globale | Inventaire, économie, échanges serveur. |
