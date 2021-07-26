#!/usr/bin/env bash

set -e

if [[ -z ${SERVER_NAME} || -z ${PHP_SERVICE} ]]; then
    exec "$@"
    exit 1
fi

convertMageMultiSite() {
    local result=''
    local sites=()

    mapfile -t sites < <(echo "${1}" | tr '=' "\n")

    for item in "${sites[@]}"; do
        mapfile -t item < <(echo "${item}" | tr '=' "\n")
        if [[ "$result" != '' ]]; then
            result="$result\n\t"
        fi

        result="$result${item[0]}\t${item[1]};"
    done

    echo "$result"
}

getServerNameMageMultiSite() {
    local result=''
    local sites=()

    mapfile -t sites < <(echo "${1}" | tr '=' "\n")

    for item in "${sites[@]}"; do
        mapfile -t item < <(echo "${item}" | tr '=' "\n")
        if [[ "$result" != '' ]]; then
            result="$result "
        fi

        result="$result${item[0]}"
    done

    echo "$result"
}

createVhostFile() {
    local server=$1
    local rootFolder=$2
    local isHttps=$3
    local isMage=$4
    local isMageMulti=$5
    local mageMode=$6
    local mageType=$7
    local mageSites=$8
    local mageSitesFinal=''
    local fileTemp="/etc/nginx/conf.d/$1.conf"
    local siteFolder="/etc/nginx/vhost/http"

    if [[ "$isHttps" == "true" ]]; then
        siteFolder="/etc/nginx/vhost/https"
        creatSslKey
    fi

    if [[ "$isMage" != "true" ]]; then # Not Magento
        cp -f "${siteFolder}/mysite.conf" "${fileTemp}"
    else # Magento
        if [[ "$isMageMulti" != "true" ]]; then # Magento single domain
            cp -f "${siteFolder}/magento.conf" "${fileTemp}"
        else # Magento multi domain
            cp -f "${siteFolder}/magento-multi.conf" "${fileTemp}"

            mageSitesFinal="$(convertMageMultiSite "${mageSites}")"
            sed -i "s/!MAGE_MULTI_SITES!/$mageSitesFinal/g" "${fileTemp}"
            sed -i "s/!MAGE_MODE!/$mageMode/g" "${fileTemp}"
            sed -i "s/!MAGE_RUN_TYPE!/$mageType/g" "${fileTemp}"
        fi
    fi

    if [[ -e ${fileTemp} ]]; then
        rootFolder=$(echo "${rootFolder}" | sed "s/\//\\\\\//g")
        sed -i "s/!SERVER_NAME!/$server/g" "${fileTemp}"
        sed -i "s/!ROOT_FOLDER!/$rootFolder/g" "${fileTemp}"
    fi
}

if [[ ! -e /etc/nginx/conf.d/${SERVER_NAME}.conf ]]; then
    createVhostFile "${SERVER_NAME}" "${ROOT_FOLDER}" "${IS_HTTPS}" "${IS_MAGENTO}" "${IS_MAGENTO_MULTI}" "${MAGENTO_MODE}" "${MAGENTO_RUN_TYPE}" "${MAGENTO_MULTI_SITES}"
fi

# Config php
sed -i "s/!PHP_SERVICE!/$PHP_SERVICE/g" /etc/nginx/conf.d/php.conf
sed -i "s/!PHP_PORT!/$PHP_PORT/g" /etc/nginx/conf.d/php.conf

# Update nginx config
if [[ "${NGINX_CONFIG}" != '' ]]; then
    mapfile -t NGINX_CONFIG < <(echo "${NGINX_CONFIG}" | tr ',' "\n")
    for item in "${NGINX_CONFIG[@]}"; do
        mapfile -t item < <(echo "${item}" | tr '=' "\n")
        configName=$(echo "${item[0]}" | tr '[:upper:]' '[:lower:]')
        configValue=${item[1]}

        sed -i "/${configName}/d" /etc/nginx/conf.d/zz-docker.conf
        printf "%s\t%s;\n" "${configName}" "${configValue}" >>/etc/nginx/conf.d/zz-docker.conf
    done
fi

nginx -t

exec "$@"
