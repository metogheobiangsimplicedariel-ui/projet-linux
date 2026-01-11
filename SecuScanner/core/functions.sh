#!/bin/bash

# --- COULEURS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- VARIABLES GLOBALES ---
PASSED_TESTS=0
TOTAL_TESTS=0
# Le fichier de rapport sera defini par le main.sh
#REPORT_FILE=""

# --- FONCTION D'ECRITURE DANS LE RAPPORT ---
# Cette fonction enleve les codes couleurs ANSI pour que le fichier texte soit propre
write_report() {
    if [ -n "$REPORT_FILE" ]; then
        # sed enlève les codes couleurs (ex: \033[0;31m)
        echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$REPORT_FILE"
    fi
}

# --- FONCTIONS D'AFFICHAGE & LOGGING ---

print_header() {
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}           SECUSCANNER v5.0                  ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    
    # On ecrit aussi dans le fichier
    write_report "============================================="
    write_report "           SECUSCANNER v5.0                  "
    write_report "============================================="
    write_report "Date : $(date)"
    write_report "Machine : $(hostname)"
    write_report "============================================="
}

log_pass() {
    local msg="$1"
    echo -e "${GREEN}[OK] $msg${NC}"
    write_report "[OK] $msg"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

log_fail() {
    local msg="$1"
    echo -e "${RED}[ALERT] $msg${NC}"
    write_report "[ALERT] $msg"
    ((TOTAL_TESTS++))
}

log_info() {
    local msg="$1"
    echo -e "${YELLOW}[INFO] $msg${NC}"
    write_report "[INFO] $msg"
}

# Nouvelle fonction pour les titres de section
log_section() {
    local msg="$1"
    echo ""
    echo -e "${BLUE}[+] $msg${NC}"
    
    write_report ""
    write_report "[+] $msg"
}

# --- FONCTION DE RAPPORT FINAL ---
show_score() {
    echo ""
    echo "============================================="
    echo " RAPPORT FINAL"
    echo "---------------------------------------------"
    
    write_report ""
    write_report "============================================="
    write_report " RAPPORT FINAL"
    write_report "---------------------------------------------"

    if [ $TOTAL_TESTS -eq 0 ]; then
        echo "Aucun test effectue."
        write_report "Aucun test effectue."
    else
        # Calcul note
        note_sur_10=$(( (PASSED_TESTS * 10) / TOTAL_TESTS ))
        
        # Couleur note ecran
        if [ "$note_sur_10" -eq 10 ]; then COLOR=$GREEN
        elif [ "$note_sur_10" -ge 5 ]; then COLOR=$YELLOW
        else COLOR=$RED
        fi

        echo -e "Tests reussis  : $PASSED_TESTS / $TOTAL_TESTS"
        echo "---------------------------------------------"
        echo -e "NOTE DE SECURITE : ${COLOR}${note_sur_10}/10${NC}"
        
        # Ecriture fichier (sans couleur)
        write_report "Tests reussis  : $PASSED_TESTS / $TOTAL_TESTS"
        write_report "---------------------------------------------"
        write_report "NOTE DE SECURITE : ${note_sur_10}/10"

        if [ "$PASSED_TESTS" -eq "$TOTAL_TESTS" ]; then
            echo -e "${GREEN}Felicitations ! Le systeme est securise.${NC}"
            write_report "Felicitations ! Le systeme est securise."
        else
            echo -e "${RED}Attention : Des corrections sont necessaires.${NC}"
            write_report "Attention : Des corrections sont necessaires."
        fi
    fi
    echo "============================================="
    write_report "============================================="
    
    # On indique a l'utilisateur ou est le fichier
    echo -e "${BLUE}Rapport sauvegarde dans : $REPORT_FILE${NC}"
}
