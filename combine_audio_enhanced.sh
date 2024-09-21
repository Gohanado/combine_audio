#!/bin/bash

# Chemin du fichier de log
log_file="/var/log/combine_audio.log"

# Fonction pour journaliser les actions
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $log_file
}

# Vérifier si PulseAudio est actif
check_pulseaudio() {
    if ! pactl info > /dev/null 2>&1; then
        dialog --msgbox "PulseAudio n'est pas actif. Veuillez le démarrer avant de continuer." 10 40
        exit 1
    fi
}

# Fonction pour envoyer une notification
notify_user() {
    notify-send "Combine Audio" "$1"
}

# Fonction pour lister les périphériques audio disponibles (haut-parleurs)
get_audio_sinks() {
    pactl list short sinks | sort
}

# Fonction pour créer un périphérique combiné (haut-parleurs)
create_combined() {
    sinks=$(get_audio_sinks)
    sink_options=()

    while read -r line; do
        index=$(echo "$line" | awk '{print $1}')
        name=$(echo "$line" | awk '{print $2}')
        sink_options+=("$index" "$name" "off")
    done <<< "$sinks"

    choices=$(dialog --checklist "Sélectionnez les haut-parleurs à combiner (ESPACE pour sélectionner)" 15 60 8 "${sink_options[@]}" 2>&1 >/dev/tty)

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

    if [ ${#selected_sinks[@]} -lt 2 ]; then
        dialog --msgbox "Vous devez sélectionner au moins deux haut-parleurs." 10 40
        clear
        return
    fi

    while true; do
        combined_name=$(dialog --inputbox "Entrez un nom pour le périphérique combiné (par défaut: 'combined')" 10 40 2>&1 >/dev/tty)
        if [ -z "$combined_name" ]; then
            combined_name="combined"
        fi

        if pactl list modules | grep "$combined_name" > /dev/null; then
            dialog --msgbox "Erreur : un périphérique combiné avec ce nom existe déjà. Réessayez." 10 40
        else
            break
        fi
    done

    combined_sinks=$(IFS=, ; echo "${selected_sinks[*]}")

    pactl load-module module-combine-sink sink_name=$combined_name slaves=$combined_sinks

    log_action "Périphérique combiné créé : $combined_name avec ${combined_sinks[*]}"
    notify_user "Périphérique combiné créé : $combined_name"
    dialog --msgbox "Périphérique combiné '$combined_name' créé avec succès." 10 40
}

# Fonction pour supprimer un périphérique combiné (haut-parleurs)
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
        module_name=$(echo "$line" | grep -oP "(?<=name=)[^,]+")
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

# Menu principal
while true; do
    action=$(dialog --menu "Gestion des périphériques combinés" 15 60 4 \
    1 "Créer un nouveau périphérique combiné (Haut-parleurs)" \
    2 "Supprimer un périphérique combiné (Haut-parleurs)" \
    3 "Quitter" 2>&1 >/dev/tty)

    case $action in
        1) check_pulseaudio; create_combined ;;
        2) purge_combined ;;
        3) clear; exit 0 ;;
        *) clear; exit 0 ;;
    esac
done
