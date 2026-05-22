#!/bin/bash
dir=/home/RTK/database/history
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d-%H-%M-%S)_NexusTK.sql"

mysqldump -h database -u rtk -pchangeMe --opt --add-drop-database --databases RTK > "$file" 2>/dev/null
chmod 444 "$file"

# Keep the 72 most recent backups (6 hours at 5-min intervals)
for oldBackup in $(ls -1tr "$dir"/*.sql 2>/dev/null | head -n -72); do
    chmod 744 "$oldBackup"
    rm -f "$oldBackup"
done
