#!/bin/sh

#set -x

export JAVA_HOME=/opt/jre-home
export PATH=$PATH:$JAVA_HOME/bin
export JETTY_CONF=none

if [ -e "/opt/shibboleth-idp/ext-conf/idp-secrets.properties" ]; then
  export keyStorePassword=`awk '/idp.sealer.storePassword/{print $NF}' /opt/shibboleth-idp/ext-conf/idp-secrets.properties`
  export JETTY_ARGS="jetty.backchannel.sslContext.keyStorePassword=$keyStorePassword"
fi

sed -i "s/^-Xmx.*$/-Xmx$JETTY_MAX_HEAP/g" /opt/shib-jetty-base/start.ini

echo "Use of this image/container constitutes acceptence of the Oracle Binary Code License Agreement for Java SE."

exec /etc/init.d/jetty run