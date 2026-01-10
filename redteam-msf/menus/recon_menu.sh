#!/bin/bash

source core/set_target.sh

while true; do
  clear
  echo "--- RECONNAISSANCE ---"
  echo "Cible : $TARGET"
  echo "1) Scan des ports"
  echo "2) Enumération services"
  echo "3) Retour"
  read -p "Choix : " R

  case $R in
    1) bash recon/scan_ports.sh ;;
    2) bash recon/enum_services.sh ;;
    3) break ;;
  esac
done
