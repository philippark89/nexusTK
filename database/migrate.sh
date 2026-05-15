#!/bin/bash
for script in scripts/*.sql; do
	echo Executing $script...
	docker compose exec -T database mysql < $script
done
