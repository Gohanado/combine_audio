# Combine Audio

**Combine Audio** est un script permettant de combiner plusieurs périphériques audio sur un système Linux utilisant PulseAudio. Il permet à plusieurs utilisateurs d'entendre le même son dans différents casques ou périphériques audio.

## Prérequis

Avant de commencer, assurez-vous que vous avez installé les dépendances suivantes :

- **PulseAudio** : pour la gestion des périphériques audio.
- **dialog** : pour afficher des interfaces utilisateur simples en ligne de commande.
- **curl** : pour les éventuelles mises à jour du script.

### Commandes d'installation des dépendances (Ubuntu) :

```bash
sudo apt update
sudo apt install pulseaudio dialog curl -y
