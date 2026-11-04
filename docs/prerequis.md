# Atelier « Du CSV au dashboard » : à préparer avant de venir

Compte 30 à 45 minutes, une seule fois, **chez toi** : le Wi-Fi de la salle ne permettra pas à 40 personnes de télécharger plusieurs Go d'images Docker en même temps.

Il te faut un ordinateur portable (macOS, Windows 10/11 ou Linux) avec, à titre indicatif, 8 Go de RAM et 10 Go d'espace disque libre.

## 1. Installer les outils

| Outil | macOS | Windows |
|---|---|---|
| Docker Desktop | [docker.com](https://www.docker.com/products/docker-desktop/), version **Apple Silicon** (M1 à M4) ou **Intel** | D'abord `wsl --install` dans un PowerShell administrateur puis redémarrage, ensuite Docker Desktop avec l'option **Use WSL 2** |
| Git | `xcode-select --install` dans le Terminal | [git-scm.com](https://git-scm.com/download/win), options par défaut |
| VS Code | [code.visualstudio.com](https://code.visualstudio.com) | idem |
| Extension VS Code | **Dev Containers** (éditeur : Microsoft) | idem |

Sous Linux : Docker Engine, Git, VS Code et l'extension Dev Containers.

Lance Docker Desktop et attends que l'icône de la baleine soit immobile.

## 2. Récupérer et ouvrir le projet

```bash
git clone https://github.com/amandippon/edna-formation
cd edna-formation
code .
```

Sous Windows, fais-le de préférence dans un terminal WSL (Ubuntu), dans ton dossier Linux (`~`) : le devcontainer est nettement plus rapide que depuis `C:\`.

Dans VS Code : `Cmd+Shift+P` (macOS) ou `Ctrl+Shift+P` (Windows), puis **Dev Containers: Reopen in Container**. Le premier lancement prend 5 à 10 minutes. Attends le message « ✅ Environnement prêt ! » dans le terminal.

## 3. Télécharger Superset et vérifier

Dans le terminal de VS Code (celui du devcontainer) :

```bash
task superset:up
task doctor
```

**C'est prêt si `task doctor` affiche quatre lignes ✅.** Tu peux aussi ouvrir http://localhost:8089 dans ton navigateur (identifiants `admin` / `admin`). Ensuite :

```bash
task superset:down
```

## Ça ne marche pas ?

- Note le message d'erreur et regarde la section **Dépannage** du [README](../README.md#7-dépannage).
- Sinon, viens dès **18h30** : on règle les installations à l'accueil, avant le début de l'atelier.
- Si ta machine ne peut pas faire tourner Docker, viens quand même : tu feras les exercices avec un voisin.
