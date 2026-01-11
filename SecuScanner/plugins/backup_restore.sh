#!/bin/bash

# Fonction de sauvegarde globale des configurations
run_backup() {
    clear
    log_section "SAUVEGARDE DES CONFIGURATIONS SYSTEME"
    
    # 1. Creation du dossier de sauvegarde
    BACKUP_DIR="$INSTALL_DIR/backups"
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        echo "Dossier cree : $BACKUP_DIR"
    fi

    # 2. Nom de l'archive avec la date
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    ARCHIVE_NAME="config_backup_${TIMESTAMP}.tar.gz"
    ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

    echo "Creation de l'archive de securite..."
    
    # 3. Creation du Tarball (Archive compressee)
    # On sauvegarde uniquement les fichiers que le Hardening va modifier
    # On utilise 'tar' avec l'option -P (Absolute names) pour garder les chemins /etc/...
    # On redirige les erreurs vers /dev/null au cas ou un fichier n'existe pas
    tar -czPvf "$ARCHIVE_PATH" \
        /etc/ssh/sshd_config \
        /etc/sysctl.conf \
        /etc/login.defs \
        /etc/shadow \
        /etc/passwd 2>/dev/null

    # 4. Verification
    if [ -f "$ARCHIVE_PATH" ]; then
        log_pass "Sauvegarde reussie : $ARCHIVE_NAME"
        echo ""
        echo "Emplacement : $ARCHIVE_PATH"
        echo "----------------------------------------------------"
        echo "POUR RESTAURER EN CAS DE PROBLEME :"
        echo "cd /"
        echo "sudo tar -xPvf $ARCHIVE_PATH"
        echo "----------------------------------------------------"
        
        # On ecrit aussi la procedure de restauration dans le rapport
        write_report "Sauvegarde effectuee : $ARCHIVE_PATH"
        write_report "Commande de restauration : tar -xPvf $ARCHIVE_PATH -C /"
    else
        log_fail "Echec de la creation de l'archive."
    fi
}
run_restore() {
    clear
    log_section "RESTAURATION SYSTEME"
    echo -e "${RED}ATTENTION : Cette action va ecraser les configurations actuelles !${NC}"
    
    BACKUP_DIR="$INSTALL_DIR/backups"
    
    # 1. Verification des fichiers
    # On met les archives .tar.gz dans un tableau
    files=("$BACKUP_DIR"/*.tar.gz)
    
    if [ ! -e "${files[0]}" ]; then
        echo -e "${RED}Aucune sauvegarde trouvee dans $BACKUP_DIR${NC}"
        return
    fi

    # 2. Affichage du menu de selection
    echo "Sauvegardes disponibles :"
    count=1
    for file in "${files[@]}"; do
        filename=$(basename "$file")
        echo "$count. $filename"
        ((count++))
    done
    
    echo "---------------------------------------------"
    read -p "Choisissez le numero de la sauvegarde a restaurer (0 pour annuler) : " choice
    
    if [ "$choice" -eq 0 ]; then
        echo "Annulation."
        return
    fi

    # 3. Validation et Restauration
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#files[@]}" ] && [ "$choice" -gt 0 ]; then
        index=$((choice-1))
        selected_file="${files[$index]}"
        
        echo ""
        echo -e "Restauration de : ${YELLOW}$(basename "$selected_file")${NC}"
        read -p "Etes-vous CERTAIN de vouloir continuer ? (oui/non) : " confirm
        
        if [ "$confirm" == "oui" ]; then
            # -x : eXtract
            # -P : Preserve absolute paths (essentiel car on a sauvegarde /etc/...)
            # -f : File
            # -C / : Change directory to root (pour remettre les fichiers au bon endroit)
            tar -xPvf "$selected_file" -C /
            
            # ... (suite du tar -xPvf ...)
            
            if [ $? -eq 0 ]; then
                log_pass "Restauration terminee avec succes."
                write_report "Restauration effectuee depuis : $(basename "$selected_file")"
                
                echo ""
                echo "-----------------------------------------------------"
                echo -e "${YELLOW}POUR FINALISER LA RESTAURATION :${NC}"
                echo "Les fichiers sont remis en place, mais les services utilisent"
                echo "encore l'ancienne configuration en memoire."
                echo ""
                echo "1. Redemarrer la machine (Recommande - 100% sur)"
                echo "2. Redemarrer uniquement les services (SSH, Inetd, Sysctl)"
                echo "3. Ne rien faire (Manuel)"
                echo "-----------------------------------------------------"
                read -p "Votre choix [1-3] : " post_action
                
                case $post_action in
                    1)
                        echo "Redemarrage du systeme dans 3 secondes..."
                        sleep 3
                        reboot
                        ;;
                    2)
                        log_info "Rechargement des configurations..."
                        
                        # 1. SSH
                        if [ -f /etc/init.d/ssh ]; then
                            /etc/init.d/ssh restart > /dev/null 2>&1
                            log_pass "Service SSH redemarre"
                        elif command -v systemctl &>/dev/null; then
                            systemctl restart ssh
                            log_pass "Service SSH redemarre"
                        fi
                        
                        # 2. Inetd (Pour Metasploitable/Telnet/Backdoor)
                        if [ -f /etc/init.d/inetd ]; then
                            /etc/init.d/inetd restart > /dev/null 2>&1
                            log_pass "Service Inetd redemarre"
                        elif pidof inetd > /dev/null; then
                            kill -HUP $(pidof inetd)
                            log_pass "Service Inetd recharge (HUP)"
                        fi
                        
                        # 3. Sysctl (Kernel)
                        sysctl -p > /dev/null 2>&1
                        log_pass "Parametres noyau recharges"
                        
                        echo ""
                        echo -e "${GREEN}Systeme restaure et services actualises.${NC}"
                        ;;
                    *)
                        echo "Aucune action effectuee. Pensez a redemarrer plus tard."
                        ;;
                esac
                
            else
                log_fail "Erreur critique lors de l'extraction de l'archive."
                write_report "Echec de la restauration."
            fi
        else
            echo "Annulation."
        fi
    else
        echo -e "${RED}Choix invalide.${NC}"
    fi

}
