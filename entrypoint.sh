#!/bin/bash

set -o noclobber  # Avoid overlay files (echo "hi" > foo)
set -o errexit    # Used to exit upon error, avoiding cascading errors
set -o pipefail   # Unveils hidden failures
set -o nounset    # Exposes unset variables

# These downloads have to happen in entrypoint because we are mounting whole /var/www/html in docker-compose.yml

# https://www.drupal.org/node/3060/release
DRUPAL_VERSION=7.69
DRUPAL_MD5=292290a2fb1f5fc919291dc3949cdf7c
CIVICRM_VERSION=5.21.1

set -eux;

if [[ ! -e /var/www/html/index.php ]]; then
    cd /tmp
    # downloading drupal
    curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz
    echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c -
    tar -xz --strip-components=1 -f drupal.tar.gz --directory /var/www/html/
    # downloading drupal german language
    curl --location https://ftp.drupal.org/files/translations/${DRUPAL_VERSION:0:1}.x/drupal/drupal-${DRUPAL_VERSION}.de.po --output /var/www/html/profiles/standard/translations/drupal-${DRUPAL_VERSION}.de.po
    # downloading civicrm
    curl --location https://download.civicrm.org/civicrm-${CIVICRM_VERSION}-drupal.tar.gz --output civicrm.tar.gz
    tar -xzf civicrm.tar.gz --directory /var/www/html/sites/all/modules/
    # downloading civicrm german language
    curl --location https://download.civicrm.org/civicrm-${CIVICRM_VERSION}-l10n.tar.gz --output civicrm-l10n.tar.gz
    tar -xzf civicrm-l10n.tar.gz civicrm/l10n --strip-components 1
    mv l10n/de_DE /var/www/html/sites/all/modules/civicrm/l10n/
    # clean
    rm -rf /tmp/*
    # permissions
    cd /var/www/html/
    chmod ug+w sites/default
    chown -R www-data:www-data sites modules themes
fi
# start php-fpm
php-fpm
