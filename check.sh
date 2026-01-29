#!/usr/bin/env bash
set -euo pipefail

SCORE=0
MAX=20

HOST_EXPECTED="srv-web01"
USER_EXPECTED="etudiant"
LAN_IP_EXPECTED="192.168.56.10/24"
WEB_EXPECTED="ALPHA-SERVICES - srv-web01"
DB_NAME="alphadb"

ok()   { echo "[OK]  $*"; }
ko()   { echo "[KO]  $*"; }
add()  { SCORE=$((SCORE + $1)); echo "      (+$1)"; }

# 1) Hostname (2 pts)
CUR_HOST="$(hostnamectl --static 2>/dev/null || hostname)"
if [[ "$CUR_HOST" == "$HOST_EXPECTED" ]]; then ok "Hostname = $HOST_EXPECTED"; add 2; else ko "Hostname attendu $HOST_EXPECTED, trouvé $CUR_HOST"; fi

# 2) User + sudo (2 pts)
if id "$USER_EXPECTED" &>/dev/null; then
  ok "Utilisateur $USER_EXPECTED existe"
  # groupe sudo ou wheel
  if id -nG "$USER_EXPECTED" | grep -Eq '\b(sudo|wheel)\b'; then ok "$USER_EXPECTED a les droits sudo"; add 2; else ko "$USER_EXPECTED n'est pas dans sudo/wheel"; add 1; fi
else
  ko "Utilisateur $USER_EXPECTED absent"
fi

# 3) Dossier projet + owner + perms (4 pts)
BASE="/home/$USER_EXPECTED/projet"
SCRIPTS="$BASE/scripts"
LOGS="$BASE/logs"
APPLOG="$LOGS/app.log"

PTS=0
if [[ -d "$BASE" && -d "$SCRIPTS" && -d "$LOGS" && -f "$APPLOG" ]]; then
  ok "Arborescence projet OK"
  PTS=$((PTS+1))
else
  ko "Arborescence projet incomplète (attendu $BASE/{scripts,logs,backup} + app.log)"
fi

# owner
if [[ -e "$BASE" ]]; then
  OWNER="$(stat -c '%U:%G' "$BASE")"
  if [[ "$OWNER" == "$USER_EXPECTED:$USER_EXPECTED" ]]; then ok "Propriétaire $OWNER OK"; PTS=$((PTS+1)); else ko "Owner $OWNER (attendu $USER_EXPECTED:$USER_EXPECTED)"; fi
fi

# perms
perm() { stat -c '%a' "$1" 2>/dev/null || echo ""; }
P1="$(perm "$SCRIPTS")"
P2="$(perm "$LOGS")"
P3="$(perm "$APPLOG")"

[[ "$P1" == "700" ]] && { ok "Perms scripts=700"; PTS=$((PTS+1)); } || ko "Perms scripts attendu 700, trouvé ${P1:-?}"
[[ "$P2" == "750" ]] && { ok "Perms logs=750"; PTS=$((PTS+1)); }   || ko "Perms logs attendu 750, trouvé ${P2:-?}"
# app.log 640 demandé, mais on ne peut pas dépasser 4 pts au total : on l'intègre dans la dernière vérif
if [[ "$P3" == "640" ]]; then ok "Perms app.log=640"; else ko "Perms app.log attendu 640, trouvé ${P3:-?}"; fi

# Ajustement: si app.log OK et une autre perms manquait, on remonte d'1 max dans la limite.
if [[ "$P3" == "640" && "$PTS" -lt 4 ]]; then PTS=$((PTS+1)); fi
if (( PTS > 4 )); then PTS=4; fi
add "$PTS"

# 4) NIC2 LAN statique (4 pts)
LAN_IF="$(ip -o -4 addr show | awk -v ip="$LAN_IP_EXPECTED" '$0 ~ ip {print $2; exit}')"
if [[ -n "${LAN_IF:-}" ]]; then
  ok "Interface LAN détectée: $LAN_IF avec $LAN_IP_EXPECTED"
  add 3
  # Vérif "pas de default route" via cette IF (LAN isolé) — tolérance
  if ip route | grep -qE "^default .* dev ${LAN_IF}\b"; then
    ko "Default route via $LAN_IF détectée (LAN isolé demandé)"; add 0
  else
    ok "Pas de default route via $LAN_IF (OK)"; add 1
  fi
else
  ko "IP LAN $LAN_IP_EXPECTED non trouvée sur une interface"
fi

# 5) htop installé (1 pt)
if command -v htop &>/dev/null; then ok "htop installé"; add 1; else ko "htop non installé"; fi

# 6) Disque /data ext4 + fstab (4 pts)
PTS=0
if mountpoint -q /data; then
  ok "/data est monté"
  PTS=$((PTS+2))
  FSTYPE="$(findmnt -n -o FSTYPE /data || true)"
  if [[ "$FSTYPE" == "ext4" ]]; then ok "FS /data = ext4"; PTS=$((PTS+1)); else ko "FS /data attendu ext4, trouvé $FSTYPE"; fi
  if grep -Eq '^[^#].*\s/data\s+ext4\s' /etc/fstab; then ok "fstab contient /data"; PTS=$((PTS+1)); else ko "fstab ne contient pas /data ext4"; fi
else
  ko "/data non monté"
fi
if (( PTS > 4 )); then PTS=4; fi
add "$PTS"

# 7) nginx actif + page (2 pts)
PTS=0
if systemctl is-active --quiet nginx; then ok "nginx actif"; PTS=$((PTS+1)); else ko "nginx inactif"; fi
# curl depuis localhost (évite dépendances réseau)
BODY="$(curl -s --max-time 2 http://127.0.0.1/ || true)"
if echo "$BODY" | grep -Fq "$WEB_EXPECTED"; then ok "Page web contient le texte attendu"; PTS=$((PTS+1)); else ko "Page web ne contient pas '$WEB_EXPECTED'"; fi
add "$PTS"

# 8) MariaDB + DB/table/data (1 pt)
PTS=0
if systemctl is-active --quiet mariadb; then
  ok "mariadb actif"
  # Vérif DB + table + au moins 2 lignes
  set +e
  COUNT="$(mariadb -N -s -e "SELECT COUNT(*) FROM ${DB_NAME}.users;" 2>/dev/null)"
  RC=$?
  set -e
  if (( RC == 0 )) && [[ "${COUNT:-0}" =~ ^[0-9]+$ ]] && (( COUNT >= 2 )); then
    ok "DB ${DB_NAME}.users OK (lignes=$COUNT)"
    PTS=1
  else
    ko "DB/table/users absente ou pas assez de lignes"
  fi
else
  ko "mariadb inactif"
fi
add "$PTS"

echo "----------------------------------------"
echo "NOTE: $SCORE / $MAX"
echo "----------------------------------------"

# Code de sortie utile pour CI
if (( SCORE == MAX )); then exit 0; else exit 1; fi
