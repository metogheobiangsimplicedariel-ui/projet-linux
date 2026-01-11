#!/bin/bash

# Test 1 : Connexion Root (Basique)
audit_ssh_root() {
    if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
        log_pass "SSH : Connexion Root bloquee"
    else
        log_fail "SSH : Root est autorise (PermitRootLogin != no)"
    fi
}

# Test 2 : Protocole (Doit etre 2)
audit_ssh_protocol() {
    # Sur les systemes recents, si la ligne n'existe pas, c'est 2 par defaut.
    # On verifie surtout qu'il n'y a PAS "Protocol 1"
    if grep -q "^Protocol 1" /etc/ssh/sshd_config; then
        log_fail "SSH : Protocole 1 (obsolete) detecte !"
    else
        log_pass "SSH : Protocole securise (v2)"
    fi
}

# Test 3 : Delai d'inactivite (Timeout) - Tres important
audit_ssh_timeout() {
    # On recupere la valeur de ClientAliveInterval
    val=$(grep "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}')
    
    # Si vide ou 0 = Pas de timeout (Mauvais)
    if [ -n "$val" ] && [ "$val" -gt 0 ] && [ "$val" -le 900 ]; then
        log_pass "SSH : Timeout d'inactivite active ($val sec)"
    else
        log_fail "SSH : Aucun timeout d'inactivite (ClientAliveInterval)"
    fi
}

# Test 4 : Tentatives max (Anti Bruteforce)
audit_ssh_max_tries() {
    val=$(grep "^MaxAuthTries" /etc/ssh/sshd_config | awk '{print $2}')
    
    # Recommande : 4 a 6 essais max
    if [ -n "$val" ] && [ "$val" -le 6 ]; then
        log_pass "SSH : Limite d'essais correcte ($val)"
    else
        log_fail "SSH : Limite d'essais trop elevee ou par defaut"
    fi
}

# Test 5 : Mots de passe vides (Critique)
audit_ssh_empty_pass() {
    if grep -q "^PermitEmptyPasswords no" /etc/ssh/sshd_config; then
        log_pass "SSH : Mots de passe vides interdits"
    else
        # Si la ligne n'y est pas, c'est 'no' par defaut sur OpenSSH recent,
        # mais on prefere que ce soit explicite.
        log_info "SSH : Verification PermitEmptyPasswords (absent ou yes)"
    fi
}
