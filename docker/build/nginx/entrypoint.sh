#!/usr/bin/env bash

set -e

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

        result="$result${item[0]} www.${item[0]}"
    done

    echo "$result"
}

createVhostFile() {
    local server="$1 www.$1"
    local rootFolder=$2
    local isHttps=$3
    local isMage=$4
    local isMageMulti=$5
    local mageMode=$6
    local mageType=$7
    local mageSites=$8
    local mageSitesFinal=''
    local fileTemp="/etc/nginx/conf.d/$1.conf"

    if [[ "$isMage" != "true" ]]; then # Not Magento
        if [[ "$isHttps" != "true" ]]; then # Not use https
            cp -f /etc/nginx/vhost/mysite.conf "${fileTemp}"
        else # Use https
            cp -f /etc/nginx/vhost/https/mysite.conf "${fileTemp}"
        fi
    else # Magento
        if [[ "$isMageMulti" != "true" ]]; then # Magento single domain
            if [[ "$isHttps" != "true" ]]; then # Not use https
                cp -f /etc/nginx/vhost/magento.conf "${fileTemp}"
            else # Use https
                cp -f /etc/nginx/vhost/https/magento.conf "${fileTemp}"
            fi
        else # Magento multi domain
            if [[ "$isHttps" != "true" ]]; then # Not use https
                cp -f /etc/nginx/vhost/magento-multi.conf "${fileTemp}"
            else # Use https
                cp /etc/nginx/vhost/https/magento-multi.conf "${fileTemp}"
            fi

            mageSitesFinal="$(convertMageMultiSite "${mageSites}")"
            server="$(getServerNameMageMultiSite "${mageSites}")"
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

if [[ ! -e /etc/nginx/conf.d/${server}.conf ]]; then
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
