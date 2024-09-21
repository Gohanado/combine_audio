#!/bin/bash

# Chemin du fichier de log
log_file="/var/log/combine_audio.log"
# Chemin pour stocker les profils audio, distinct pour chaque utilisateur
profiles_file="$HOME/.combine_audio_profiles"

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

# Fonction pour lister les périphériques audio disponibles (micros)
get_audio_sources() {
    pactl list short sources | sort
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

# Fonction pour créer un périphérique combiné (micros)
create_combined_mic() {
    sources=$(get_audio_sources)
    source_options=()

    while read -r line; do
        index=$(echo "$line" | awk '{print $1}')
        name=$(echo "$line" | awk '{print $2}')
        source_options+=("$index" "$name" "off")
    done <<< "$sources"

    choices=$(dialog --checklist "Sélectionnez les micros à combiner (ESPACE pour sélectionner)" 15 60 8 "${source_options[@]}" 2>&1 >/dev/tty)

    if [ -z "$choices" ]; then
        dialog --msgbox "Aucun micro sélectionné. Annulation." 10 40
        clear
        return
    fi

    selected_sources=()
    for choice in $choices; do
        source=$(echo "$sources" | awk -v id="$choice" '{if ($1 == id) print $2}')
        selected_sources+=("$source")
    done

    if [ ${#selected_sources[@]} -lt 2 ]; then
        dialog --msgbox "Vous devez sélectionner au moins deux micros." 10 40
        clear
        return
    fi

    while true; do
        combined_name=$(dialog --inputbox "Entrez un nom pour le périphérique combiné de micros (par défaut: 'combined_mic')" 10 40 2>&1 >/dev/tty)
        if [ -z "$combined_name" ]; then
            combined_name="combined_mic"
        fi

        if pactl list modules | grep "$combined_name" > /dev/null; then
            dialog --msgbox "Erreur : un périphérique combiné avec ce nom existe déjà. Réessayez." 10 40
        else
            break
        fi
    done

    combined_sources=$(IFS=, ; echo "${selected_sources[*]}")

    pactl load-module module-combine-source source_name=$combined_name slaves=$combined_sources

    log_action "Micro combiné créé : $combined_name avec ${combined_sources[*]}"
    notify_user "Micro combiné créé : $combined_name"
    dialog --msgbox "Micro combiné '$combined_name' créé avec succès." 10 40
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

# Fonction pour supprimer un périphérique combiné (micros)
purge_combined_mic() {
    combined_sources=$(pactl list short modules | grep module-combine-source)

    if [ -z "$combined_sources" ]; then
        dialog --msgbox "Aucun micro combiné trouvé." 10 40
        clear
        return
    fi

    combined_list=()
    while read -r line; do
        module_id=$(echo "$line" | awk '{print $1}')
        module_name=$(echo "$line" | awk '{print $2}')
        combined_list+=("$module_id" "$module_name")
    done <<< "$combined_sources"

    module_to_delete=$(dialog --menu "Sélectionnez le micro combiné à supprimer" 15 60 8 "${combined_list[@]}" 2>&1 >/dev/tty)

    if [ -n "$module_to_delete" ]; then
        pactl unload-module "$module_to_delete"
        log_action "Micro combiné supprimé : $module_to_delete"
        notify_user "Micro combiné supprimé : $module_to_delete"
        dialog --msgbox "Micro combiné supprimé avec succès." 10 40
    fi
}

# Fonction pour sauvegarder un profil avec métadonnées
save_profile() {
    profile_name=$(dialog --inputbox "Entrez le nom du profil à sauvegarder" 10 40 2>&1 >/dev/tty)
    if [ -z "$profile_name" ]; then
        dialog --msgbox "Le nom du profil ne peut pas être vide." 10 40
        return
    fi

    description=$(dialog --inputbox "Entrez une description pour ce profil (facultatif)" 10 40 2>&1 >/dev/tty)
    profile_file="$HOME/.combine_audio_profiles/$profile_name.profile"

    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')" > "$profile_file"
    echo "Description: $description" >> "$profile_file"
    echo "Configuration:" >> "$profile_file"
    echo "pactl load-module module-combine-sink sink_name=$profile_name" >> "$profile_file"

    dialog --msgbox "Profil '$profile_name' sauvegardé avec succès." 10 40
}

# Fonction pour gérer les profils audio (chargement et suppression)
manage_profiles() {
    if [ ! -d "$HOME/.combine_audio_profiles" ]; then
        mkdir -p "$HOME/.combine_audio_profiles"
    fi

    profiles=$(ls "$HOME/.combine_audio_profiles")
    if [ -z "$profiles" ]; then
        dialog --msgbox "Aucun profil trouvé." 10 40
        return
    fi

    profile_action=$(dialog --menu "Que souhaitez-vous faire ?" 15 60 3 \
    1 "Charger un profil" \
    2 "Supprimer des profils" 2>&1 >/dev/tty)

    case $profile_action in
        1)
            selected_profile=$(dialog --menu "Sélectionnez un profil à charger" 15 60 8 $profiles 2>&1 >/dev/tty)
            if [ -n "$selected_profile" ]; then
                profile_file="$HOME/.combine_audio_profiles/$selected_profile.profile"
                source "$profile_file"
                dialog --msgbox "Profil '$selected_profile' chargé avec succès." 10 40
            fi
            ;;
        2)
            selected_profiles=$(dialog --checklist "Sélectionnez les profils à supprimer (ESPACE pour sélectionner)" 15 60 8 $profiles 2>&1 >/dev/tty)
            if [ -n "$selected_profiles" ]; then
                for profile in $selected_profiles; do
                    rm "$HOME/.combine_audio_profiles/$profile.profile"
                done
                dialog --msgbox "Les profils sélectionnés ont été supprimés." 10 40
            fi
            ;;
        *)
            dialog --msgbox "Action annulée." 10 40
            ;;
    esac
}

# Fonction d'aide dynamique
display_help() {
    dialog --msgbox "Instructions d'utilisation :
    - Créer un périphérique combiné : Combine plusieurs périphériques audio en un seul.
    - Supprimer un périphérique combiné : Supprime un périphérique combiné existant.
    - Gérer les profils : Sauvegarde et charge des profils de périphériques combinés." 15 60
}

# Fonction de mise à jour du script via curl
update_script() {
    dialog --msgbox "Téléchargement de la dernière version du script depuis GitHub..." 10 40
    
    # Utilisation de curl pour télécharger la dernière version du script
    curl -o combine_audio_enhanced.sh https://raw.githubusercontent.com/Gohanado/combine_audio/main/combine_audio_enhanced.sh

    if [ $? -eq 0 ]; then
        chmod +x combine_audio_enhanced.sh
        dialog --msgbox "Mise à jour terminée avec succès." 10 40
    else
        dialog --msgbox "Échec de la mise à jour. Impossible de télécharger le fichier." 10 40
    fi
}

# Sauvegarde automatique à la fermeture
trap save_profile EXIT

# Menu principal
while true; do
    action=$(dialog --menu "Gestion des périphériques combinés" 15 60 8 \
    1 "Créer un nouveau périphérique combiné (Haut-parleurs)" \
    2 "Supprimer un périphérique combiné (Haut-parleurs)" \
    3 "Créer un nouveau micro combiné" \
    4 "Supprimer un micro combiné" \
    5 "Sauvegarder un profil" \
    6 "Gérer les profils audio" \
    7 "Afficher l'aide" \
    8 "Mise à jour du script" \
    9 "Quitter" 2>&1 >/dev/tty)

    case $action in
        1) check_pulseaudio; create_combined ;;
        2) purge_combined ;;
        3) check_pulseaudio; create_combined_mic ;;
        4) purge_combined_mic ;;
        5) save_profile ;;
        6) manage_profiles ;;
        7) display_help ;;
        8) update_script ;;
        9) clear; exit 0 ;;
        *) clear; exit 0 ;;
    esac
done

