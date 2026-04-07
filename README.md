# 👾 24h pour coder 2026 : TIC-80 & Fennel

Préparez-vous à plonger dans le monde du développement de jeux vidéo sous contraintes matérielles. Ce hackathon mettra à l'épreuve votre créativité, votre logique et votre architecture logicielle.

## 🎯 Le Défi

Votre objectif est de créer un jeu fonctionnel en utilisant **exclusivement** la fantasy console [TIC-80](https://tic80.com/) et le langage **Fennel** (dialecte Lisp). 

**Thème de cette édition :** Libre

---

## 🛠️ 1. Prérequis & Installation

Avant de commencer à coder, assurez-vous que chaque membre de l'équipe a configuré son environnement de développement :

1. **[Télécharger TIC-80](https://tic80.com/create)** (Prenez la dernière version pour votre OS).
2. Ajoutez l'exécutable `tic80` à votre variable d'environnement `PATH` (pour pouvoir le lancer depuis un terminal).
3. **Éditeur de code :** Nous recommandons vivement [VS Code](https://code.visualstudio.com/) pour sa polyvalence.
4. **Extensions VS Code recommandées :**
   - `Fennel` (par *gq* ou *Tangerine*) pour la coloration syntaxique.
   - `Rainbow Brackets` (indispensable pour survivre aux parenthèses Lisp).

---

## 🚀 2. Démarrer le projet (Fork & Clone)

Un seul membre de l'équipe doit effectuer ces premières étapes :

1. Cliquez sur le bouton "Fork" en haut à droite de cette page pour créer votre propre dépôt d'équipe.
2. Clonez votre nouveau dépôt sur votre machine locale.
3. Déposez réguliérement votre travail sur ce repo selon les bonnes pratiques git : [Clean Sheet git](https://training.github.com/downloads/fr/github-git-cheat-sheet.pdf)

---

## 🌲 3. La structure du dépôt GitHub (Template)

```text
hackathon-tic80-template/
├── assets/
│   └── game.tic                 # La cartouche vide générée par TIC-80 (via `new fennel`)
├── src/
│   └── main.fnl                 # Le starter code (la boucle TIC avec un petit affichage)
├── docs/                        # TODO
│   ├── cheatsheet_fennel.md     # Un résumé de la syntaxe
│   └── api_tic80.md             # Les fonctions TIC-80 autorisées/utiles
├── .gitignore                   # Ignore les fichiers OS et IDE
└── README.md                    
```

---

## 💻 4. Workflow

Pour éviter les conflits Git sur les fichiers binaires, **nous séparons le code (Fennel) des assets (TIC-80)**.

Ouvrez un terminal dans VS Code et lancez cette commande :
```bash
tic80 assets/game.tic -code src/main.fnl
```

**Comment travailler en équipe :**
* 📝 **Le Code :** Modifiez `src/main.fnl` dans VS Code, sauvegardez (`Ctrl+S`), puis basculez sur la fenêtre TIC-80 et appuyez sur **`Ctrl+R`**. Le jeu se met à jour en direct !
* 🎨 **Les Assets (Sprites, Map, SFX) :** Ouvrez l'éditeur directement dans TIC-80 (touche `Echap`). Modifiez vos dessins, sauvegardez (`Ctrl+S` dans TIC-80). 
* ⚠️ **ATTENTION SUR GIT :** Vous pouvez coder à plusieurs sur `main.fnl` sans souci. Mais **ne soyez jamais deux à modifier les graphismes/sons dans `game.tic` en même temps**, dite bonjour au conflit Git !

---

## 📚 5. Ressources et Documentation

* **[Cheatsheet Fennel dans ce dépôt](./docs/cheatsheet_fennel.md)** : Pour comprendre les boucles, conditions et variables.
* **[Wiki TIC-80 (API)](https://github.com/nesbox/TIC-80/wiki)** : Pour trouver comment dessiner (`spr`), afficher du texte (`print`), ou lire les inputs (`btn`).
* **[Tutoriel officiel Fennel](https://fennel-lang.org/tutorial)** : Pour les plus curieux (M2 qui veulent pousser l'architecture fonctionnelle).

---

## 🎯 6. Rendu Final :
Vous avez jusqu'au 16 avril 2026 à XXh pour effectuer des commits sur vos repos personnels. Passé ce délai, si vous effectuez un commit, votre équipe peut être disqualifiée.

Votre repo doit contenir :
- Votre code source
* Un fichier README.md présentant votre projet, son principe et des captures d'écran.

Bonne chance à tous, et que le meilleur code l'emporte ! 🚀
