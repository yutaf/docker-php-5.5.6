# tag: amanekucompany/ks-php-5.5.6
FROM centos:6.6
MAINTAINER yutaf <fujishiro@amaneku.co.jp>

# yum repos
# epel; need for libcurl-devel
RUN yum localinstall http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm -y
# mysql
#RUN yum localinstall https://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm -y
# ius
#RUN yum localinstall -y http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-13.ius.centos6.noarch.rpm

RUN yum update -y
#RUN yum install -y --enablerepo=epel,mysql56-community,ius \
RUN yum install -y --enablerepo=epel \
# commands
  git \
# Apache, php \
  tar \
  gcc \
  zlib \
  zlib-devel \
  openssl-devel \
  pcre-devel \
# php
  perl \
  libxml2-devel \
  libjpeg-devel \
  libpng-devel \
  freetype-devel \
  libmcrypt-devel \
  libcurl-devel \
  readline-devel \
  libicu-devel \
  gcc-c++ \
  readline-devel \
# mysql
  mysql \
# cron
  crontabs.noarch

# workaround for curl certification error
COPY templates/ca-bundle-curl.crt /root/ca-bundle-curl.crt

# Apache
RUN \
  cd /usr/local/src && \
  curl -L -O http://archive.apache.org/dist/httpd/httpd-2.2.26.tar.gz && \
  tar xzvf httpd-2.2.26.tar.gz && \
  cd httpd-2.2.26 && \
    ./configure \
      --prefix=/opt/apache2.2.26 \
      --enable-mods-shared=all \
      --enable-proxy \
      --enable-ssl \
      --with-ssl \
      --with-mpm=prefork \
      --with-pcre && \
  make && \
  make install && \
  cd && \
  rm -r /usr/local/src/httpd-2.2.26

# php
RUN \
  cd /usr/local/src && \
  curl -L -O http://php.net/distributions/php-5.5.6.tar.gz && \
  tar xzvf php-5.5.6.tar.gz && \
  cd php-5.5.6 && \
  ./configure \
    --prefix=/opt/php-5.5.6 \
    --with-config-file-path=/srv/etc \
    --with-config-file-scan-dir=/srv/etc/php.d \
    --with-apxs2=/opt/apache2.2.26/bin/apxs \
# This line is necessary for build
    --with-libdir=lib64 \
# From live server configuration
    --enable-mbstring \
    --enable-mbregex \
    --with-mysql=mysqlnd \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-zlib=/usr \
    --with-curl \
    --enable-soap \
    --with-xmlrpc \
    --with-openssl=/usr \
    --with-mcrypt=/usr \
    --with-gd && \
# For interactive shell
    --with-readline=/usr \
# Mine
#    --enable-intl \
#    --with-icu-dir=/usr \
#    --with-gettext=/usr \
#    --with-pcre-regex=/usr \
#    --with-pcre-dir=/usr \
#    --with-readline=/usr \
#    --with-libxml-dir=/usr/bin/xml2-config \
#    --with-zlib-dir=/usr \
#    --with-jpeg-dir=/usr \
#    --with-png-dir=/usr \
#    --with-freetype-dir=/usr \
#    --enable-gd-native-ttf \
#    --enable-gd-jis-conv \
#    --enable-bcmath \
#    --enable-exif && \
  make && \
  make install && \
  cd && \
  rm -r /usr/local/src/php-5.5.6

# Set php PATH to use phpize command
ENV PATH /opt/php-5.5.6/bin:$PATH

# xdebug
RUN \
  mkdir -p /usr/local/src/xdebug && \
  cd /usr/local/src/xdebug && \
  curl --cacert /root/ca-bundle-curl.crt -L -O http://xdebug.org/files/xdebug-2.4.1.tgz && \
  tar -xzf xdebug-2.4.1.tgz && \
  cd xdebug-2.4.1 && \
  phpize && \
  ./configure --enable-xdebug && \
  make && \
  make install && \
  cd && \
  rm -r /usr/local/src/xdebug

#
# Edit config files
#
COPY templates/apache.conf /srv/etc/apache.conf
COPY templates/php.ini /srv/etc/php.ini
# Apache
RUN \
  sed -i "s/^Listen 80/#&/" /opt/apache2.2.26/conf/httpd.conf && \
  sed -i "s/^DocumentRoot/#&/" /opt/apache2.2.26/conf/httpd.conf && \
  sed -i "/^<Directory/,/^<\/Directory/s/^/#/" /opt/apache2.2.26/conf/httpd.conf && \
  sed -i "s;ScriptAlias /cgi-bin;#&;" /opt/apache2.2.26/conf/httpd.conf && \
  sed -i "s;#\(Include conf/extra/httpd-mpm.conf\);\1;" /opt/apache2.2.26/conf/httpd.conf && \
  sed -i "s;#\(Include conf/extra/httpd-default.conf\);\1;" /opt/apache2.2.26/conf/httpd.conf && \
# DirectoryIndex; index.html precedes index.php
  sed -i "/\s*DirectoryIndex/s/$/ index.php/" /opt/apache2.2.26/conf/httpd.conf && \
  sed -i "s/\(ServerTokens \)Full/\1Prod/" /opt/apache2.2.26/conf/extra/httpd-default.conf && \
  echo "Include /srv/etc/apache.conf" >> /opt/apache2.2.26/conf/httpd.conf && \
# log
  mkdir -p -m 777 /srv/www/log/ && \
  echo 'CustomLog "|/opt/apache2.2.26/bin/rotatelogs /srv/www/log/access.%Y%m%d.log 86400 540" combined' >> /srv/etc/apache.conf && \
  echo 'ErrorLog "|/opt/apache2.2.26/bin/rotatelogs /srv/www/log/error.%Y%m%d.log 86400 540"' >> /srv/etc/apache.conf && \
# Create php scripts for check
  mkdir -p /srv/www/htdocs/https && \
  echo "<?php echo 'hello, php';" > /srv/www/htdocs/https/index.php && \
  echo "<?php phpinfo();" > /srv/www/htdocs/https/info.php && \
#
# php.ini
#

## xdebug
  echo 'zend_extension = /opt/php-5.5.6/lib/php/extensions/no-debug-non-zts-20121212/xdebug.so' >> /srv/etc/php.ini && \
# set TERM
  echo export TERM=xterm-256color >> /root/.bashrc && \
# set timezone
  ln -sf /usr/share/zoneinfo/Japan /etc/localtime && \
# Delete log files except dot files
  echo '00 15 * * * find /srv/www/log -not -regex ".*/\.[^/]*$" -type f -mtime +2 -exec rm -f {} \;' > /root/crontab && \
  crontab /root/crontab && \
# mysql
  echo >> /etc/my.cnf && \
  echo '[client]' >> /etc/my.cnf && \
  echo 'default-character-set=utf8' >> /etc/my.cnf && \
  sed -i 's;^\[mysqld\];&\ncharacter-set-server=utf8\ncollation-server=utf8_general_ci;' /etc/my.cnf

CMD ["/bin/bash", "-c", "/etc/init.d/crond start && /opt/apache2.2.26/bin/httpd -DFOREGROUND"]
