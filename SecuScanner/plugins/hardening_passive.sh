#!/bin/bash

# Fonction utilitaire pour afficher la commande de correction
log_fix() {
    local msg="$1"
    local cmd="$2"
    echo -e "   ${YELLOW}-> CORRECTION SUGGEREE : $msg${NC}"
    echo -e "      Commande : ${BLUE}$cmd${NC}"
    
    write_report "   -> CORRECTION : $msg"
    write_report "      Commande : $cmd"
}

passive_ssh() {
    log_section "Plan de correction SSH"
    CONFIG="/etc/ssh/sshd_config"

    # 1. Root Login
    if grep -q "^PermitRootLogin yes" "$CONFIG" || grep -q "#PermitRootLogin" "$CONFIG"; then
        log_fix "Desactiver le login Root" "sed -i 's/^.*PermitRootLogin.*/PermitRootLogin no/' $CONFIG"
    fi

    # 2. Protocole 1
    if grep -q "^Protocol 1" "$CONFIG"; then
        log_fix "Forcer le protocole 2" "sed -i 's/^Protocol.*/Protocol 2/' $CONFIG"
    fi

    # 3. CORRECTIF : MaxAuthTries (Limite d'essais)
    if ! grep -q "^MaxAuthTries 3" "$CONFIG"; then
        log_fix "Limiter les essais de connexion (3)" "echo 'MaxAuthTries 3' >> $CONFIG"
    fi

    # 4. Timeout
    if ! grep -q "^ClientAliveInterval" "$CONFIG" || grep -q "^ClientAliveInterval 0" "$CONFIG"; then
        log_fix "Activer deconnexion auto (5min)" "echo 'ClientAliveInterval 300' >> $CONFIG"
    fi
}

passive_system() {
    log_section "Plan de correction Systeme"

    # 1. Permissions Shadow
    perms=$(stat -c "%a" /etc/shadow 2>/dev/null)
    if [ "$perms" != "600" ]; then
        log_fix "Corriger permissions shadow (600)" "chmod 600 /etc/shadow"
    fi

    # 2. Umask (Audit)
    if grep -q "^UMASK" /etc/login.defs; then
        val=$(grep "^UMASK" /etc/login.defs | awk '{print $2}')
        if [ "$val" != "027" ]; then
            log_fix "Durcir le UMASK (027)" "sed -i 's/^UMASK.*/UMASK 027/' /etc/login.defs"
        fi
    fi
}

passive_kernel() {
    log_section "Plan de correction Noyau (Sysctl)"
    
    # 1. IP Forwarding
    if [ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" -eq 1 ]; then
        log_fix "Desactiver IP Forwarding" "sysctl -w net.ipv4.ip_forward=0"
    fi

    # 2. CORRECTIF : ASLR (Audit)
    if [ "$(sysctl -n kernel.randomize_va_space 2>/dev/null)" -ne 2 ]; then
        log_fix "Activer ASLR (Niveau 2)" "sysctl -w kernel.randomize_va_space=2"
    fi
}

passive_network() {
    log_section "Plan de correction Reseau (Services)"

    # Suggestion pour le mode nucleaire si trop de ports sont ouverts
    open_ports=$(netstat -tpln | grep "LISTEN" | wc -l)
    if [ "$open_ports" -gt 5 ]; then
        log_fix "Fermer les services inutiles (Mode Nucleaire)" "/etc/init.d/xinetd stop && /etc/init.d/portmap stop"
        log_fix "Tuer les processus suspects" "pkill -9 -f 'ircd|distccd|tomcat|java'"
    fi
}
