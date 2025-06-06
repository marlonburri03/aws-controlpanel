#!/bin/bash

# Zugangsdaten abfragen
read -rp "AWS Access Key ID: " KEY
read -rp "AWS Secret Access Key: " SECRET
read -rp "AWS Session Token: " TOKEN

# Dateipfad zur credentials-Datei abfragen
read -rp "Pfad zur credentials-Datei (z. B. ~/.aws/credentials): " CRED_FILE
CRED_FILE="${CRED_FILE/#\~/$HOME}"  # ~ durch $HOME ersetzen

# Existiert die Datei? Wenn nein, erstellen
if [[ ! -f "$CRED_FILE" ]]; then
    echo "Datei $CRED_FILE existiert nicht. Erstelle sie..."
    mkdir -p "$(dirname "$CRED_FILE")"
    touch "$CRED_FILE"
fi

# Profil abfragen (default, oder benannt)
read -rp "Name des Profils (Standard: default): " PROFILE
PROFILE=${PROFILE:-default}

# Vorhandenen Eintrag für das Profil entfernen (falls vorhanden)
awk -v profile="[$PROFILE]" '
BEGIN {skip=0}
{
    if ($0 ~ /^\[.*\]/) {
        skip=($0 == profile)
    }
    if (!skip) print $0
}
' "$CRED_FILE" > "${CRED_FILE}.tmp"

# Neue Zugangsdaten ans Ende der Datei schreiben
{
    echo
    echo "[$PROFILE]"
    echo "aws_access_key_id = $KEY"
    echo "aws_secret_access_key = $SECRET"
    echo "aws_session_token = $TOKEN"
} >> "${CRED_FILE}.tmp"

# Alte Datei ersetzen
mv "${CRED_FILE}.tmp" "$CRED_FILE"

echo "Zugangsdaten erfolgreich in $CRED_FILE unter dem Profil [$PROFILE] gespeichert."
