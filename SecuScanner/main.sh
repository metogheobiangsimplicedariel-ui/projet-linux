#!/bin/bash

# =================================================================
#  SECUSCANNER v2.0 - Outil d'Audit et de Hardening pour Linux
# =================================================================

# --- 1. CONFIGURATION INITIALE ---
INSTALL_DIR=$(dirname "$(readlink -f "$0")")

# Initialisation du système de rapport
REPORT_DIR="$INSTALL_DIR/reports"
mkdir -p "$REPORT_DIR"

# Nom du fichier de rapport unique pour cette session
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
export REPORT_FILE="$REPORT_DIR/audit_${TIMESTAMP}.txt"

# Verification des droits root
if [ "$EUID" -ne 0 ]; then
  echo "Erreur : Ce script doit etre lance avec sudo ou en root."
  exit 1
fi

# --- 2. CHARGEMENT DES MODULES ---

# Chargement du coeur (Fonctions de log, couleurs, scores)
if [ -f "$INSTALL_DIR/core/functions.sh" ]; then
    source "$INSTALL_DIR/core/functions.sh"
else
    echo "Erreur critique : core/functions.sh introuvable."
    exit 1
fi

# Chargement automatique de tous les plugins presents
for plugin in "$INSTALL_DIR/plugins/"*.sh; do
    if [ -f "$plugin" ]; then
        source "$plugin"
    fi
done

# --- 3. FONCTIONS WRAPPERS (LOGIQUE D'EXECUTION) ---

pause() {
    echo ""
    read -p "Appuyez sur Entree pour revenir au menu..."
}

# Wrappers d'Audit (SSH, Systeme, Kernel, Reseau)
run_ssh_audit() {
    log_section "Analyse du service SSH..."
    command -v audit_ssh_root &> /dev/null && { audit_ssh_root; audit_ssh_protocol; audit_ssh_timeout; audit_ssh_max_tries; audit_ssh_empty_pass; } || log_fail "Plugin SSH non charge."
}

run_system_audit() {
    log_section "Analyse du Systeme..."
    command -v audit_uid_zero &> /dev/null && { audit_shadow_perms; audit_uid_zero; audit_pass_hashing; audit_umask; audit_empty_hashes; } || log_fail "Plugin Systeme non charge."
}

run_kernel_audit() {
    log_section "Analyse Parametres Noyau (Sysctl)..."
    command -v audit_ip_forward &> /dev/null && { audit_ip_forward; audit_icmp_redirects; audit_syn_cookies; audit_aslr; } || log_fail "Plugin Kernel non charge."
}

run_network_audit() {
    log_section "Analyse Reseau..."
    command -v audit_telnet &> /dev/null && { audit_telnet; audit_backdoor_1524; audit_listening_ports; } || log_fail "Plugin Reseau non charge."
}

run_passive_hardening() {
    # On vérifie si les fonctions du plugin plugins/hardening_passive.sh sont chargées
    if command -v passive_ssh &> /dev/null; then
        clear
        log_section "GENERATION DU PLAN DE REMEDIATION (PASSIF)"
        echo "Analyse des defauts et generation des commandes correctives..."
        echo "Note : Aucune modification ne sera effectuee sur le systeme."
        echo "----------------------------------------------------"
        
        # Appel des fonctions contenues dans plugins/hardening_passive.sh
        passive_ssh      # Conseils SSH (MaxAuthTries, Root, etc.)
        passive_system   # Conseils Système (UMASK, Shadow)
        passive_kernel   # Conseils Noyau (ASLR, Forwarding)
        passive_network  # Conseils Réseau (Nettoyage des ports/Processus)
        
        echo ""
        echo "----------------------------------------------------"
        echo "Termine. Vous pouvez copier ces commandes pour un hardening manuel."
    else
        echo -e "${RED}Erreur : Plugin de hardening passif non charge.${NC}"
        echo "Assurez-vous que le fichier plugins/hardening_passive.sh existe."
    fi
}

run_full_audit() {
    PASSED_TESTS=0; TOTAL_TESTS=0
    print_header
    run_ssh_audit; run_system_audit; run_kernel_audit; run_network_audit
    show_score
}

view_reports() {
    clear
    log_section "Historique des Rapports d'Audit"
    files=("$REPORT_DIR"/*.txt)
    [ ! -e "${files[0]}" ] && { echo -e "${RED}Aucun rapport trouve.${NC}"; return; }
    
    count=1
    for file in "${files[@]}"; do echo "$count. $(basename "$file")"; ((count++)); done
    
    read -p "Numero du rapport (0 pour retour) : " choice
    if [ "$choice" -gt 0 ] && [ "$choice" -le "${#files[@]}" ] 2>/dev/null; then
        clear; cat "${files[$((choice-1))]}"
    fi
}

# --- 4. GESTION DU HARDENING (SOUS-MENU) ---

show_hardening_menu() {
    clear
    echo -e "${RED}=============================================${NC}"
    echo -e "${RED}           MENU DE SECURISATION              ${NC}"
    echo -e "${RED}=============================================${NC}"
    echo "1. Mode STANDARD (Services Web/SQL/Samba)"
    echo "2. Mode NUCLEAIRE (Ferme TOUT sauf SSH)"
    echo "3. DESACTIVER LA PERSISTANCE (Interdit le reboot des services)"
    echo "4. RETOUR A LA NORMALE (Restauration Backup)"
    echo "---------------------------------------------"
    echo "0. Retour au menu principal"
    echo "---------------------------------------------"
    read -p "Votre choix : " h_choice

    case $h_choice in
        1)
            print_header
            fix_ssh; fix_system; fix_kernel; fix_services_standard
            show_score; pause ;;
        2)
            echo -e "${RED}!!! ACTIVATION DU PROTOCOLE NUCLEAIRE !!!${NC}"
            sleep 1; print_header
            fix_ssh; fix_system; fix_kernel; fix_services_nuclear
            show_score; pause ;;
        3)
            log_section "Désactivation du démarrage automatique..."
            # On boucle sur tous les services connus pour les désactiver au boot
            for svc in apache2 mysql samba vsftpd postgresql-8.3 tomcat5.5 bind9 xinetd inetd; do
                if [ -f "/etc/init.d/$svc" ]; then
                    update-rc.d -f "$svc" remove > /dev/null 2>&1
                    log_pass "Persistance retiree pour : $svc"
                fi
            done
            pause ;;
        4) run_restore; pause ;;
        *) return ;;
    esac
}

# --- 5. MENU PRINCIPAL ---

show_menu() {
    clear
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}           SECUSCANNER - MENU PRINCIPAL      ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo "Machine cible : $(hostname)"
    echo "Date          : $(date +%Y-%m-%d)"
    echo "Rapport actuel: $(basename "$REPORT_FILE")"
    echo "---------------------------------------------"
    echo "1. Lancer un Audit COMPLET"
    echo "2. Audit SSH uniquement"
    echo "3. Audit Systeme/Utilisateurs"
    echo "4. Audit Reseau (Ports)"
    echo "5. Audit Noyau (Sysctl)"
    echo "6. Voir l'historique des rapports"
    echo "---------------------------------------------"
    echo "7. CREER UN POINT DE RESTAURATION (BACKUP)"
    echo "8. RESTAURER UNE SAUVEGARDE"
    echo "---------------------------------------------"
    echo "9. Generer un plan de correction (Passif)"
    echo -e "${RED}10. MENU DE SECURISATION (ACTIF)${NC}"
    echo "---------------------------------------------"
    echo "0. Quitter"
}

# --- 6. BOUCLE D'EXECUTION ---

while true; do
    show_menu
    read -p "Votre choix [0-10] : " choice
    case $choice in
        1) run_full_audit; pause ;;
        2) print_header; PASSED_TESTS=0; TOTAL_TESTS=0; run_ssh_audit; show_score; pause ;;
        3) print_header; PASSED_TESTS=0; TOTAL_TESTS=0; run_system_audit; show_score; pause ;;
        4) print_header; PASSED_TESTS=0; TOTAL_TESTS=0; run_network_audit; show_score; pause ;;
        5) print_header; PASSED_TESTS=0; TOTAL_TESTS=0; run_kernel_audit; show_score; pause ;;
        6) view_reports; pause ;;
        7) run_backup; pause ;;
        8) run_restore; pause ;;
        9) run_passive_hardening; pause ;;
        10) show_hardening_menu ;;
        0) exit 0 ;;
        *) echo -e "${RED}Choix invalide.${NC}"; sleep 1 ;;
    esac
done
