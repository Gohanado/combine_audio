# Combine Audio

**Combine Audio** est un ensemble de scripts permettant de combiner plusieurs périphériques audio sur un système Linux utilisant PulseAudio ou PipeWire. La version d'origine repose sur `dialog` pour une interface en ligne de commande. Une interface graphique simple basée sur Tkinter est désormais disponible.

## Prérequis

Installez les dépendances suivantes :

- **PulseAudio** ou **PipeWire** pour la gestion audio.
- **dialog** si vous souhaitez utiliser le script en ligne de commande.
- **Python 3** avec Tkinter (généralement installé par défaut) pour l'interface graphique.

### Installation des dépendances (Ubuntu)

```bash
sudo apt update
sudo apt install pulseaudio dialog python3-tk -y
```

## Utilisation

- **Interface graphique :** lancez `python3 combine_audio_gui.py` puis utilisez les boutons pour créer ou supprimer des périphériques combinés (haut‑parleurs ou micros).
- **Ligne de commande :** exécutez `./combine_audio_enhanced.sh` et suivez les instructions textuelles.

Ces scripts permettent de créer des périphériques combinés afin que plusieurs utilisateurs puissent partager les mêmes haut‑parleurs ou micros.
