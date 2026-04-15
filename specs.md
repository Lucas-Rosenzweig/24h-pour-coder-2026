# Specifications techniques
Le jeux est un jeux de type "rogue like en 2D"

## Personnage jouable
- Le personnage peut se déplacer dans les 4 directions (haut, bas, gauche, droite)
- Le personnage possède une attaque principale de base qui pourra être altérée par des améliorations
- Le personnage possède un sort qui est vide pour le moment mais qui pourra être selectioner et améliorer
- Le personnage possède un utilitaire qui est vide et qui pourra être selectionnée et echangé par un autre sans amélioration

## Boucle de gameplay 
- Le personnage se déplace dans un donjon
- La génération du donjon pioche dans un pool de pièces prédéfinies (ex: salle avec 4 portes, salle avec 2 portes opposées, salle avec 3 portes, etc.)
- Le donjon est composé de plusieurs étages, chaque étage possède son propre pool de salles prédéfinies
- Un étage est complété lorsque le joueur a vaincu un nombre défini de salles
- Pour dévérouiller la porte qui mène a la pièce suivante, le joueur doit vaincre tous les ennemis présents dans la salle
- Quand on bat un ennemi le joueur gagne de l'argent
- Quand on bat une salle, on droppe un item qui permet de choisir entre une amélioration de l'attaque, du sort ou de l'utilitaire

## Gestion de l'aléatoire de la génération du donjon
- Quand on quitte une salle, la salle suivante est selectionnée aléatoirement parmi les pièces prédéfinies pour cet étage
- Au bout de 4 salles, on arrive dans une salle de shop 
- Après la salle de shop, on arrive dans une salle de boss

## Shop 
- Dans le shop, le joueur peut acheter du heal , un item d'amélioration.