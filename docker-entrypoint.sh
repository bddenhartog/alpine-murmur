#!/usr/bin/env sh
set -e

CONFIGFILE="/etc/murmur/murmur.ini"
ICEFILE="/etc/murmur/ice.ini"
WELCOMEFILE="/data/welcometext"

setVal() {
    if [ -n "$1" ] && [ -n "$2" ]; then
        echo "update setting: ${1} with: ${2}"
        sed -i -E 's;#?('"$1"'=).*;\1'"$2"';' "$CONFIGFILE"
    fi
}

setVal ice "$MUMBLE_ICE"
setVal icesecretread "$MUMBLE_ICESECRETREAD"
setVal icesecretwrite "$MUMBLE_ICESECRETWRITE"
setVal autobanAttempts "$MUMBLE_AUTOBANATTEMPTS"
setVal autobanTimeframe "$MUMBLE_AUTOBANTIMEFRAME"
setVal autobanTime "$MUMBLE_AUTOBANTIME"
setVal serverpassword "$MUMBLE_SERVERPASSWORD"
setVal obfuscate "$MUMBLE_OBFUSCATE"
setVal sendversion "$MUMBLE_SENDVERSION"
setVal legacyPasswordHash "$MUMBLE_LEGACYPASSWORDHASH"
setVal kdfIterations "$MUMBLE_KDFITERATIONS"
setVal allowping "$MUMBLE_ALLOWPING"
setVal bandwidth "$MUMBLE_BANDWIDTH"
setVal timeout "$MUMBLE_TIMEOUT"
setVal certrequired "$MUMBLE_CERTREQUIRED"
setVal users "$MUMBLE_USERS"
setVal usersperchannel "$MUMBLE_USERSPERCHANNEL"
setVal username "$MUMBLE_USERNAME"
setVal channelname "$MUMBLE_CHANNELNAME"
setVal channelnestinglimit "$MUMBLE_CHANNELNESTINGLIMIT"
setVal defaultchannel "$MUMBLE_DEFAULTCHANNEL"
setVal rememberchannel "$MUMBLE_REMEMBERCHANNEL"
setVal textmessagelength "$MUMBLE_TEXTMESSAGELENGTH"
setVal imagemessagelength "$MUMBLE_IMAGEMESSAGELENGTH"
setVal allowhtml "$MUMBLE_ALLOWHTML"
setVal opusthreshold "$MUMBLE_OPUSTHRESHOLD"
setVal messagelimit "$MUMBLE_MESSAGELIMIT"
setVal messageburst "$MUMBLE_MESSAGEBURST"
setVal registerHostname "$MUMBLE_REGISTERHOSTNAME"
setVal registerPassword "$MUMBLE_REGISTERPASSWORD"
setVal registerUrl "$MUMBLE_REGISTERURL"
setVal registerName "$MUMBLE_REGISTERNAME"
setVal suggestVersion "$MUMBLE_SUGGESTVERSION"
setVal suggestPositional "$MUMBLE_SUGGESTPOSITIONAL"
setVal suggestPushToTalk "$MUMBLE_SUGGESTPUSHTOTALK"

if [ -n "${MUMBLE_ENABLESSL}" ] && [ "${MUMBLE_ENABLESSL}" -eq 1 ]; then
    SSL_CERTFILE="${MUMBLE_CERTFILE:-/data/cert.pem}"
    SSL_KEYFILE="${MUMBLE_KEYFILE:-/data/key.pem}"
    SSL_CAFILE="${MUMBLE_CAFILE:-/data/intermediate.pem}"
    SSL_DHFILE="${MUMBLE_DHFILE:-/data/dh.pem}"

    if [ -f "$SSL_CERTFILE" ]; then
        setVal sslCert "$SSL_CERTFILE"
    fi

    if [ -f "$SSL_KEYFILE" ]; then
        setVal sslKey "$SSL_KEYFILE"
        setVal sslPassPhrase "$MUMBLE_SSLPASSPHRASE"
    fi

    if [ -f "$SSL_CAFILE" ]; then
        setVal sslCA "$SSL_CAFILE"
    fi

    if [ -f "$SSL_DHFILE" ]; then
        setVal sslDHParams "$SSL_DHFILE"
    fi

    setVal sslCiphers "$MUMBLE_SSLCIPHERS"
fi

if [ -f "$WELCOMEFILE" ]; then
    parsedContent=$(sed -E 's/"/\\"/g' "$WELCOMEFILE")
    setVal welcometext "\"${parsedContent}\""
fi

if ! grep -q '\[Ice\]' "$CONFIGFILE"; then
    echo "" >> "$CONFIGFILE"
    cat "$ICEFILE" >> "$CONFIGFILE"
fi

chown -R murmur:nobody /data/

if [ ! -f /data/murmur.sqlite ]; then
    if [ -z "${SUPERUSER_PASSWORD+x}" ]; then
        SUPERUSER_PASSWORD=$(pwgen -cns1 36)
    fi

    echo "SUPERUSER_PASSWORD: $SUPERUSER_PASSWORD"

    # Using -supw currently throws a fatal error and exits the program. It has
    # been fixed in the upstream project by commit d8203ba94 [1], but has not
    # yet been included in a release. To bypass the issue and allow the entrypoint
    # script to proceed, we are ignoring the erroneous exit code by executing
    # `true` if the invocation fails.
    #
    # IMPORTANT
    # Before removing this workaround, be sure to check that the upstream
    # release actually contains the commit:
    #
    #     git clone git@github.com:mumble-voip/mumble.git
    #     git -C mumble tag --contains d8203ba94d528b092e0ff5a52a51af28f8f592f1 <ref>
    #
    # This was previously erroneously removed. See [2] for more information.
    #
    # [1]: https://github.com/mumble-voip/mumble/commit/d8203ba94d528b092e0ff5a52a51af28f8f592f1
    # [2]: https://github.com/sudoforge/docker-mumble-server/issues/121
    /opt/murmur/murmur.x86 -ini "$CONFIGFILE" -supw "$SUPERUSER_PASSWORD" || true
fi

# Run murmur if not in debug mode
if [ -z "$DEBUG" ] || [ "$DEBUG" -ne 1 ]; then
    exec /opt/murmur/murmur.x86 -fg -ini "$CONFIGFILE"
fi
