#!/bin/bash
set -e

# Generate random password salt
salt=$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 -w0)
sed -e '/passwordSalt.*ПРИДУМАЙТЕ СЮДА ЧТО-НИБУДЬ/s%=> .*%=> "'$salt'",%' \
	-i /srv/$DOMAIN/protected/config/params.php

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf

