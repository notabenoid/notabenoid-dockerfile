FROM ubuntu:14.04
MAINTAINER opennota <opennota@gmail.com>

# Change these variables
ENV DOMAIN=example.com
ENV ADMIN_EMAIL=admin@example.com
ENV COMMENT_EMAIL=comment@example.com
ENV SYSTEM_EMAIL=no-reply@example.com

# Update the system and install all the necessary packages
RUN     apt-get update && \
	apt-get install -y \
		git \
		memcached \
		nginx \
		php5 \
		php5-curl \
		php5-fpm \
		php5-gd \
		php5-memcache \
		php5-pgsql \
		postgresql \
		supervisor

# Configure nginx
COPY    nginx /etc/nginx/sites-available/default
RUN     sed -i 's,\$DOMAIN,'$DOMAIN',' /etc/nginx/sites-available/default && \
	echo "daemon off;" >> /etc/nginx/nginx.conf

# Configure php5-fpm
RUN     sed -i 's,.*daemonize =.*,daemonize = no,' /etc/php5/fpm/php-fpm.conf && \
	sed -i 's,.*error_reporting =.*,error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT \& ~E_NOTICE,' /etc/php5/fpm/php.ini

# Configure postgresql
COPY    pg_hba.conf /etc/postgresql/9.3/main/

# Configure supervisord
COPY    supervisor/*.conf /etc/supervisor/conf.d/

# Entry point
COPY    entrypoint.sh /

# Add cron jobs
RUN   ( echo "0 0 * * * /usr/bin/php /srv/$DOMAIN/protected/yiic maintain midnight" && \
	echo "0 4 * * * /usr/bin/php /srv/$DOMAIN/protected/yiic maintain dailyfixes" ) >> /etc/crontab

# Clone the notabenoid repo, create directories, add write permissions, fix config files
RUN     git clone --depth=1 https://github.com/uisky/notabenoid.git /srv/$DOMAIN
WORKDIR /srv/$DOMAIN
RUN     mkdir -p www/assets www/i/book www/i/upic www/i/tmp protected/runtime && \
	chown www-data www/assets www/i/book www/i/upic www/i/tmp protected/runtime && \
	cd protected/config && \
	sed -e '/domain/s%=>.*%=> "'$DOMAIN'",%' \
	    -e '/adminEmail/s%=>.*%=> "'$ADMIN_EMAIL'",%' \
	    -e '/commentEmail/s%=>.*%=> "'$COMMENT_EMAIL'",%' \
	    -e '/systemEmail/s%=>.*%=> "'$SYSTEM_EMAIL'",%' \
	    -i main.php console.php

# Start postgresql, create user and database, load SQL dump, run maintenance script
RUN     /etc/init.d/postgresql start && \
	createuser -U postgres notabenoid && \
	createdb -U postgres -O notabenoid notabenoid && \
	psql -U notabenoid < init.sql && \
	php protected/yiic maintain dailyfixes && \
	/etc/init.d/postgresql stop

# Expose the Nginx port
EXPOSE 80

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc", "/var/log", "/var/lib/postgresql"]

ENTRYPOINT ["/entrypoint.sh"]

