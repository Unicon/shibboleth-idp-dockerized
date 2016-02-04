FROM centos:centos7

MAINTAINER Unicon, Inc.

LABEL idp.java.version="1.8.0_71" \
      idp.jetty.version="9.3.7.v20160115" \
      idp.version="3.2.0"

ENV JETTY_HOME=/opt/jetty-home \
    JETTY_BASE=/opt/shib-jetty-base\ 
    JETTY_MAX_HEAP=512m \
    JETTY_BROWSER_SSL_KEYSTORE_PASSWORD=changeme \
    JETTY_BACKCHANNEL_SSL_KEYSTORE_PASSWORD=changeme \
    PATH=$PATH:$JRE_HOME/bin

RUN yum -y update \
    && yum -y install wget tar which \
    && yum -y clean all

RUN set -x; \
    java_version=8u71; \
    java_bnumber=15; \
    java_semver=1.8.0_71; \
    java_hash=429c3184b10d7af2bb5db3faf20b467566eb5bd95778f8339352c180c8ba48a1; \
    jetty_version=9.3.7.v20160115; \
    jetty_hash=8d957f7223a3f3b795a79952f8e8081e93cf06b0; \
    idp_version=3.2.0; \
    idp_hash=302c45a4e0814e97a1c01950137d328e0a8630638b35bdd6ae50af9510bcea84; \
    dta_hash=2f547074b06952b94c35631398f36746820a7697; \

    useradd jetty -U -s /bin/false \

# Download Java, verify the hash, and install \
    && cd / \
    && wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/$java_version-b$java_bnumber/server-jre-$java_version-linux-x64.tar.gz \
    && echo "$java_hash  server-jre-$java_version-linux-x64.tar.gz" | sha256sum -c - \
    && tar -zxvf server-jre-$java_version-linux-x64.tar.gz -C /opt \
    && rm server-jre-$java_version-linux-x64.tar.gz \
    && ln -s /opt/jdk$java_semver/ /opt/jre-home \

# Download Jetty, verify the hash, and install, initialize a new base \
    && cd / \
    && wget -O jetty-distribution-$jetty_version.tar.gz "https://eclipse.org/downloads/download.php?file=/jetty/$jetty_version/dist/jetty-distribution-$jetty_version.tar.gz&r=1" \
    && echo "$jetty_hash  jetty-distribution-$jetty_version.tar.gz" | sha1sum -c - \
    && tar -zxvf jetty-distribution-$jetty_version.tar.gz -C /opt \
    && rm jetty-distribution-$jetty_version.tar.gz \
    && ln -s /opt/jetty-distribution-$jetty_version/ /opt/jetty-home \

# Config Jetty \
    && cd / \
    && cp /opt/jetty-home/bin/jetty.sh /etc/init.d/jetty \
    && sed -i -e 's/"-Djetty\.logging\.dir=$JETTY_LOGS"//g' /etc/init.d/jetty \
    && mkdir -p /opt/shib-jetty-base/modules /opt/shib-jetty-base/lib/ext /opt/shib-jetty-base/resources \
    && cd /opt/shib-jetty-base \
    && touch start.ini \
    && /opt/jre-home/bin/java -jar ../jetty-home/start.jar --add-to-startd=http,https,deploy,ext,annotations,jstl \

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

# Setting owner ownership and permissions on new items in this command
    && chown -R root:jetty /opt \
    && chmod -R 640 /opt \
    && chmod 750 /opt/jre-home/bin/java \
    && chmod 750 /opt/jre-home/jre/bin/java
    
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
