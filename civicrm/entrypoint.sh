#!/bin/bash

set -o noclobber  # Avoid overlay files (echo "hi" > foo)
set -o errexit    # Used to exit upon error, avoiding cascading errors
set -o pipefail   # Unveils hidden failures
set -o nounset    # Exposes unset variables

# These downloads have to happen in entrypoint because we are mounting whole /var/www/html in docker-compose.yml

# https://www.drupal.org/node/3060/release
DRUPAL_VERSION=7.69
DRUPAL_MD5=292290a2fb1f5fc919291dc3949cdf7c
CIVICRM_VERSION=5.20.0

set -eux;

if [[ ! -e /var/www/html/index.php ]]; then
    # downloading drupal
    curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz
    echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c -
    tar -xz --strip-components=1 -f drupal.tar.gz --directory /var/www/html/
    rm drupal.tar.gz
    # downloading drupal german language
    curl --location https://ftp.drupal.org/files/translations/${DRUPAL_VERSION:0:1}.x/drupal/drupal-${DRUPAL_VERSION}.de.po --output /var/www/html/profiles/standard/translations/drupal-${DRUPAL_VERSION}.de.po
    # downloading civicrm
    curl --location https://download.civicrm.org/civicrm-${CIVICRM_VERSION}-drupal.tar.gz --output civicrm.tar.gz
    tar -xzf civicrm.tar.gz --directory /var/www/html/sites/all/modules/
    rm civicrm.tar.gz
    # downloading civicrm german language
    curl --location https://download.civicrm.org/civicrm-${CIVICRM_VERSION}-l10n.tar.gz --output civicrm-l10n.tar.gz
    tar -xzf civicrm-l10n.tar.gz civicrm/l10n --strip-components 1
    mv l10n/de_DE /var/www/html/sites/all/modules/civicrm/l10n/
    rm civicrm-l10n.tar.gz
    # download smtp module
    curl https://ftp.drupal.org/files/projects/smtp-7.x-1.7.tar.gz | tar -xvz --directory=/var/www/html/sites/all/modules/
    # download bootstrap theme
    curl https://ftp.drupal.org/files/projects/bootstrap-7.x-3.26.tar.gz | tar -xvz --directory=/var/www/html/sites/all/themes/
    # download civimobileapi
    CIVIMOBILEAPI=4.2.1
    curl --location https://github.com/agiliway/com.agiliway.civimobileapi/archive/v${CIVIMOBILEAPI}.tar.gz | tar -xvz --directory=/var/www/html/sites/default/files/civicrm/ext/
    mv /var/www/html/sites/default/files/civicrm/ext/com.agiliway.civimobileapi-${CIVIMOBILEAPI} /var/www/html/sites/default/files/civicrm/ext/com.agiliway.civimobileapi
    # download apikey
    APIKEY=1.0
    curl --location https://github.com/cividesk/com.cividesk.apikey/archive/v${APIKEY}.tar.gz | tar -xvz --directory=/var/www/html/sites/default/files/civicrm/ext/
    mv /var/www/html/sites/default/files/civicrm/ext/com.cividesk.apikey-${APIKEY} /var/www/html/sites/default/files/civicrm/ext/com.cividesk.apikey
    # permissions
    cd /var/www/html/
    chmod ug+w sites/default
    chown -R 1001:1000 sites modules themes
fi
# start php-fpm
php-fpm
