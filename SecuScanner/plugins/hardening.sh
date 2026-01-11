#!/bin/bash

# --- FONCTION DE SAUVEGARDE ---
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak.$(date +%F_%H%M%S)"
        log_info "Sauvegarde creee : ${file}.bak.$(date +%F_%H%M%S)"
    fi
}

# --- 1. HARDENING SSH ---
fix_ssh() {
    log_section "Application du Hardening SSH..."
    CONFIG="/etc/ssh/sshd_config"
    backup_file "$CONFIG"

    # Liste des paramètres à appliquer
    # On gère PermitRootLogin, Protocol, ClientAliveInterval, PermitEmptyPasswords et MaxAuthTries
    params=(
        "PermitRootLogin=no"
        "Protocol=2"
        "ClientAliveInterval=300"
        "PermitEmptyPasswords=no"
        "MaxAuthTries=3"
    )

    for item in "${params[@]}"; do
        key=$(echo "$item" | cut -d= -f1)
        val=$(echo "$item" | cut -d= -f2)
        
        if grep -q "^$key" "$CONFIG"; then
            sed -i "s/^$key.*/$key $val/" "$CONFIG"
        else
            echo "$key $val" >> "$CONFIG"
        fi
    done

    log_pass "SSH : Parametres (Root, V2, Timeout, NoEmpty, Tries) appliques"
    log_info "Note : Redemarrez le service (service ssh restart)"
}

fix_system() {
    log_section "Application du Hardening Systeme..."

    # 1. Permissions Shadow
    if [ -f /etc/shadow ]; then
        chmod 600 /etc/shadow
        log_pass "Permissions : /etc/shadow corrige (600)"
    fi

    # 2. CORRECTIF UMASK 027 (Audit)
    if grep -q "^UMASK" /etc/login.defs; then
        sed -i 's/^UMASK.*/UMASK 027/' /etc/login.defs
    else
        echo "UMASK 027" >> /etc/login.defs
    fi
    log_pass "Systeme : UMASK regle sur 027"
}

# --- 3. HARDENING KERNEL (SYSCTL) ---
fix_kernel() {
    log_section "Application du Hardening Noyau..."
    SYSCTL_CONF="/etc/sysctl.conf"
    backup_file "$SYSCTL_CONF"

    # Liste complète incluant l'ASLR pour corriger l'audit
    settings=(
        "net.ipv4.ip_forward=0"
        "net.ipv4.conf.all.accept_redirects=0"
        "net.ipv4.tcp_syncookies=1"
        "net.ipv4.conf.all.log_martians=1"
        "kernel.randomize_va_space=2"
    )

    for setting in "${settings[@]}"; do
        key=$(echo "$setting" | cut -d= -f1)
        val=$(echo "$setting" | cut -d= -f2)
        
        # Application immédiate
        sysctl -w "$key=$val" > /dev/null 2>&1
        
        # Persistance
        if grep -q "^$key" "$SYSCTL_CONF"; then
            sed -i "s/^$key.*/$key=$val/" "$SYSCTL_CONF"
        else
            echo "$key=$val" >> "$SYSCTL_CONF"
        fi
        log_pass "Kernel : $key regle sur $val"
    done
    
    sysctl -p > /dev/null 2>&1
    log_info "Parametres noyau recharges."
}
# --- 4. HARDENING SERVICES (MODE STANDARD) ---
fix_services_standard() {
    log_section "Hardening Services - Mode STANDARD"
    # On ne coupe que les services les plus critiques
    services_std=("apache2" "mysql" "samba" "vsftpd" "postgresql-8.3" "tomcat5.5")
    for svc in "${services_std[@]}"; do
        if [ -f "/etc/init.d/$svc" ]; then
            /etc/init.d/$svc stop > /dev/null 2>&1
            log_pass "Service $svc arrete"
        fi
    done
}

# --- 5. HARDENING SERVICES (MODE NUCLEAIRE) ---
fix_services_nuclear() {
    log_section "Hardening Services - Mode NUCLEAIRE"
    
    # 1. Arret des super-serveurs (Xinetd/Inetd)
    for daemon in "inetd" "xinetd" "openbsd-inetd"; do
        if [ -f "/etc/init.d/$daemon" ]; then
            /etc/init.d/$daemon stop > /dev/null 2>&1
            log_pass "Super-serveur $daemon neutralise"
        fi
    done

    # 2. Arret de TOUS les services connus
    services_all=("apache2" "mysql" "samba" "postgresql-8.3" "tomcat5.5" "vsftpd" "postfix" "bind9")
    for svc in "${services_all[@]}"; do
        if [ -f "/etc/init.d/$svc" ]; then
            /etc/init.d/$svc stop > /dev/null 2>&1
            log_pass "Service $svc arrete"
        fi
    done

    # C. Arret du RPC/NFS (Ports 111 et 2049)
    log_info "Fermeture des partages reseau (NFS/RPC)..."
    [ -f "/etc/init.d/nfs-common" ] && /etc/init.d/nfs-common stop > /dev/null 2>&1
    [ -f "/etc/init.d/nfs-kernel-server" ] && /etc/init.d/nfs-kernel-server stop > /dev/null 2>&1
    
    if [ -f "/etc/init.d/portmap" ]; then
        /etc/init.d/portmap stop > /dev/null 2>&1
        log_pass "Portmap (RPC) et NFS arretes"
    fi

    # 4. Elimination des processus sans scripts (IRC, Distccd, VNC)
    # J'ai ajoute le -9 pour forcer l'arret de Tomcat/Java qui resiste souvent
    pkill -9 -f "tomcat|java|ircd|distccd|rmiregistry|vnc|ruby"
    log_pass "Processus zombies neutralises"
}
