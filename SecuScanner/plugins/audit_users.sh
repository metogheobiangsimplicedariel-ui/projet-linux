#!/bin/bash

# Test 1 : UID 0
audit_uid_zero() {
    found=$(awk -F: '$3 == 0 && $1 != "root" {print $1}' /etc/passwd)
    if [ -z "$found" ]; then
        log_pass "Systeme : Aucun utilisateur UID 0 suspect"
    else
        log_fail "ALERTE : Utilisateur UID 0 cache : $found"
    fi
}

# Test 2 : Droits Shadow
audit_shadow_perms() {
    perms=$(stat -c "%a" /etc/shadow)
    if [ "$perms" -eq 600 ] || [ "$perms" -eq 640 ]; then
        log_pass "Fichiers : /etc/shadow est protege ($perms)"
    else
        log_fail "Fichiers : /etc/shadow trop permissif ($perms)"
    fi
}

# Test 3 : Hachage des mots de passe (SHA512)
audit_pass_hashing() {
    # On cherche dans login.defs
    if grep -q "^ENCRYPT_METHOD SHA512" /etc/login.defs; then
        log_pass "Systeme : Hachage fort active (SHA512)"
    else
        log_fail "Systeme : Methode de hachage faible ou inconnue"
    fi
}

# Test 4 : Umask (Droits par defaut)
# 027 ou 077 est recommande pour les serveurs
audit_umask() {
    val=$(grep "^UMASK" /etc/login.defs | grep -v "^#" | awk '{print $2}')
    
    if [ "$val" == "027" ] || [ "$val" == "077" ]; then
        log_pass "Systeme : UMASK par defaut securise ($val)"
    else
        log_fail "Systeme : UMASK par defaut trop large ($val)"
    fi
}

# Test 5 : Comptes sans mot de passe
audit_empty_hashes() {
    # Cherche les champs vides dans shadow
    empty_accts=$(awk -F: '($2 == "" ) {print $1}' /etc/shadow)
    
    if [ -z "$empty_accts" ]; then
        log_pass "Comptes : Aucun compte sans mot de passe"
    else
        log_fail "ALERTE : Comptes sans mot de passe : $empty_accts"
    fi
}
