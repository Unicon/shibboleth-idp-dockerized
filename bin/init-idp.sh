#!/bin/bash

export JAVA_HOME=/opt/jre-home
export PATH=$PATH:$JAVA_HOME/bin

cd /opt/shibboleth-idp/bin

# Remove existing config to build starts with an empty config
rm -r ../conf/

echo "Please complete the following for your IdP environment:"
./build.sh -Didp.target.dir=/opt/shibboleth-idp init gethostname askscope metadata-gen

mkdir -p /ext-mount/customized-shibboleth-idp/conf/

# Copy the essential and routinely customized config to out Docker mount.
cd ..
cp -r credentials/ /ext-mount/customized-shibboleth-idp/
cp -r metadata/ /ext-mount/customized-shibboleth-idp/
cp conf/{attribute-resolver.xml,attribute-filter.xml,cas-protocol.xml,idp.properties,ldap.properties,metadata-providers.xml,relying-party.xml,saml-nameid.xml} /ext-mount/customized-shibboleth-idp/conf/

# Copy the basic UI components, which are routinely customized
cp -r views/ /ext-mount/customized-shibboleth-idp/
mkdir /ext-mount/customized-shibboleth-idp/webapp/
cp -r webapp/css/ /ext-mount/customized-shibboleth-idp/webapp/
cp -r webapp/images/ /ext-mount/customized-shibboleth-idp/webapp/
cp -r webapp/js/ /ext-mount/customized-shibboleth-idp/webapp/
rm -r /ext-mount/customized-shibboleth-idp/views/user-prefs.js

echo "A basic Shibboleth IdP config and UI has been copied to ./customized-shibboleth-idp/ (assuming the default volume mapping was used)."
echo "Most files, if not being customized can be removed from what was exported/the local Docker image and baseline files will be used."
