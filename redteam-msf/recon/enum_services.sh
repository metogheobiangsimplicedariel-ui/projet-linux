nmap -sV -sC $TARGET | tee -a reports/redteam.txt
read -p "Entrée pour continuer..."
