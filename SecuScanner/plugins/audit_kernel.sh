#!/bin/bash

# Test 1 : IP Forwarding (Routage de paquets)
audit_ip_forward() {
    # 0 = Desactive (Securise pour un serveur/client standard)
    # 1 = Active (Necessaire seulement pour les routeurs/gateways)
    val=$(sysctl -n net.ipv4.ip_forward 2>/dev/null)
    
    if [ "$val" -eq 0 ]; then
        log_pass "Kernel : IP Forwarding desactive"
    else
        log_fail "Kernel : IP Forwarding active (Risque : la machine agit comme routeur)"
    fi
}

# Test 2 : ICMP Redirects (Protection MITM)
audit_icmp_redirects() {
    # Accepter les redirects permet a un attaquant de changer vos routes
    val=$(sysctl -n net.ipv4.conf.all.accept_redirects 2>/dev/null)
    
    if [ "$val" -eq 0 ]; then
        log_pass "Kernel : ICMP Redirects refuses (Protection MITM)"
    else
        log_fail "Kernel : ICMP Redirects acceptes"
    fi
}

# Test 3 : TCP SYN Cookies (Protection DoS)
audit_syn_cookies() {
    # Aide a resister aux attaques SYN Flood
    val=$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null)
    
    if [ "$val" -eq 1 ]; then
        log_pass "Kernel : SYN Cookies actives"
    else
        log_fail "Kernel : SYN Cookies desactives (Risque DoS)"
    fi
}

# Test 4 : ASLR (Randomisation Memoire)
audit_aslr() {
    # 0 = Desactive
    # 2 = Randomisation complete (Recommande)
    val=$(sysctl -n kernel.randomize_va_space 2>/dev/null)
    
    if [ "$val" -eq 2 ]; then
        log_pass "Kernel : ASLR active (Niveau 2)"
    else
        log_fail "Kernel : ASLR faible ou desactive ($val)"
    fi
}
