
vtotalsubs() {
    curl https://www.virustotal.com/vtapi/v2/domain/report\?apikey\=$VT_KEY\&domain\=$1 | jq -r
}

ipinfo() {
    curl http://ipinfo.io/$1
}

crtsh() {
    curl -s https://crt.sh/?Identity=%.$1 | grep ">*.$1" | sed 's/<[/]*[TB][DR]>/\n/g' | grep -vE "<|^[\*]*[\.]*$1" | sort -u | awk 'NF'
}

urlencode() { # -s encodes chars considered unreserved by RFC 3986. pipe stdout (echo "/hello/" | urlencode [-s])
    local strict=0
    local input

    if [[ "$1" == "-s" || "$1" == "--strict" ]]; then
        strict=1
        shift
    fi

    if [ $# -eq 0 ]; then
        input=$(cat)
    else
        input="$1"
    fi

    local LC_ALL=C
    for (( i = 0; i < ${#input}; i++ )); do
        c="${input:i:1}"
        if (( strict )); then
            case "$c" in
                [a-zA-Z0-9])
                    printf '%s' "$c"
                    ;;
                *)
                    printf '%%%02X' "'$c"
                    ;;
            esac
        else
            case "$c" in
                [a-zA-Z0-9.~_-])
                    printf '%s' "$c"
                    ;;
                *)
                    printf '%%%02X' "'$c"
                    ;;
            esac
        fi
    done
    printf '\n'
}

