#!/bin/bash

# Chemin du fichier de log
log_file="/var/log/combine_audio.log"
# Chemin pour stocker les profils audio
profiles_file="$HOME/.combine_audio_profiles"

# Fonction pour journaliser les actions
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $log_file
}

# Fonction pour envoyer une notification
notify_user() {
    notify-send "Combine Audio" "$1"
}

# Fonction pour lister les périphériques audio disponibles
get_audio_sinks() {
    pactl list short sinks
}

# Fonction pour créer un périphérique combiné
create_combined() {
    # Lister tous les périphériques audio disponibles et créer des options pour dialog
    sinks=$(get_audio_sinks)
    sink_options=()

    while read -r line; do
        index=$(echo "$line" | awk '{print $1}')
        name=$(echo "$line" | awk '{print $2}')
        sink_options+=("$index" "$name" "off") # Ajoute le nom du périphérique
    done <<< "$sinks"

    # Utiliser dialog pour afficher une liste et permettre la sélection
    choices=$(dialog --checklist "Sélectionnez les périphériques à combiner (ESPACE pour sélectionner)" 15 60 8 "${sink_options[@]}" 2>&1 >/dev/tty)

    if [ -z "$choices" ]; then
        dialog --msgbox "Aucun périphérique sélectionné. Annulation." 10 40
        clear
        return
    fi

    selected_sinks=()
    for choice in $choices; do
        sink=$(echo "$sinks" | awk -v id="$choice" '{if ($1 == id) print $2}')
        selected_sinks+=("$sink")
    done

    # Vérification du nombre de périphériques
    if [ ${#selected_sinks[@]} -lt 2 ]; then
        dialog --msgbox "Vous devez sélectionner au moins deux périphériques." 10 40
        clear
        return
    fi

    # Demander un nom pour le périphérique combiné
    combined_name=$(dialog --inputbox "Entrez un nom pour le périphérique combiné (par défaut: 'combined')" 10 40 2>&1 >/dev/tty)
    if [ -z "$combined_name" ]; then
        combined_name="combined"
    fi

    # Vérifier si le nom existe déjà
    if pactl list modules | grep "$combined_name" > /dev/null; then
        dialog --msgbox "Erreur : un périphérique combiné avec ce nom existe déjà." 10 40
        clear
        return
    fi

    combined_sinks=$(IFS=, ; echo "${selected_sinks[*]}")

    # Créer le périphérique combiné
    pactl load-module module-combine-sink sink_name=$combined_name slaves=$combined_sinks

    log_action "Périphérique combiné créé : $combined_name avec ${combined_sinks[*]}"
    notify_user "Périphérique combiné créé : $combined_name"
    dialog --msgbox "Périphérique combiné '$combined_name' créé avec succès." 10 40
}

# Fonction pour supprimer un périphérique combiné
purge_combined() {
    combined_sinks=$(pactl list short modules | grep module-combine-sink)

    if [ -z "$combined_sinks" ]; then
        dialog --msgbox "Aucun périphérique combiné trouvé." 10 40
        clear
        return
    fi

    combined_list=()
    while read -r line; do
        module_id=$(echo "$line" | awk '{print $1}')
        module_name=$(echo "$line" | awk '{print $2}')
        combined_list+=("$module_id" "$module_name")
    done <<< "$combined_sinks"

    module_to_delete=$(dialog --menu "Sélectionnez le périphérique combiné à supprimer" 15 60 8 "${combined_list[@]}" 2>&1 >/dev/tty)

    if [ -n "$module_to_delete" ]; then
        pactl unload-module "$module_to_delete"
        log_action "Périphérique combiné supprimé : $module_to_delete"
        notify_user "Périphérique combiné supprimé : $module_to_delete"
        dialog --msgbox "Périphérique combiné supprimé avec succès." 10 40
    fi
}

# Fonction pour gérer les profils
manage_profiles() {
    if [ ! -f "$profiles_file" ]; then
        touch "$profiles_file"
    fi

    profiles=$(cat "$profiles_file" | nl)
    if [ -z "$profiles" ]; then
        dialog --msgbox "Aucun profil trouvé." 10 40
        return
    fi

    profile_to_load=$(dialog --menu "Sélectionnez un profil à charger" 15 60 8 $profiles 2>&1 >/dev/tty)
    if [ -n "$profile_to_load" ]; then
        selected_profile=$(sed -n "${profile_to_load}p" "$profiles_file")
        eval "$selected_profile"
        dialog --msgbox "Profil chargé avec succès." 10 40
    fi
}

# Fonction pour sauvegarder un profil
save_profile() {
    combined_name=$(dialog --inputbox "Entrez le nom du profil à sauvegarder" 10 40 2>&1 >/dev/tty)
    echo "pactl load-module module-combine-sink sink_name=$combined_name" >> "$profiles_file"
    dialog --msgbox "Profil '$combined_name' sauvegardé avec succès." 10 40
}

# Fonction pour afficher l'aide
display_help() {
    dialog --msgbox "Instructions d'utilisation :
    - Créer un périphérique combiné : Combine plusieurs périphériques audio en un seul.
    - Supprimer un périphérique combiné : Supprime un périphérique combiné existant.
    - Gérer les profils : Sauvegarde et charge des profils de périphériques combinés." 15 60
}

# Menu principal
while true; do
    action=$(dialog --menu "Gestion des périphériques combinés" 15 60 6 \
    1 "Créer un nouveau périphérique combiné" \
    2 "Supprimer un périphérique combiné" \
    3 "Sauvegarder un profil" \
    4 "Gérer les profils audio" \
    5 "Afficher l'aide" \
    6 "Quitter" 2>&1 >/dev/tty)

    case $action in
        1) create_combined ;;
        2) purge_combined ;;
        3) save_profile ;;
        4) manage_profiles ;;
        5) display_help ;;
        6) clear; exit 0 ;;
        *) clear; exit 0 ;;
    esac
done

