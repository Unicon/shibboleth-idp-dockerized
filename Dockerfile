FROM centos:centos7

LABEL maintainer="Unicon, Inc."\
      idp.java.version="8.0.192" \
      idp.jetty.version="9.3.25.v20180904" \
      idp.version="3.4.0"

ENV JETTY_HOME=/opt/jetty-home \
    JETTY_BASE=/opt/shib-jetty-base \
    JETTY_MAX_HEAP=2048m \
    JETTY_BROWSER_SSL_KEYSTORE_PASSWORD=changeme \
    JETTY_BACKCHANNEL_SSL_KEYSTORE_PASSWORD=changeme \
    PATH=$PATH:$JRE_HOME/bin

RUN yum -y update \
    && yum -y install wget tar which \
    && yum -y clean all

RUN set -x; \
    java_version=8.0.192; \
    zulu_version=8.33.0.1; \
    java_hash=5db43a961b477533054504a8cbcfa5f1; \
    jetty_version=9.3.25.v20180904; \
    jetty_hash=dff5f1573d8ecbf9e6036cebcb64642173a2262d; \
    idp_version=3.4.0; \
    idp_hash=3a6bb6ec42ae22a44ad52bb108875e9699167c808645e7e43137d108841e41ad; \
    dta_hash=2f547074b06952b94c35631398f36746820a7697; \
    slf4j_hash=da76ca59f6a57ee3102f8f9bd9cee742973efa8a; \
    logback_classic_hash=7c4f3c474fb2c041d8028740440937705ebb473a; \
    logback_core_hash=864344400c3d4d92dfeb0a305dc87d953677c03c; \
    logback_access_hash=e8a841cb796f6423c7afd8738df6e0e4052bf24a; \

    useradd jetty -U -s /bin/false \

# Download Java, verify the hash, and install \
    && cd / \
    && wget http://cdn.azul.com/zulu/bin/zulu$zulu_version-jdk$java_version-linux_x64.tar.gz \
    && echo "$java_hash  zulu$zulu_version-jdk$java_version-linux_x64.tar.gz" | md5sum -c - \
    && tar -zxvf zulu$zulu_version-jdk$java_version-linux_x64.tar.gz -C /opt \
    && rm zulu$zulu_version-jdk$java_version-linux_x64.tar.gz \
    && ln -s /opt/zulu$zulu_version-jdk$java_version-linux_x64/jre/ /opt/jre-home \

# Download Jetty, verify the hash, and install, initialize a new base \
    && cd / \
    && wget http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$jetty_version/jetty-distribution-$jetty_version.tar.gz \
    && echo "$jetty_hash  jetty-distribution-$jetty_version.tar.gz" | sha1sum -c - \
    && tar -zxvf jetty-distribution-$jetty_version.tar.gz -C /opt \
    && rm jetty-distribution-$jetty_version.tar.gz \
    && ln -s /opt/jetty-distribution-$jetty_version/ /opt/jetty-home \

# Config Jetty \
    && cd / \
    && cp /opt/jetty-home/bin/jetty.sh /etc/init.d/jetty \
    && mkdir -p /opt/shib-jetty-base/modules /opt/shib-jetty-base/lib/ext  /opt/shib-jetty-base/lib/logging /opt/shib-jetty-base/resources \
    && cd /opt/shib-jetty-base \
    && touch start.ini \
    && /opt/jre-home/bin/java -jar ../jetty-home/start.jar --add-to-startd=http,https,deploy,ext,annotations,jstl,rewrite \

# Download Shibboleth IdP, verify the hash, and install \
    && cd / \
    && wget https://shibboleth.net/downloads/identity-provider/$idp_version/shibboleth-identity-provider-$idp_version.tar.gz \
    && echo "$idp_hash  shibboleth-identity-provider-$idp_version.tar.gz" | sha256sum -c - \
    && tar -zxvf  shibboleth-identity-provider-$idp_version.tar.gz -C /opt \
    && rm /shibboleth-identity-provider-$idp_version.tar.gz \
    && ln -s /opt/shibboleth-identity-provider-$idp_version/ /opt/shibboleth-idp \

# Download the library to allow SOAP Endpoints, verify the hash, and place \
    && cd / \
    && wget https://build.shibboleth.net/nexus/content/repositories/releases/net/shibboleth/utilities/jetty9/jetty9-dta-ssl/1.0.0/jetty9-dta-ssl-1.0.0.jar \
    && echo "$dta_hash  jetty9-dta-ssl-1.0.0.jar" | sha1sum -c - \
    && mv jetty9-dta-ssl-1.0.0.jar /opt/shib-jetty-base/lib/ext/ \

# Download the slf4j library for Jetty logging, verify the hash, and place \
    && cd / \
    && wget http://central.maven.org/maven2/org/slf4j/slf4j-api/1.7.25/slf4j-api-1.7.25.jar \
    && echo "$slf4j_hash  slf4j-api-1.7.25.jar" | sha1sum -c - \
    && mv slf4j-api-1.7.25.jar /opt/shib-jetty-base/lib/logging/ \

# Download the logback_classic library for Jetty logging, verify the hash, and place \
    && cd / \
    && wget http://central.maven.org/maven2/ch/qos/logback/logback-classic/1.2.3/logback-classic-1.2.3.jar \
    && echo "$logback_classic_hash  logback-classic-1.2.3.jar" | sha1sum -c - \
    && mv logback-classic-1.2.3.jar /opt/shib-jetty-base/lib/logging/ \

# Download the logback-core library for Jetty logging, verify the hash, and place \
    && cd / \
    && wget http://central.maven.org/maven2/ch/qos/logback/logback-core/1.2.3/logback-core-1.2.3.jar \
    && echo "$logback_core_hash logback-core-1.2.3.jar" | sha1sum -c - \
    && mv logback-core-1.2.3.jar /opt/shib-jetty-base/lib/logging/ \

# Download the logback-access library for Jetty logging, verify the hash, and place \
     && cd / \
    && wget http://central.maven.org/maven2/ch/qos/logback/logback-access/1.2.3/logback-access-1.2.3.jar \
    && echo "$logback_access_hash logback-access-1.2.3.jar" | sha1sum -c - \
    && mv logback-access-1.2.3.jar /opt/shib-jetty-base/lib/logging/ \


# Setting owner ownership and permissions on new items in this command
    && chown -R root:jetty /opt \
    && chmod -R 640 /opt \
    && chmod 750 /opt/jre-home/bin/java

COPY bin/ /usr/local/bin/
COPY opt/shib-jetty-base/ /opt/shib-jetty-base/
COPY opt/shibboleth-idp/ /opt/shibboleth-idp/

# Setting owner ownership and permissions on new items from the COPY command
RUN mkdir /opt/shib-jetty-base/logs \
    && chown -R root:jetty /opt/shib-jetty-base \
    && chmod -R 640 /opt/shib-jetty-base \
    && chmod -R 750 /opt/shibboleth-idp/bin \
    && chmod 750 /usr/local/bin/run-jetty.sh /usr/local/bin/init-idp.sh

# Opening 4443 (browser TLS), 8443 (mutual auth TLS)
EXPOSE 4443 8443

CMD ["run-jetty.sh"]
