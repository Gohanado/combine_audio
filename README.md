# Combine Audio

**Combine Audio** est un script permettant de combiner plusieurs périphériques audio sur un système Linux utilisant PulseAudio. Il permet aux utilisateurs de combiner plusieurs haut-parleurs en un seul périphérique virtuel.

## Prérequis

Avant de commencer, assurez-vous que vous avez installé les dépendances suivantes :

- **PulseAudio** : pour la gestion des périphériques audio.
- **dialog** : pour afficher des interfaces utilisateur simples en ligne de commande.

### Commandes d'installation des dépendances (Ubuntu) :

```bash
sudo apt update
sudo apt install pulseaudio dialog -y
