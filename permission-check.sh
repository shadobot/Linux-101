#!/usr/bin/env bash
# autocheck_droits.sh — Auto-check TP "Gestion des droits" (Debian)
# Donne une note /20 + XP + badges + rapport.
# Usage:
#   chmod +x autocheck_droits.sh
#   ./autocheck_droits.sh
#
# Hypothèses (TP proposé) :
#   ~/TP_DROITS/atelier contient :
#     public.txt (644)
#     secret.txt (600)
#     script.sh  (750)
#     dossierA   (dossier, 700)
#     partage/   (dossier, 770, owner alice, group tpusers)
#     partage/notes.txt (doit exister)

set -u

# ---------------------------
# Helpers
# ---------------------------
ok(){ printf "✅ %s\n" "$*"; }
ko(){ printf "❌ %s\n" "$*"; }
info(){ printf "ℹ️  %s\n" "$*"; }

# safe stat wrappers
perm_of() { stat -c "%a" "$1" 2>/dev/null || echo ""; }
owner_of(){ stat -c "%U" "$1" 2>/dev/null || echo ""; }
group_of(){ stat -c "%G" "$1" 2>/dev/null || echo ""; }

# scoring
SCORE=0
MAX=20
REPORT_LINES=()

add_report(){ REPORT_LINES+=("$*"); }

award_points() {
  local pts="$1"; shift
  local msg="$*"
  SCORE=$((SCORE + pts))
  add_report "+${pts} : ${msg}"
}

fail_report(){
  add_report "  0 : $*"
}

# ---------------------------
# Locate TP directory
# ---------------------------
BASE_DEFAULT="$HOME/TP_DROITS"
BASE="$BASE_DEFAULT"
ATELIER="$BASE/atelier"
RENDU="$BASE/rendu"

if [[ ! -d "$BASE" ]]; then
  # Try to locate within home (light search)
  FOUND="$(find "$HOME" -maxdepth 3 -type d -name "TP_DROITS" 2>/dev/null | head -n 1)"
  if [[ -n "${FOUND:-}" ]]; then
    BASE="$FOUND"
    ATELIER="$BASE/atelier"
    RENDU="$BASE/rendu"
  fi
fi

# Prepare report path (even if rendu missing)
NOW="$(date +"%Y%m%d_%H%M%S")"
REPORT_PATH="/tmp/autocheck_droits_${NOW}.txt"
if [[ -d "$RENDU" ]]; then
  REPORT_PATH="$RENDU/autocheck_droits_${NOW}.txt"
fi

add_report "=== AUTO-CHECK TP DROITS (Debian) ==="
add_report "Base détectée : $BASE"
add_report "Atelier : $ATELIER"
add_report "Rendu : $RENDU"
add_report "Date : $(date -Is)"
add_report ""

# ---------------------------
# 1) Structure (2 points)
# ---------------------------
STRUCT_OK=0
if [[ -d "$BASE" ]]; then
  ok "Dossier TP_DROITS trouvé: $BASE"
  STRUCT_OK=$((STRUCT_OK + 1))
else
  ko "Dossier TP_DROITS introuvable (attendu: $BASE_DEFAULT)"
fi

if [[ -d "$ATELIER" && -d "$RENDU" ]]; then
  ok "Sous-dossiers atelier/ et rendu/ présents"
  STRUCT_OK=$((STRUCT_OK + 1))
else
  ko "Sous-dossiers manquants (attendus: $ATELIER et $RENDU)"
fi

if [[ $STRUCT_OK -eq 2 ]]; then
  award_points 2 "Structure TP_DROITS + atelier/rendu OK"
else
  fail_report "Structure incomplète (0/2)."
fi

add_report ""

# ---------------------------
# 2) Users exist (2 points)
# ---------------------------
USERS=("alice" "bob" "charlie")
FOUND_USERS=0
for u in "${USERS[@]}"; do
  if grep -qE "^${u}:" /etc/passwd 2>/dev/null; then
    ok "Utilisateur existe: $u"
    FOUND_USERS=$((FOUND_USERS + 1))
  else
    ko "Utilisateur absent dans /etc/passwd: $u"
  fi
done

# Scoring: 2 pts if all 3 exist, 1 pt if 2 exist, else 0.
if [[ $FOUND_USERS -eq 3 ]]; then
  award_points 2 "Utilisateurs (alice/bob/charlie) présents"
elif [[ $FOUND_USERS -ge 2 ]]; then
  award_points 1 "Utilisateurs partiellement présents (au moins 2/3)"
  fail_report "Il manque au moins 1 utilisateur."
else
  fail_report "Utilisateurs insuffisants (moins de 2/3)."
fi

add_report ""

# ---------------------------
# 3) Group + membership (2 points)
# ---------------------------
GROUP_OK=0
if getent group tpusers >/dev/null 2>&1; then
  ok "Groupe existe: tpusers"
  GROUP_OK=$((GROUP_OK + 1))
else
  ko "Groupe manquant: tpusers"
fi

MEM_OK=0
if [[ $FOUND_USERS -eq 3 ]]; then
  ALL_IN_GROUP=1
  for u in "${USERS[@]}"; do
    # id <user> works without sudo on Debian
    if id -nG "$u" 2>/dev/null | tr ' ' '\n' | grep -qx "tpusers"; then
      ok "$u appartient à tpusers"
    else
      ko "$u n'appartient pas à tpusers"
      ALL_IN_GROUP=0
    fi
  done
  if [[ $ALL_IN_GROUP -eq 1 ]]; then
    MEM_OK=1
  fi
else
  info "Test appartenance groupe ignoré: tous les utilisateurs ne sont pas présents."
fi

if [[ $GROUP_OK -eq 1 ]]; then
  award_points 1 "Groupe tpusers présent"
else
  fail_report "Groupe tpusers absent (0/1)."
fi

if [[ $MEM_OK -eq 1 ]]; then
  award_points 1 "Tous les utilisateurs sont membres de tpusers"
else
  fail_report "Appartenance tpusers incomplète (0/1)."
fi

add_report ""

# ---------------------------
# 4) Items exist (2 points)
# ---------------------------
ITEMS_OK=0
missing=()

need_file(){ [[ -f "$1" ]] || missing+=("$1"); }
need_dir(){ [[ -d "$1" ]] || missing+=("$1"); }

need_file "$ATELIER/public.txt"
need_file "$ATELIER/secret.txt"
need_file "$ATELIER/script.sh"
need_dir  "$ATELIER/dossierA"
need_dir  "$ATELIER/partage"
need_file "$ATELIER/partage/notes.txt"

if [[ ${#missing[@]} -eq 0 ]]; then
  ok "Tous les fichiers/dossiers attendus existent"
  award_points 2 "Présence des éléments (public/secret/script/dossierA/partage/notes) OK"
else
  ko "Éléments manquants :"
  for m in "${missing[@]}"; do ko "  - $m"; done
  fail_report "Présence des éléments incomplète (0/2)."
fi

# Warning if a leftover file named dossierA exists (typo in TP creation step sometimes)
if [[ -f "$ATELIER/dossierA" && ! -d "$ATELIER/dossierA" ]]; then
  info "Attention: 'dossierA' est un fichier, pas un dossier (corriger avec mkdir dossierA)."
fi

add_report ""

# ---------------------------
# 5) Permissions (10 points total)
# ---------------------------
# public.txt = 644 (2)
# secret.txt = 600 (2)
# script.sh  = 750 (2)
# dossierA   = 700 (2)
# partage    = 770 (2)
check_perm() {
  local path="$1" expected="$2" pts="$3" label="$4"
  if [[ -e "$path" ]]; then
    local p; p="$(perm_of "$path")"
    if [[ "$p" == "$expected" ]]; then
      ok "Perm OK: $label ($path) = $p"
      award_points "$pts" "Permissions $label = $expected"
    else
      ko "Perm NOK: $label ($path) = ${p:-?} (attendu $expected)"
      fail_report "Permissions $label incorrectes (attendu $expected)."
    fi
  else
    ko "Perm check impossible: $path absent"
    fail_report "Permissions $label non vérifiées (fichier/dossier absent)."
  fi
}

check_perm "$ATELIER/public.txt"  "644" 2 "public.txt"
check_perm "$ATELIER/secret.txt"  "600" 2 "secret.txt"
check_perm "$ATELIER/script.sh"   "750" 2 "script.sh"
check_perm "$ATELIER/dossierA"    "700" 2 "dossierA/"
check_perm "$ATELIER/partage"     "770" 2 "partage/"

add_report ""

# ---------------------------
# 6) Ownership/group critical (2 points)
# ---------------------------
# partage: owner alice, group tpusers (2 points)
if [[ -d "$ATELIER/partage" ]]; then
  O="$(owner_of "$ATELIER/partage")"
  G="$(group_of "$ATELIER/partage")"
  if [[ "$O" == "alice" && "$G" == "tpusers" ]]; then
    ok "Owner/group OK: partage/ = $O:$G"
    award_points 2 "Propriétaire/groupe de partage/ = alice:tpusers"
  else
    ko "Owner/group NOK: partage/ = ${O:-?}:${G:-?} (attendu alice:tpusers)"
    fail_report "Propriétaire/groupe de partage/ incorrect."
  fi
else
  ko "Owner/group check impossible: partage/ absent"
  fail_report "Propriétaire/groupe de partage/ non vérifiés."
fi

add_report ""

# ---------------------------
# Final score + XP + badges
# ---------------------------
if [[ $SCORE -gt $MAX ]]; then SCORE=$MAX; fi

PERCENT=$((SCORE * 100 / MAX))
XP=$((SCORE * 50))           # 0..1000
BONUS=0
if [[ $SCORE -eq 20 ]]; then BONUS=200; XP=$((XP + BONUS)); fi

BADGE="Apprenti des Permissions (C-Rank)"
if [[ $SCORE -ge 20 ]]; then
  BADGE="Gardien des Permissions (S-Rank)"
elif [[ $SCORE -ge 17 ]]; then
  BADGE="Maître du chmod (A-Rank)"
elif [[ $SCORE -ge 14 ]]; then
  BADGE="Gestionnaire de droits (B-Rank)"
fi

echo
echo "=============================="
echo "NOTE FINALE : $SCORE / $MAX  ($PERCENT%)"
echo "XP GAGNÉE  : $XP $( [[ $BONUS -gt 0 ]] && echo "(+${BONUS} bonus perfect)" )"
echo "BADGE      : $BADGE"
echo "=============================="
echo

add_report "=== RÉSULTAT ==="
add_report "Note : $SCORE / $MAX ($PERCENT%)"
add_report "XP   : $XP"
add_report "Badge: $BADGE"
add_report ""

# Save report
{
  for line in "${REPORT_LINES[@]}"; do
    echo "$line"
  done
} > "$REPORT_PATH"

echo "Rapport écrit dans : $REPORT_PATH"
echo "Astuce: ouvre-le avec 'less $REPORT_PATH'"

exit 0