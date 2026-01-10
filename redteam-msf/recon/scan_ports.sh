nmap -p- -T4 $TARGET | tee -a reports/redteam.txt
read -p "Entrée pour continuer..."
