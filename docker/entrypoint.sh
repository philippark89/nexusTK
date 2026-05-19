#!/bin/bash
set -e

echo "[entrypoint] Waiting for database..."
until mysqladmin ping -h database -u rtk -pchangeMe --silent 2>/dev/null; do
    sleep 2
done
echo "[entrypoint] Database ready."

echo "[entrypoint] Running migrations..."
for script in /database/scripts/*.sql; do
    echo "  $(basename $script)"
    mysql -h database -u root -pdefinitelyChangeMe RTK < "$script" 2>&1 | grep -v "Warning:"
done
echo "[entrypoint] Migrations done."

echo "[entrypoint] Building RTK servers..."
cd /home/RTK/rtk && make clean && make all

echo "[entrypoint] Starting servers via supervisord..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/rtk.conf
