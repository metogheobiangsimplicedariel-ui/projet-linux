# SECUSCANNER v5.0

Outil d'Audit et de Hardening Automatise pour Linux

SecuScanner est une suite d'outils en Bash concue pour auditer, securiser et durcir (hardening) les systemes Linux. Il est particulierement efficace sur des environnements vulnerables comme Metasploitable 2 pour transformer une "passoire" reseau en un systeme conforme aux standards de securite.

---

## Table des Matieres

1. Architecture
2. Fonctionnalites
3. Installation
4. Guide d'Utilisation
5. Details des Modes de Securisation

---

## Architecture

Le projet suit une structure modulaire pour garantir la robustesse et la facilite de maintenance :

- main.sh : Interface utilisateur et orchestrateur du systeme.
- core/ : Contient functions.sh (moteur de log, calcul des scores et couleurs).
- plugins/ :
  - audit\_\*.sh : Modules de detection des vulnerabilites.
  - hardening.sh : Logique de remediation active (Standard/Nucleaire).
  - hardening_passive.sh : Generateur de plan de conseil (sans modification).
  - backup_restore.sh : Systeme de sauvegarde et de retour arriere.
- reports/ : Historique des audits generes (format .txt horodate).

---

## Fonctionnalites

### Audit Complet

- SSH : Verification du login Root, version du protocole, timeouts, et limites de tentatives.
- Systeme : Analyse des permissions /etc/shadow, conformite du UMASK et hashing des mots de passe.
- Noyau (Kernel) : Verification de l'ASLR, de l'IP Forwarding et des protections ICMP.
- Reseau : Scan des ports ouverts et detection de services critiques (Telnet, R-services).

### Hardening (Securisation)

- Mode Standard : Arret propre des services applicatifs (Apache, MySQL, Samba...).
- Mode Nucleaire : Neutralisation radicale des super-serveurs (xinetd), des partages reseau (NFS/RPC) et des processus orphelins. Seul le port SSH securise reste ouvert.
- Gestion de la Persistance : Desactivation des services au demarrage du systeme via update-rc.d.

---

## Installation

1. Transfert : Envoyez le dossier sur la machine cible (ex: via SSH/SCP).
2. Permissions : Rendez le script principal executable :
   chmod +x main.sh
3. Execution : Lancez l'outil avec les privileges Root :
   sudo ./main.sh

---

## Guide d'Utilisation

Pour un resultat optimal, suivez cette sequence :

1. Backup (Option 7) : Creez toujours un point de restauration avant de modifier le systeme.
2. Audit (Option 1) : Etablissez le diagnostic initial et notez votre score de securite.
3. Plan Passif (Option 9) : Etudiez les recommandations de correction.
4. Action (Option 10.2) : Lancez le Protocole Nucleaire pour verrouiller la machine.
5. Persistance (Option 10.3) : Rendez les modifications permanentes apres redemarrage.
6. Verification : Relancez un audit pour constater l'amelioration du score (Cible : 8/10+).

---

## Securite et Restauration

En cas de besoin de reactiver les services d'origine, utilisez l'Option 8. Le systeme restaurera automatiquement les fichiers de configuration a partir de l'archive creee lors de l'etape de Backup.

---

Developpe pour l'audit de securite et le durcissement systeme.
