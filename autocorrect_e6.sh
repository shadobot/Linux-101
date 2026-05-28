#!/bin/bash
# ============================================================
#  SCRIPT D'AUTO-CORRECTION — ÉPREUVE BLANC E6 BTS SIO SISR
#  StadiumCompany — Infrastructure HA + GLPI + Active Directory
# ============================================================
# Usage : sudo bash autocorrect_e6.sh [IP_HAPROXY] [IP_GLPI] [IP_AD]
# Exemple : sudo bash autocorrect_e6.sh 172.20.0.10 172.20.0.15 172.20.0.20
# ============================================================

HAPROXY_IP=${1:-172.20.0.10}
GLPI_IP=${2:-172.20.0.15}
AD_IP=${3:-172.20.0.20}
SCORE=0
MAX=20
RAPPORT="/tmp/rapport_e6_$(date +%Y%m%d_%H%M%S).txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "$1" | tee -a "$RAPPORT"; }
ok()  { log "${GREEN}[OK  +${2}pt(s)]${NC} $1"; SCORE=$((SCORE + $2)); }
fail(){ log "${RED}[ECHEC     ]${NC} $1"; }
warn(){ log "${YELLOW}[TEST...  ]${NC} $1"; }
hdr() { log "\n${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; log "${BLUE}${BOLD}  $1${NC}"; log "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

log "╔══════════════════════════════════════════════════════╗"
log "║  SCRIPT AUTO-CORRECTION — ÉPREUVE BLANC E6           ║"
log "║  BTS SIO SISR — StadiumCompany                       ║"
log "║  $(date '+%d/%m/%Y %H:%M:%S')                              ║"
log "╚══════════════════════════════════════════════════════╝"
log ""
log "  HAProxy IP : $HAPROXY_IP"
log "  GLPI IP    : $GLPI_IP"
log "  AD IP      : $AD_IP"

# ─────────────────────────────────────────────────────────
hdr "PARTIE A — HAProxy (7 points)"
# ─────────────────────────────────────────────────────────

# A1 — Service actif (1pt)
warn "A1 — Service HAProxy actif sur $HAPROXY_IP..."
HAPROXY_STATUS=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes root@$HAPROXY_IP \
  "systemctl is-active haproxy 2>/dev/null && systemctl is-enabled haproxy 2>/dev/null" 2>/dev/null)
if echo "$HAPROXY_STATUS" | grep -q "^active"; then
  ok "Service HAProxy actif (running)" 1
else
  fail "Service HAProxy non actif ou VM non joignable en SSH root@$HAPROXY_IP"
fi

# A2 — Config haproxy.cfg (3pts)
warn "A2 — Analyse /etc/haproxy/haproxy.cfg..."
CFG=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes root@$HAPROXY_IP \
  "cat /etc/haproxy/haproxy.cfg 2>/dev/null" 2>/dev/null)
SCORE_A2=0

if echo "$CFG" | grep -qi "frontend_stadium"; then
  log "  ${GREEN}✓${NC} frontend nommé 'frontend_stadium' trouvé"; SCORE_A2=$((SCORE_A2+1))
else
  log "  ${RED}✗${NC} frontend 'frontend_stadium' absent"
fi
if echo "$CFG" | grep -qi "backend_stadium"; then
  log "  ${GREEN}✓${NC} backend nommé 'backend_stadium' trouvé"; SCORE_A2=$((SCORE_A2+1))
else
  log "  ${RED}✗${NC} backend 'backend_stadium' absent"
fi
if echo "$CFG" | grep -qi "balance.*round.?robin"; then
  log "  ${GREEN}✓${NC} algorithme roundrobin configuré"; SCORE_A2=$((SCORE_A2+1))
else
  log "  ${RED}✗${NC} algorithme roundrobin absent ou mal orthographié"
fi

if   [ $SCORE_A2 -eq 3 ]; then ok "Configuration haproxy.cfg complète (3/3 critères)" 3
elif [ $SCORE_A2 -eq 2 ]; then ok "Configuration haproxy.cfg partielle (2/3 critères)" 2
elif [ $SCORE_A2 -eq 1 ]; then ok "Configuration haproxy.cfg partielle (1/3 critères)" 1
else fail "Configuration haproxy.cfg incorrecte ou fichier inaccessible"; fi

# A3 — Load balancing fonctionnel (2pts)
warn "A3 — Test load balancing HTTP et page de statistiques..."
SCORE_A3=0
HTTP_RESP=$(curl -s --max-time 8 "http://$HAPROXY_IP/" 2>/dev/null)
if echo "$HTTP_RESP" | grep -qi "grill\|html\|body"; then
  log "  ${GREEN}✓${NC} Site web accessible via HAProxy (réponse HTTP reçue)"; SCORE_A3=$((SCORE_A3+1))
else
  log "  ${RED}✗${NC} Aucune réponse HTTP sur http://$HAPROXY_IP/"
fi
STATS_RESP=$(curl -s --max-time 8 -u "admin:Stadium2026!" "http://$HAPROXY_IP/haproxy_stats" 2>/dev/null)
if echo "$STATS_RESP" | grep -qi "haproxy\|statistics\|BACKEND\|UP\|DOWN"; then
  log "  ${GREEN}✓${NC} Page de statistiques HAProxy accessible (login admin/Stadium2026!)"; SCORE_A3=$((SCORE_A3+1))
else
  log "  ${RED}✗${NC} Page stats inaccessible — vérifier URI '/haproxy_stats' et credentials"
fi

if   [ $SCORE_A3 -eq 2 ]; then ok "Load balancing et stats opérationnels" 2
elif [ $SCORE_A3 -eq 1 ]; then ok "Load balancing ou stats partiellement opérationnel" 1
else fail "Load balancing non fonctionnel"; fi

# A4 — Tolérance aux pannes : SRV-WEB1 et SRV-WEB2 UP (1pt)
warn "A4 — Vérification que les 2 serveurs web sont UP (Apache redémarré)..."
WEB1=$(curl -s --max-time 5 "http://172.20.0.11/" 2>/dev/null)
WEB2=$(curl -s --max-time 5 "http://172.20.0.12/" 2>/dev/null)
if echo "$WEB1" | grep -qi "grill\|html" && echo "$WEB2" | grep -qi "grill\|html"; then
  ok "SRV-WEB1 et SRV-WEB2 répondent tous les deux (Apache actif)" 1
elif echo "$WEB1" | grep -qi "grill\|html" || echo "$WEB2" | grep -qi "grill\|html"; then
  fail "Un seul des deux serveurs web répond — l'autre n'a pas été redémarré"
else
  fail "Aucun des deux serveurs web ne répond"
fi

# ─────────────────────────────────────────────────────────
hdr "PARTIE B — GLPI (8 points)"
# ─────────────────────────────────────────────────────────

MYSQL_CMD="mysql -h $GLPI_IP -u glpiuser -ppassword dbglpi"

# B1 — Fichier install.php renommé (1pt)
warn "B1 — Sécurisation GLPI : fichier install.php..."
INSTALL_CHECK=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes root@$GLPI_IP \
  "test -f /var/www/html/glpi/install/install.php && echo PRESENT || echo ABSENT" 2>/dev/null)
if [ "$INSTALL_CHECK" = "ABSENT" ]; then
  ok "Fichier install.php renommé ou supprimé" 1
else
  fail "Fichier install.php encore présent — sécurisation non effectuée"
fi

# B2 — Entité Agence Bamako (1pt)
warn "B2 — Entité 'Agence Bamako'..."
ENTITY=$($MYSQL_CMD -se "SELECT COUNT(*) FROM glpi_entities WHERE name='Agence Bamako';" 2>/dev/null)
if [ "$ENTITY" = "1" ] 2>/dev/null; then
  ok "Entité 'Agence Bamako' créée dans GLPI" 1
else
  fail "Entité 'Agence Bamako' non trouvée (résultat: $ENTITY)"
fi

# B3 — Équipements (3pts)
warn "B3 — Équipements dans l'entité Agence Bamako..."
# Récupérer l'ID de l'entité
ENTITY_ID=$($MYSQL_CMD -se "SELECT id FROM glpi_entities WHERE name='Agence Bamako' LIMIT 1;" 2>/dev/null)

if [ -n "$ENTITY_ID" ]; then
  PC_COUNT=$($MYSQL_CMD -se "SELECT COUNT(*) FROM glpi_computers WHERE entities_id=$ENTITY_ID;" 2>/dev/null)
  NET_COUNT=$($MYSQL_CMD -se "SELECT COUNT(*) FROM glpi_networkequipments WHERE entities_id=$ENTITY_ID;" 2>/dev/null)
else
  PC_COUNT=0; NET_COUNT=0
fi

SCORE_B3=0
log "  Ordinateurs trouvés : ${PC_COUNT:-0}/3 attendus"
log "  Équipements réseau trouvés : ${NET_COUNT:-0}/2 attendus"

[ "${PC_COUNT:-0}" -ge 3 ] 2>/dev/null && SCORE_B3=$((SCORE_B3+2)) || \
  { [ "${PC_COUNT:-0}" -ge 1 ] 2>/dev/null && SCORE_B3=$((SCORE_B3+1)); }
[ "${NET_COUNT:-0}" -ge 2 ] 2>/dev/null && SCORE_B3=$((SCORE_B3+1))

if   [ $SCORE_B3 -eq 3 ]; then ok "Tous les équipements créés (3 PC + 2 réseau)" 3
elif [ $SCORE_B3 -eq 2 ]; then ok "Équipements partiellement créés" 2
elif [ $SCORE_B3 -eq 1 ]; then ok "Équipements partiellement créés" 1
else fail "Aucun équipement trouvé dans l'entité Agence Bamako"; fi

# B4 — Techniciens (1pt)
warn "B4 — Comptes techniciens..."
TECH=$($MYSQL_CMD -se \
  "SELECT COUNT(*) FROM glpi_users WHERE name IN ('mcoulibaly','fdiallo') \
   OR email LIKE '%coulibaly%' OR email LIKE '%diallo%';" 2>/dev/null)
if [ "${TECH:-0}" -ge 2 ] 2>/dev/null; then
  ok "Les 2 techniciens créés (mcoulibaly + fdiallo)" 1
elif [ "${TECH:-0}" -ge 1 ] 2>/dev/null; then
  ok "1 technicien sur 2 créé" 0
  fail "Second technicien manquant"
else
  fail "Aucun technicien trouvé (noms attendus : mcoulibaly, fdiallo)"
fi

# B5 — Tickets (2pts)
warn "B5 — Tickets d'incidents..."
TICKET=$($MYSQL_CMD -se \
  "SELECT COUNT(*) FROM glpi_tickets WHERE \
   name LIKE '%VPN%' OR name LIKE '%cran%' OR name LIKE '%allume%' OR name LIKE '%Bamako%' OR name LIKE '%BKO%';" 2>/dev/null)
if   [ "${TICKET:-0}" -ge 2 ] 2>/dev/null; then ok "2 tickets d'incidents créés et trouvés" 2
elif [ "${TICKET:-0}" -ge 1 ] 2>/dev/null; then ok "1 ticket sur 2 créé" 1
else fail "Aucun ticket d'incident trouvé (cherché: VPN, écran, allume, BKO)"; fi

# ─────────────────────────────────────────────────────────
hdr "PARTIE C — Liaison LDAP / Active Directory (5 points)"
# ─────────────────────────────────────────────────────────

# C1 — Liaison LDAP configurée (3pts)
warn "C1 — Configuration liaison LDAP dans GLPI..."
LDAP_ACTIVE=$($MYSQL_CMD -se "SELECT COUNT(*) FROM glpi_authldaps WHERE is_active=1;" 2>/dev/null)
LDAP_BASE=$($MYSQL_CMD -se "SELECT basedn FROM glpi_authldaps WHERE is_active=1 LIMIT 1;" 2>/dev/null)
LDAP_HOST=$($MYSQL_CMD -se "SELECT host FROM glpi_authldaps WHERE is_active=1 LIMIT 1;" 2>/dev/null)

SCORE_C1=0
if [ "${LDAP_ACTIVE:-0}" -ge 1 ] 2>/dev/null; then
  log "  ${GREEN}✓${NC} Liaison LDAP active trouvée dans GLPI"; SCORE_C1=$((SCORE_C1+1))
else
  log "  ${RED}✗${NC} Aucune liaison LDAP active en base"
fi
if echo "$LDAP_BASE" | grep -qi "stadiumcompany"; then
  log "  ${GREEN}✓${NC} BaseDN contient 'stadiumcompany' : $LDAP_BASE"; SCORE_C1=$((SCORE_C1+1))
else
  log "  ${RED}✗${NC} BaseDN incorrect (attendu: DC=stadiumcompany,DC=com, obtenu: $LDAP_BASE)"
fi
if [ -n "$LDAP_HOST" ] && ping -c 1 -W 3 "$LDAP_HOST" >/dev/null 2>&1; then
  log "  ${GREEN}✓${NC} Serveur AD joignable : $LDAP_HOST"; SCORE_C1=$((SCORE_C1+1))
elif [ -n "$LDAP_HOST" ]; then
  log "  ${YELLOW}⚠${NC} Host LDAP configuré ($LDAP_HOST) mais non joignable — AD éteint ?"
  SCORE_C1=$((SCORE_C1+1))  # crédit partiel si configuré même si AD non joignable
else
  log "  ${RED}✗${NC} Aucun host LDAP configuré"
fi

if   [ $SCORE_C1 -ge 3 ]; then ok "Liaison LDAP complètement configurée" 3
elif [ $SCORE_C1 -ge 2 ]; then ok "Liaison LDAP partiellement configurée" 2
elif [ $SCORE_C1 -ge 1 ]; then ok "Liaison LDAP minimalement configurée" 1
else fail "Liaison LDAP absente ou incorrecte"; fi

# C2 — Import utilisateurs AD (2pts)
warn "C2 — Utilisateurs importés depuis l'Active Directory..."
IMPORTED=$($MYSQL_CMD -se "SELECT COUNT(*) FROM glpi_users WHERE authtype=3;" 2>/dev/null)
if   [ "${IMPORTED:-0}" -ge 3 ] 2>/dev/null; then ok "$IMPORTED utilisateurs AD importés dans GLPI" 2
elif [ "${IMPORTED:-0}" -ge 1 ] 2>/dev/null; then ok "$IMPORTED utilisateur(s) AD importé(s) (partiel)" 1
else fail "Aucun utilisateur AD importé (authtype=3 attendu en base)"; fi

# ─────────────────────────────────────────────────────────
hdr "RÉSULTAT FINAL"
# ─────────────────────────────────────────────────────────
log ""
log "┌──────────────────────────────────────────────────────┐"
log "│              SCORE OBTENU : $SCORE / $MAX                    │"

if   [ $SCORE -ge 18 ]; then MENTION="${GREEN}Excellent${NC}"
elif [ $SCORE -ge 16 ]; then MENTION="${GREEN}Très Bien${NC}"
elif [ $SCORE -ge 14 ]; then MENTION="${YELLOW}Bien${NC}"
elif [ $SCORE -ge 12 ]; then MENTION="${YELLOW}Assez Bien${NC}"
elif [ $SCORE -ge 10 ]; then MENTION="Passable"
else MENTION="${RED}Insuffisant${NC}"; fi

log "│              MENTION : $MENTION"
log "└──────────────────────────────────────────────────────┘"
log ""
log "  Rapport détaillé enregistré : $RAPPORT"
log ""
echo ""
echo "================================================"
echo "  NOTE FINALE : $SCORE / $MAX"
echo "================================================"
