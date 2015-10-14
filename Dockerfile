FROM centos:centos7

MAINTAINER Unicon, Inc.

ENV JETTY_HOME=/opt/jetty-home \
    JETTY_BASE=/opt/shib-jetty-base\ 
    JETTY_MAX_HEAP=512m \
    PATH=$PATH:$JRE_HOME/bin:/opt/container-scripts

RUN yum -y update \
    && yum -y install wget tar \
    && yum -y clean all

# Download Java, verify the hash, and install
RUN set -x; \
    java_version=8u60; \
    java_semver=1.8.0_60; \
    java_hash=899d9f09d7c1621a5cce184444b0ba97a8b0391bd85b624ea29f81a759764c55; \
    wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/$java_version-b27/server-jre-$java_version-linux-x64.tar.gz \
    && echo "$java_hash  server-jre-$java_version-linux-x64.tar.gz" | sha256sum -c - \
    && tar -zxvf server-jre-$java_version-linux-x64.tar.gz -C /opt \
    && rm server-jre-$java_version-linux-x64.tar.gz \
    && ln -s /opt/jdk$java_semver/ /opt/jre-home \

# Download Jetty, verify the hash, and install, initialize a new base \
    && jetty_version=9.3.3.v20150827; \
    jetty_hash=10ff46a7e6d89e28472fcd377372b62919597d36; \
    wget -O jetty-distribution-$jetty_version.tar.gz "https://eclipse.org/downloads/download.php?file=/jetty/$jetty_version/dist/jetty-distribution-$jetty_version.tar.gz&r=1" \
    && echo "$jetty_hash  jetty-distribution-$jetty_version.tar.gz" | sha1sum -c - \
    && tar -zxvf jetty-distribution-$jetty_version.tar.gz -C /opt \
    && rm jetty-distribution-$jetty_version.tar.gz \
    && ln -s /opt/jetty-distribution-$jetty_version/ /opt/jetty-home \

# Config Jetty \
    && cp /opt/jetty-home/bin/jetty.sh /etc/init.d/jetty \
    && sed -i -e 's/"-Djetty\.logging\.dir=$JETTY_LOGS"//g' /etc/init.d/jetty \
    && mkdir -p /opt/shib-jetty-base/modules /opt/shib-jetty-base/lib/ext /opt/shib-jetty-base/resources \
    && cd /opt/shib-jetty-base \
    && touch start.ini \
    && /opt/jre-home/bin/java -jar ../jetty-home/start.jar --add-to-startd=http,https,deploy,ext,annotations,jstl

# Download Shibboleth IdP, verify the hash, and install
RUN set -x; \
    idp_version=3.1.2; \
    idp_hash=2519918257f77a80816de3bdb56b940a9f59325b6aa550aad53800291c1dec04; \
    wget https://shibboleth.net/downloads/identity-provider/$idp_version/shibboleth-identity-provider-$idp_version.tar.gz \
    && echo "$idp_hash  shibboleth-identity-provider-$idp_version.tar.gz" | sha256sum -c - \
    && tar -zxvf  shibboleth-identity-provider-$idp_version.tar.gz -C /opt \
    && rm -r /shibboleth-identity-provider-$idp_version.tar.gz \
    && ln -s /opt/shibboleth-identity-provider-$idp_version/ /opt/shibboleth-idp

# Download the library to allow SOAP Endpoints, verify the hash, and place
RUN set -x; \
    dta_hash=2f547074b06952b94c35631398f36746820a7697; \
    wget https://build.shibboleth.net/nexus/content/repositories/releases/net/shibboleth/utilities/jetty9/jetty9-dta-ssl/1.0.0/jetty9-dta-ssl-1.0.0.jar \
    && echo "$dta_hash  jetty9-dta-ssl-1.0.0.jar" | sha1sum -c - \
    && mv jetty9-dta-ssl-1.0.0.jar /opt/shib-jetty-base/lib/ext/

COPY container-scripts/ /opt/container-scripts/

# Creating runtime user and tightening permissions
RUN useradd jetty -U -s /bin/false \
    && chown -R root:jetty /opt \
    && chmod -R 640 /opt \
    && chmod 750 /opt/container-scripts/run-jetty.sh \
    && chmod 750 /opt/jre-home/bin/java

# Opening 8443 (browser TLS), 9443 (SOAP/mutual TLS auth).
EXPOSE 8443 9443

VOLUME ["/opt/shib-jetty-base/logs"]

CMD ["/opt/container-scripts/run-jetty.sh"]
