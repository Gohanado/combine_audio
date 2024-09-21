# Combine Audio

**Combine Audio** est un script permettant de combiner plusieurs périphériques audio et micros sur un système Linux utilisant PulseAudio. Il permet à plusieurs utilisateurs d'entendre le même son dans différents casques ou périphériques audio, ou de combiner plusieurs micros pour la capture audio. Le script permet également de sauvegarder et gérer des profils audio personnalisés.

## Fonctionnalités

- Créer des périphériques combinés pour les haut-parleurs
- Créer des périphériques combinés pour les micros
- Supprimer des périphériques combinés existants (haut-parleurs et micros)
- Sauvegarder et charger des profils audio personnalisés
- Mettre à jour automatiquement le script avec la dernière version depuis GitHub

## Prérequis

Avant de commencer, assurez-vous que vous avez installé les dépendances suivantes :

- **PulseAudio** : pour la gestion des périphériques audio.
- **dialog** : pour afficher des interfaces utilisateur simples en ligne de commande.
- **curl** : pour les éventuelles mises à jour du script.

### Commandes d'installation des dépendances (Ubuntu) :

```bash
sudo apt update
sudo apt install pulseaudio dialog curl -y
