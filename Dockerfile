FROM ubuntu:14.04
MAINTAINER opennota <opennota@gmail.com>

# Install all the necessary packages
# This is the longest build step, so it is at the top of the Dockerfile
# for Docker to be able to cache the results of it for later rebuilds.
RUN     apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y \
		memcached \
		nginx \
		php5 \
		php5-curl \
		php5-fpm \
		php5-gd \
		php5-memcache \
		php5-pgsql \
		postgresql \
		supervisor \
		wget && \
	rm -rf /var/lib/apt/lists/*

###### VARIABLES
###### Change them

# URL of tar.gz archive with Notabenoid code
# For bleeding edge code use https://github.com/notabenoid/notabenoid/tarball/master
# For a specific version use https://github.com/notabenoid/notabenoid/tarball/[tag or branch or commit]
ENV NB_GIT_REF=master
ENV NB_ARCHIVE_URL=https://github.com/notabenoid/notabenoid/tarball/$NB_GIT_REF

ENV NB_DOMAIN=example.com
ENV NB_EMAIL_ADMIN=admin@example.com
ENV NB_EMAIL_COMMENT=comment@example.com
ENV NB_EMAIL_SYSTEM=no-reply@example.com

###### END OF VARIABLES

# Configure nginx
COPY    nginx /etc/nginx/sites-available/default
RUN     sed -i 's,\$DOMAIN,'$NB_DOMAIN',' /etc/nginx/sites-available/default && \
	echo "daemon off;" >> /etc/nginx/nginx.conf

# Configure php5-fpm
RUN     sed -i 's,.*daemonize =.*,daemonize = no,' /etc/php5/fpm/php-fpm.conf && \
	sed -i 's,.*max_input_vars =.*,max_input_vars = 4000,' /etc/php5/fpm/php.ini && \
	sed -i 's,.*error_reporting =.*,error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT \& ~E_NOTICE,' /etc/php5/fpm/php.ini

# Configure postgresql access, remove default database
COPY    pg_hba.conf /etc/postgresql/9.3/main/
RUN     sed -i "s/'\\/var\\/lib\\/postgresql\\/9.3\\/main'/'\\/notabenoid\\/dbdata'/g" /etc/postgresql/9.3/main/postgresql.conf && \
	rm -rf /var/lib/postgresql

# Configure supervisord
COPY    supervisor/*.conf /etc/supervisor/conf.d/

# Add cron jobs
RUN   ( echo "0 0 * * * /usr/bin/php /notabenoid/site/protected/yiic maintain midnight" && \
	echo "0 4 * * * /usr/bin/php /notabenoid/site/protected/yiic maintain dailyfixes" ) >> /etc/crontab

# Download the application
WORKDIR /notabenoid
RUN     mkdir site && \
	wget --no-verbose -O- $NB_ARCHIVE_URL | \
	tar -xzC site --strip-components=1

# Create temp files directories, add write permissions
RUN     mkdir -p tmp/assets tmp/upiccut tmp/runtime && \
	chown www-data:www-data tmp/assets tmp/upiccut tmp/runtime

# Edit notabenoid config files
WORKDIR /notabenoid/site
RUN     cd protected/config && \
	sed -e '/domain/s%=>.*%=> "'$NB_DOMAIN'",%' \
	    -e '/adminEmail/s%=>.*%=> "'$NB_EMAIL_ADMIN'",%' \
	    -e '/commentEmail/s%=>.*%=> "'$NB_EMAIL_COMMENT'",%' \
	    -e '/systemEmail/s%=>.*%=> "'$NB_EMAIL_SYSTEM'",%' \
	    -i params.php console.php

# Add important VOLUMEs
VOLUME  ["/notabenoid/dbdata", "/notabenoid/files"]

# Expose Nginx port
EXPOSE 80

# Setup entry point
COPY    docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

# Start the application
CMD ["notabenoid"]
