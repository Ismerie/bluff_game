# Contributing

## Branches

| Préfixe | Quand l'utiliser |
|---|---|
| `feature/` | Nouvelle fonctionnalité |
| `bugfix/` | Correction de bug |
| `refactor/` | Refactoring sans ajout de feature |
| `design/` | Game design, règles, équilibrage |

Format : `prefixe/[numero-issue]-[description-courte]`

Exemples :
- `feature/12-systeme-bluff`
- `bugfix/34-lobby-crash`

## Commits

Format : `type: description courte`

Exemples :
- `feature: ajout du système de bluff`
- `fix: correction crash lobby`
- `refactor: nettoyage network manager`

## Pull Requests

- Une PR = une issue
- Toujours merger dans `develop`, jamais dans `main`
- Lier l'issue dans la description : `Closes #42`
- L'autre personne doit approuver avant de merger

## Definition of Done

- [ ] Code reviewé par l'autre
- [ ] PR mergée dans `develop`
- [ ] Testé à deux joueurs si la feature touche au réseau
- [ ] Pas de régression sur les scènes existantes

## Branches protégées

- `main` — version stable, merge uniquement depuis `develop`
- `develop` — intégration, merge uniquement via PR