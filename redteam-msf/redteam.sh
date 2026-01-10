#!/bin/bash

# ===== COULEURS =====
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
PINK="\e[35m"
RESET="\e[0m"
BOLD="\e[1m"

# ===== BANNIÈRE SimOck =====
banner() {
echo -e "${RED}${BOLD}
██████╗ ███████╗██████╗     ████████╗███████╗ █████╗ ███╗   ███╗
██╔══██╗██╔════╝██╔══██╗    ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║
██████╔╝█████╗  ██║  ██║       ██║   █████╗  ███████║██╔████╔██║
██╔══██╗██╔══╝  ██║  ██║       ██║   ██╔══╝  ██╔══██║██║╚██╔╝██║
██║  ██║███████╗██████╔╝       ██║   ███████╗██║  ██║██║ ╚═╝ ██║
╚═╝  ╚═╝╚══════╝╚═════╝        ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
${RESET}"
echo -e "${PINK}${BOLD}                SimOck Security Framework${RESET}\n"
}

# ===== MENU PRINCIPAL =====
while true; do
  clear
  banner
  echo -e "${BLUE}===== SimOck (ATTACK POUR COMPRENDRE) =====${RESET}"
  echo -e "${GREEN}1) Reconnaissance${RESET}"
  echo -e "${GREEN}2) Exploitation${RESET}"
  echo -e "${RED}3) Quitter${RESET}"
  echo -e "${BLUE}=========================================${RESET}"
  read -p "$(echo -e ${PINK}Choix : ${RESET})" CHOICE

  case $CHOICE in
    1) bash menus/recon_menu.sh ;;
    2) bash menus/exploit_menu.sh ;;
    3) echo -e "\n${RED}[+] Fin de session SimOck 👋${RESET}"; exit ;;
    *) echo -e "${RED}[!] Choix invalide${RESET}"; sleep 1 ;;
  esac
done
