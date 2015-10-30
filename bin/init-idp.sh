#!/bin/bash

export JAVA_HOME=/opt/jre-home
export PATH=$PATH:$JAVA_HOME/bin

cd /opt/shibboleth-idp/bin

# Remove existing config to build starts with an empty config
rm -r ../conf/

./build.sh -Didp.target.dir=/opt/shibboleth-idp init gethostname askscope metadata-gen

mkdir -p /ext-mount/customized-shibboleth-idp/conf/

# Copy the essential and routinely customized config to out Docker mount.
cd ..
cp -r credentials/ /ext-mount/customized-shibboleth-idp/
cp -r metadata/ /ext-mount/customized-shibboleth-idp/
cp conf/{attribute-resolver.xml,attribute-filter.xml,cas-protocol.xml,idp.properties,ldap.properties,metadata-providers.xml,relying-party.xml,saml-nameid.xml} /ext-mount/customized-shibboleth-idp/conf/

echo "A basic Shibboleth IdP config has been copied to ./customized-shibboleth-idp/ (assuming the default volume mapping was used)."