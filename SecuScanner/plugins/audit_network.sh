#!/bin/bash

# --- CORRECTION DU PATH POUR METASPLOITABLE ---
# On force l'ajout des dossiers systeme (/sbin) au chemin de recherche
# C'est indispensable pour que 'netstat' soit trouve via sudo
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin

# --- DETECTION AUTOMATIQUE DE L'OUTIL ---
NET_CMD=""
COL_PORT=""

# 1. On essaie 'ss' (Linux moderne - Debian/Kali/Ubuntu recent)
if command -v ss >/dev/null 2>&1; then
    NET_CMD="ss -tuln"
    # ss affiche le port local en colonne 5
    COL_PORT=5

# 2. On essaie 'netstat' (Linux ancien - Metasploitable/CentOS vieux)
elif command -v netstat >/dev/null 2>&1; then
    NET_CMD="netstat -tuln"
    # netstat affiche le port local en colonne 4
    COL_PORT=4

else
    echo "ERREUR : Impossible de trouver 'ss' ou 'netstat' dans le PATH."
    echo "PATH actuel : $PATH"
    return
fi

# Test 1 : Detection de Telnet (Port 23)
audit_telnet() {
    # On cherche ":23 " dans la sortie de la commande
    if $NET_CMD | grep -q ":23 "; then
        log_fail "ALERTE : Service Telnet detecte (Port 23) - Non chiffre !"
    else
        log_pass "RESEAU : Pas de Telnet detecte"
    fi
}

# Test 2 : Backdoor Metasploitable (Port 1524)
audit_backdoor_1524() {
    if $NET_CMD | grep -q ":1524 "; then
        log_fail "ALERTE CRITIQUE : Backdoor Ingreslock detectee (Port 1524)"
    else
        log_pass "RESEAU : Port 1524 ferme"
    fi
}

# Test 3 : Inventaire complet des ports et analyse de surface
audit_listening_ports() {
    echo ""
    log_info "Inventaire des ports ouverts (Commande : $(echo $NET_CMD | awk '{print $1}'))"
    
    # CORRECTION MAJEURE :
    # On filtre les lignes commencant par 'tcp' ou 'udp'.
    # C'est beaucoup plus fiable sur les vieux Linux que de chercher "LISTEN".
    raw_ports=$($NET_CMD | grep -E "^(tcp|udp)")
    
    if [ -z "$raw_ports" ]; then
        echo "Aucun port detecte (Erreur technique ou aucun service actif)"
        count=0
    else
        echo "-------------------------------------------------"
        echo -e "${BLUE}PROTO   ADRESSE LOCAL:PORT${NC}"
        echo "-------------------------------------------------"
        
        # Affichage propre via AWK (alignement des colonnes)
        echo "$raw_ports" | awk -v col="$COL_PORT" '{printf "%-7s %s\n", $1, $col}'
        echo "-------------------------------------------------"
        
        # On compte le nombre de lignes (donc de ports)
        count=$(echo "$raw_ports" | wc -l)
    fi

    # VERDICT ET SCORING
    # Si plus de 10 ports ouverts -> Echec (Trop de surface d'attaque)
    if [ "$count" -gt 10 ]; then
        log_fail "RESEAU : Surface d'attaque elevee ($count ports ouverts)"
    elif [ "$count" -eq 0 ]; then
        log_info "RESEAU : Impossible de compter les ports (Erreur technique possible)"
    else
        log_pass "RESEAU : Surface d'attaque raisonnable ($count ports ouverts)"
    fi
}
