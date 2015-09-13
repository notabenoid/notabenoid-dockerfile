#!/bin/bash

NB_SITE=/notabenoid/site
NB_DBDATA=/notabenoid/dbdata

# Exit immediately if a command exits with a non-zero status.
set -e

if [ "$1" = 'notabenoid' ]; then
	# Initialise work files directories
	# This is done at the entry script, because developers/devops
	# can create volumes both for /notabenoid/site and /notabenoid/files
	mkdir -p /notabenoid/files/bookpic /notabenoid/files/userpic
	chown www-data:www-data /notabenoid/files/bookpic /notabenoid/files/userpic
	ln -sn /notabenoid/files/bookpic /notabenoid/site/www/i/book || true
	ln -sn /notabenoid/files/userpic /notabenoid/site/www/i/upic || true
	ln -sn /notabenoid/tmp/assets /notabenoid/site/www/assets || true
	mkdir -p /notabenoid/site/www/i/tmp
	ln -sn /notabenoid/tmp/upiccut /notabenoid/site/www/i/tmp/upiccut || true
	ln -sn /notabenoid/tmp/runtime /notabenoid/site/protected/runtime || true

	# If database not initialized
	if [ ! -s "$NB_DBDATA/PG_VERSION" ]; then
		mkdir -p $NB_DBDATA
		chown -R postgres $NB_DBDATA
		su postgres -c "/usr/lib/postgresql/9.3/bin/initdb -D $NB_DBDATA"
	fi

	# Start postgresql
	/etc/init.d/postgresql start

	# If database user not exists
	USERSFOUND=$(psql postgres -U postgres -tAc "SELECT count(*) FROM pg_roles WHERE rolname='notabenoid'")
	if [ "$USERSFOUND" = "0" ]; then
		# Create user and database, load SQL dump
		createuser -U postgres notabenoid
		createdb -U postgres -O notabenoid notabenoid
		psql -U notabenoid --quiet < $NB_SITE/init.sql

		# Create admin user
		# Specifying a cost doesn't make sense here, as we're going
		# to change the admin password anyway.
		ADMINPWDHASH=$(php -r "print(password_hash('admin', PASSWORD_DEFAULT));")
		ADMINSQL="INSERT INTO users (login, pass, email, lang)
		          VALUES ('admin', '$ADMINPWDHASH', '$NB_EMAIL_ADMIN', 1);"
		echo "$ADMINSQL" | psql notabenoid -U notabenoid --quiet
	fi

	# Execute statistics calculation script
	php $NB_SITE/protected/yiic maintain dailyfixes

	# Stop database
	/etc/init.d/postgresql stop

	# Start services
	exec /usr/bin/supervisord --nodaemon --configuration=/etc/supervisor/supervisord.conf
fi

exec "$@"
