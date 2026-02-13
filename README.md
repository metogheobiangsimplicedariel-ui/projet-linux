# Rapport de Projet : Framework Unifié d'Audit, Hardening et Attaque Contrôlée (Red & Blue Team)

**Établissement :** École d'Ingénierie Digitale et d'Intelligence Artificielle (EIDIA) - Université Euromed de Fès[cite: 3, 5].  
**Réalisé par :** Enock DJE BI, Simplice Sariel METOGHE OBIANG, Océane YAROU[cite: 8, 9].  
**Encadré par :** M. AIRAJ Mohammed[cite: 11].  
**Année Universitaire :** 2025/2026[cite: 12].

---

## 1. Introduction et Objectifs

Ce projet vise à développer un framework modulaire nommé **SimOck**, écrit en Bash, pour simuler un cycle complet de sécurité sur une cible vulnérable (Metasploitable 2)[cite: 18, 19, 24]. Il intègre deux visions complémentaires :

- **Mode Scan & Offensive (Red Team) :** Identifier et exploiter les failles de sécurité[cite: 21].
- **Mode Audit & Hardening (Blue Team) :** Analyser la configuration et sécuriser le système via un scoring dynamique[cite: 22].

## 2. Architecture Modulaire

L'outil repose sur une architecture extensible chargeant dynamiquement des modules[cite: 24, 26]:

- **core/ :** Fonctions centrales, journalisation et calcul du score[cite: 27].
- **plugins/recon/ :** Scripts de scan réseau (Nmap, ARP)[cite: 28].
- **plugins/exploit/ :** Scripts d'attaque contrôlée (automatisation de Metasploit)[cite: 29].
- **plugins/hardening/ :** Scripts de correction (Sysctl, SSH, Services)[cite: 29].

## 3. Module Offensif : Audit et Simulation

Ce module démontre l'impact des vulnérabilités avant toute correction[cite: 31].

- **Reconnaissance :** Un scan Nmap sur Metasploitable 2 révèle une surface d'attaque critique avec de nombreux ports ouverts (FTP 21, SSH 22, Telnet 23, HTTP 80, etc.) ainsi qu'une porte dérobée sur le port 1524[cite: 45, 46].
- **Exploitation :** Le framework permet de valider les failles, par exemple en exploitant la vulnérabilité `vsftpd 2.3.4` pour obtenir un shell distant avec les privilèges root[cite: 157, 159].

## 4. Module Défensif : Hardening Automatisé

Une fois les failles identifiées, le module **SecuScanner** est déployé pour durcir le système[cite: 170].

### 4.1 Système de Scoring Dynamique

Le framework génère un score de sécurité en temps réel selon l'équation suivante[cite: 172]:
$$Score = \frac{Tests~Réussis}{Tests~Totaux} \times 10$$
Le score initial mesuré sur la cible était de $3/10$[cite: 174].

### 4.2 Stratégies de Renforcement

Le durcissement s'effectue via deux modes :

1. **Mode Passif :** Le programme suggère des commandes de correction à l'utilisateur sans modifier le système (ex: désactiver le login root SSH, corriger les permissions de `/etc/shadow`)[cite: 178, 184, 191].
2. **Mode Nucléaire :** Le framework applique directement les commandes de sécurité (neutralisation des super-serveurs, arrêt des services vulnérables, activation de l'ASLR)[cite: 205, 222, 242].

## 5. Analyse Comparative

L'efficacité du framework est validée par la comparaison avant/après l'application du hardening[cite: 246]:

| Métrique                 | État Initial (Vulnérable)                        | État Final (Durci)                           |
| :----------------------- | :----------------------------------------------- | :------------------------------------------- |
| **Score de Sécurité**    | 3/10 [cite: 248]                     | 9/10 [cite: 248]                 |
| **Ports Ouverts**        | 28 à 35 [cite: 248]                  | 2 (SSH et FTP) [cite: 248]       |
| **Vulnérabilité vsftpd** | Exploitable (Shell Root) [cite: 248] | Service Inaccessible [cite: 248] |
| **Configuration Noyau**  | Défaut (Pas d'ASLR) [cite: 248]      | Durcie (sysctl.conf) [cite: 248] |

## 6. Conclusion

Le projet démontre qu'un passage d'une surface d'attaque de 28 ports à un bastion sécurisé (principalement SSH) est possible grâce à l'automatisation via Bash[cite: 338]. L'approche modulaire permet de basculer efficacement entre la vision de l'attaquant et celle de l'auditeur[cite: 337].
