# tag: yutaf/php-5.5.6
FROM centos:6.3
MAINTAINER yutaf <yutafuji2008@gmail.com>

# yum repos
# epel; need for libcurl-devel
RUN yum localinstall http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm -y
# mysql
RUN yum localinstall https://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm -y
# ius
RUN yum localinstall -y http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-13.ius.centos6.noarch.rpm

RUN yum update -y
RUN yum install -y --enablerepo=epel,mysql56-community,ius \
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
    --with-config-file-path=/srv/php/etc \
    --with-config-file-scan-dir=/srv/php/etc/php.d \
    --with-apxs2=/opt/apache2.2.26/bin/apxs \
    --with-libdir=lib64 \
    --enable-mbstring \
    --enable-intl \
    --with-icu-dir=/usr \
    --with-gettext=/usr \
    --with-pcre-regex=/usr \
    --with-pcre-dir=/usr \
    --with-readline=/usr \
    --with-libxml-dir=/usr/bin/xml2-config \
    --with-mysql=mysqlnd \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-zlib=/usr \
    --with-zlib-dir=/usr \
    --with-gd \
    --with-jpeg-dir=/usr \
    --with-png-dir=/usr \
    --with-freetype-dir=/usr \
    --enable-gd-native-ttf \
    --enable-gd-jis-conv \
    --with-openssl=/usr \
    --with-mcrypt=/usr \
    --enable-bcmath \
    --with-curl \
    --enable-exif && \
  make && \
  make install && \
  cd && \
  rm -r /usr/local/src/php-5.5.6

# xdebug
RUN \
  mkdir -p /usr/local/src/xdebug && \
  cd /usr/local/src/xdebug && \
  curl --cacert /root/ca-bundle-curl.crt -L -O http://xdebug.org/files/xdebug-2.2.7.tgz && \
  tar -xzf xdebug-2.2.7.tgz && \
  cd xdebug-2.2.7 && \
  phpize && \
  ./configure --enable-xdebug && \
  make && \
  make install && \
  cd && \
  rm -r /usr/local/src/xdebug

#
# Edit config files
#

COPY templates/apache.conf /etc/httpd/conf.d/apache.conf
RUN \
# Apache config
  sed -i 's/^Listen 80/#&/' /etc/httpd/conf/httpd.conf && \
  sed -i 's/^DocumentRoot/#&/' /etc/httpd/conf/httpd.conf && \
  sed -i '/^<Directory/,/^<\/Directory/s/^/#/' /etc/httpd/conf/httpd.conf && \
  sed -i 's;ScriptAlias /cgi-bin;#&;' /etc/httpd/conf/httpd.conf && \
  mkdir -p -m 777 /var/www/html/log/ && \
  sed -i 's;^CustomLog .*;CustomLog "|/usr/sbin/rotatelogs /var/www/html/log/access.%Y%m%d.log 86400 540" combined;' /etc/httpd/conf/httpd.conf && \
  sed -i 's;^ErrorLog .*;ErrorLog "|/usr/sbin/rotatelogs /var/www/html/log/error.%Y%m%d.log 86400 540";' /etc/httpd/conf/httpd.conf && \
  sed -i 's;^ServerTokens .*;ServerTokens Prod;' /etc/httpd/conf/httpd.conf && \
# Create php scripts for check
  mkdir -p /var/www/html/htdocs && \
  echo "<?php echo 'hello, php';" > /var/www/html/htdocs/index.php && \
  echo "<?php phpinfo();" > /var/www/html/htdocs/info.php && \
#
# php.ini
#
  sed -i 's;^expose_php.*;expose_php = Off;' /etc/php.ini && \
# error
  sed -i 's;^display_errors.*;display_errors = On;' /etc/php.ini && \
  sed -i 's;^display_startup_errors.*;display_startup_errors = On;' /etc/php.ini && \
# timezone
  sed -i 's/^;date.timezone.*/date.timezone = GMT/' /etc/php.ini && \
# memory
  sed -i 's;^memory_limit.*;memory_limit = 256M;' /etc/php.ini && \
# composer
  echo 'curl.cainfo=/root/ca-bundle-curl.crt' >> /etc/php.ini && \
  echo 'openssl.cafile=/root/ca-bundle-curl.crt' >> /etc/php.ini && \
# imagick
  echo 'extension=imagick.so' >> /etc/php.ini && \
# xdebug
  echo 'zend_extension=/usr/lib64/php/modules/xdebug.so' >> /etc/php.ini && \
  echo 'html_errors = on' >> /etc/php.ini && \
  echo 'xdebug.remote_enable  = on' >> /etc/php.ini && \
  echo 'xdebug.remote_autostart = 1' >> /etc/php.ini && \
  echo 'xdebug.remote_connect_back=1' >> /etc/php.ini && \
  echo 'xdebug.remote_handler = dbgp' >> /etc/php.ini && \
  echo 'xdebug.idekey = PHPSTORM' >> /etc/php.ini && \
# set TERM
  echo export TERM=xterm-256color >> /root/.bashrc && \
# set timezone
  ln -sf /usr/share/zoneinfo/Japan /etc/localtime && \
# Delete log files except dot files
  echo '00 15 * * * find /var/www/html/log -not -regex ".*/\.[^/]*$" -type f -mtime +2 -exec rm -f {} \;' > /root/crontab && \
  crontab /root/crontab && \
# mysql
  echo >> /etc/my.cnf && \
  echo '[client]' >> /etc/my.cnf && \
  echo 'default-character-set=utf8' >> /etc/my.cnf && \
  sed -i 's;^\[mysqld\];&\ncharacter-set-server=utf8\ncollation-server=utf8_general_ci;' /etc/my.cnf

CMD ["/bin/bash", "-c", "/etc/init.d/crond start && /usr/sbin/httpd -DFOREGROUND"]
