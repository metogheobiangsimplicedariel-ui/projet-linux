# Rapport de Projet : Framework Unifié d'Audit, Hardening et Attaque Contrôlée (Red & Blue Team)

**Établissement :** École d'Ingénierie Digitale et d'Intelligence Artificielle (EIDIA) – Université Euromed de Fès  
**Réalisé par :** Enock DJE BI, Simplice Sariel METOGHE OBIANG, Océane YAROU  
**Encadré par :** M. AIRAJ Mohammed  
**Année Universitaire :** 2025–2026  

---

## 1. Introduction et objectifs

Ce projet vise à développer un framework modulaire nommé **SimOck**, écrit en Bash, pour simuler un cycle complet de sécurité sur une cible vulnérable (Metasploitable 2). Il intègre deux visions complémentaires :

- **Mode Scan & Offensive (Red Team)** : identifier et exploiter les failles de sécurité ;
- **Mode Audit & Hardening (Blue Team)** : analyser la configuration et sécuriser le système via un scoring dynamique.

## 2. Architecture modulaire

L'outil repose sur une architecture extensible chargeant dynamiquement des modules :

- **`core/`** : fonctions centrales, journalisation et calcul du score ;
- **`plugins/recon/`** : scripts de scan réseau (Nmap, ARP) ;
- **`plugins/exploit/`** : scripts d'attaque contrôlée (automatisation de Metasploit) ;
- **`plugins/hardening/`** : scripts de correction (Sysctl, SSH, services).

## 3. Module offensif : audit et simulation

Ce module démontre l'impact des vulnérabilités avant toute correction.

- **Reconnaissance** : un scan Nmap sur Metasploitable 2 révèle une surface d'attaque critique avec de nombreux ports ouverts (FTP 21, SSH 22, Telnet 23, HTTP 80, etc.) ainsi qu'une porte dérobée sur le port 1524.
- **Exploitation** : le framework permet de valider les failles, par exemple en exploitant la vulnérabilité `vsftpd 2.3.4` pour obtenir un shell distant avec les privilèges root.

## 4. Module défensif : hardening automatisé

Une fois les failles identifiées, le module **SecuScanner** est déployé pour durcir le système.

### 4.1 Système de scoring dynamique

Le framework génère un score de sécurité en temps réel selon l'équation suivante :

$$
\text{Score} = \frac{\text{Tests réussis}}{\text{Tests totaux}} \times 10
$$

Le score initial mesuré sur la cible était de **3/10**.

### 4.2 Stratégies de renforcement

Le durcissement s'effectue via deux modes :

1. **Mode passif** : le programme suggère des commandes de correction à l'utilisateur sans modifier le système (ex. : désactiver le login root SSH, corriger les permissions de `/etc/shadow`).
2. **Mode nucléaire** : le framework applique directement les commandes de sécurité (neutralisation des super-serveurs, arrêt des services vulnérables, activation de l'ASLR).

## 5. Analyse comparative

L'efficacité du framework est validée par la comparaison avant/après l'application du hardening :

| Métrique                 | État initial (vulnérable)          | État final (durci)                  |
| :----------------------- | :--------------------------------- | :--------------------------------- |
| **Score de sécurité**    | 3/10                               | 9/10                               |
| **Ports ouverts**        | 28 à 35                            | 2 (SSH et FTP)                    |
| **Vulnérabilité vsftpd** | Exploitable (shell root)           | Service inaccessible              |
| **Configuration noyau**  | Défaut (pas d'ASLR)               | Durcie (`sysctl.conf`)            |

## 6. Conclusion

Le projet démontre qu'un passage d'une surface d'attaque de 28 ports à un bastion sécurisé (principalement SSH) est possible grâce à l'automatisation via Bash. L'approche modulaire permet de basculer efficacement entre la vision de l'attaquant et celle de l'auditeur.
