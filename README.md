[![](https://badge.imagelayers.io/unicon/shibboleth-idp:latest.svg)](https://imagelayers.io/?images=unicon/shibboleth-idp:latest 'image layer analysis')

# Major Change
This image is now based on OpenJDK-based Zulu and not Oracle Java. Some Shibboleth IdP adoptors have had issues with various OpenJDK releases. However, Zulu is a roboust, certified version of OpenJDK and initial testing with it has been positive.

Docker Hub images have been updated utilizing Zulu. Instructions for switching to Oracle Java for local deployments can be view on the [project wiki](https://github.com/Unicon/shibboleth-idp-dockerized/wiki).

## Overview
This Docker image contains a deployed Shibboleth IdP 3.3.3 running on OpenJDK-based Zulu 8 Update 163 and Jetty 9.3.23 running on the latest CentOS 7 base. This image is a base image and should be used to set the configuration with local changes. 

Every component (Java, Jetty, Shibboleth IdP, and extensions) in this image is verified using cryptographic hashes obtained from each vendor and stored in the Dockerfile directly. This makes the build essentially deterministic. 

A working example of how this image can be used can be found at https://github.com/UniconLabs/dockerized-idp-testbed.

## Tags
Currently maintained tags:

* lastest: master branch
* 3.3.3 - The latest 3.3.3 image
* 3.3.2 - The latest 3.3.2 image

There are also date-based tags tied to versions to allow users to maintain consistency between minor changes, such as Jetty or Java version upgrades. See https://github.com/Unicon/shibboleth-idp-dockerized/wiki/Tags for details.

Retired tags:
* 3.3.1 - The latest 3.3.1 image
* 3.3.0 - The latest 3.3.0 image
* 3.2.1 - The latest 3.2.1 image
* 3.2.0 - The latest 3.2.0 image
* 3.1.2 - The latest 3.1.2 image

Retired tags contain a valid version of the IdP, but are no longer rev'd when new Java and Jetty releaseds are made. Other tags may exists but either are no longer maintained or are not considered production ready.

## Creating a Shibboleth IdP Configuration
Assuming that you do not already have one, create your initial IdP configuration by run with:

```
docker run -it -v $(pwd):/ext-mount --rm unicon/shibboleth-idp init-idp.sh
```

> This downloads the base image, if it does not already exists, creates a temporary container, and exports the new configuration to the local (Docker Host) file system. After the process completes, the temporary Docker container is deleted as it is no longer needed.

The files in the `customized-shibboleth-idp/` directory are your IdP specific files. Safe guard them, especially the `credentials/` directory. You will apply these files to the IdP base image in your own custom image.

Also, included are directories that one would often customized, such as the images, css, and page templates themselves. The baseline files have been exported and can be modified.

## Using the Image
You can use this image as a base image for one's own IdP deployment. Assuming that you have a layout with your configuration, credentials, and war customizations (see above). The directory structure could look like:

```
[basedir]
|-- .dockerignore
|-- Dockerfile
|-- shibboleth-idp/
|   |-- conf/
|   |   |-- attribute-filter.xml
|   |   |-- attribute-resolver.xml
|   |   |-- credentials.xml
|   |   |-- idp.properties
|   |   |-- ldap.properties
|   |   |-- login.config
|   |   |-- metadata-providers.xml
|   |   |-- relying-party.xml
|   |   |-- services.xml
|   |-- credentials/
|   |   |-- idp-backchannel.crt
|   |   |-- idp-backchannel.p12
|   |   |-- idp-browser.p12
|   |   |-- idp-encryption.crt
|   |   |-- idp-encryption.key
|   |   |-- idp-signing.crt
|   |   |-- idp-signing.key
|   |   |-- sealer.jks
|   |   |-- sealer.kver
|   |-- metadata/
|   |   |-- idp-metadata.xml
|   |   |-- [sp metadatafiles]
|   |-- webapp/
|   |   |-- images/
|   |   |   |-- dummylogo-mobile.png
|   |   |   |-- dummylogo.png
|   |   |-- WEB-INF/
|   |   |   |-- web.xml
|   |-- views/
|   |   |   |-- login.vm
|   |   |   |-- logout.vm
```

Next, assuming you create a Dockerfile similar to this example:

```
FROM unicon/shibboleth-idp

MAINTAINER <your_contact_email>

ADD shibboleth-idp/ /opt/shibboleth-idp/
```

The dependant image can be built by running:

```
docker pull centos:centos7
docker build --tag="<org_id>/shibboleth-idp:<version>" .
```

> This will download the base image from the Docker Hub repository. Next, your files are overlaid replacing the base image's counter-parts.

Now, execute the new/customized image:

```
$ docker run -d --name="shib-local-test" <org_id>/shibboleth-idp 
```

> This is the base command-line used to start the container. The container will likely fail to initialize if this limited command-line is used. You'll likely need to specify additional parameters to start-up the IdP.

## Run-time Parameters
Start the IdP will take several parameters. The following parameters can be specified when `run`ning a new IdP container:

### Port Mappings
The image exposes two ports. `4443` is the for standard browser-based TLS communication. `8443` is the backchannel TLS communication port. These ports will need to be mapped to the Docker host so that communication can occur.

* `-P`: Used to indicate that the Docker Service should map all exposed container ports to ephemeral host ports. Use `docker ps` to see the mappings.
* `-p <host>:<container>`: Explicitly maps the host ports to the container's exposed ports. This parameters can be used multiple times to map multiple sets of ports. `-p 443:4443` would make the IdP accessible on `https://<docker_host_ip>/idp/`. 

### Environmental variables
The container will use environmental variables to control IdP functionality at runtime. Currently there are 3 such variables that can be set from the `docker run` command:

* `-e JETTY_BROWSER_SSL_KEYSTORE_PASSWORD=<changeme>`: The password for the browser TLS p12 key store (`/opt/shibboleth-idp/credentials/idp-browser.p12`). Defaults to `changeme`.
* `-e JETTY_BACKCHANNEL_SSL_KEYSTORE_PASSWORD=<changeme>`: The password for the browser TLS p12 key store (`/opt/shibboleth-idp/credentials/idp-backchannel.p12`). Defaults to `changeme`.
* `-e JETTY_MAX_HEAP=<2048m>`: Specifies the maximum heap sized used by Jetty's child process to run the IdP application.

### Volume Mount
The IdP container does not explicitally need any volumes mapped for operation, but the option does exist using the following format:

* `-v <hostDir:containerDir`

It maybe desirable to map things like  `/opt/shibboleth-idp/logs` or `/opt/shibboleth-idp/credentials` to host-side storage.

## Notables
There are a few things that implementors should be aware of.

### Browser-based TLS Certificate and Key
This image expects to find the TLS certificate and key for browser based communication in `/opt/shibboleth-idp/credentials/idp-browser.p12`. This certificate can be self-signed or be signed by a commerical certificate authority. If signed by the later, the appropriate intermediate certificate(s) should be included in the .p12 file. The appopriate `openssl` commands can be found on <http://www.eclipse.org/jetty/documentation/current/configuring-ssl.html>. The container will fully start without this file. 

Changes to the key store type, location, etc. can be changed by modifying `shib-jetty-base/etc/jetty-ssl-context.xml`.

### Externalizing Secrets and Credentials
Some adopters will not want to include their secrets (key files and passwords) in their customized images. This image has been enhanced to faciliate externalizing those and connecting them in at runtime.

To do this, you will *NOT* want to include the `credentials` directory in your image. Put that directory on the Docker host. When starting the container specify `-v <Host_credentials_directory>:/opt/shibboleth-idp/credentials`. This will mount the local credentials directory into the image.

To extract out passwords, you'll want to modify the `conf/idp.properties` file, by moving sensitive entries out of the file and into a file named `idp-secrets.properties`. Save the `idp-secrets.properties` and `ldap.properties` files onto the docker host into their own directory. Also, change the `conf/idp.properties`'s `idp.additionalProperties` setting to look something like:

```
# Load any additional property resources from a comma-delimited list
idp.additionalProperties= /ext-conf/idp-secrets.properties, /ext-conf/ldap.properties, /conf/saml-nameid.properties, /conf/services.properties
```

> Note the **/ext-conf/** changes/additions in the property.

This tells the IdP to look into the `/opt/shibboleth-idp/ext-conf/` directory for the `idp-secrets.properties` and `ldap.properties` files. To mount the ext-conf directory, add `-v <Host_ext-config_directory>:/opt/shibboleth-idp/ext-conf` to the start-up parameters.

When the container starts up, if the `/opt/shibboleth-idp/ext-conf/idp-secrets.properties` file is found the TLS key files passwords will be read from the file as properties: `jetty.sslContext.keyStorePassword` (browser) and `jetty.backchannel.sslContext.keyStorePassword` (backchannel). This will preclude needing to specify them via the `-e` parameter.

### Logging 
Jetty Logs and Shibboleth IdP's `idp-process.log`are redirected to the console and are exposed via the `docker logs` command and other Docker logging methods. 

Removing the `/opt/shib-jetty-base/etc/jetty-logging.xml` (or setting it to your own configuration) will cause Jetty's default behavior to occur. Restoring the IdP's baseline `logback.xml` via overlaying will cause the default IdP file logging behavior to occur.

## Building from source:
 
```
$ docker build --tag="<org_id>/shibboleth-idp" github.com/unicon/shibboleth-idp-dockerized
```

## Recipes
Instructions for things like use the Oracle JVM and JCE with this image can be found at <https://github.com/Unicon/shibboleth-idp-dockerized/wiki/>.

## Authors/Contributors

  * John Gasper (<jgasper@unicon.net>)

## LICENSE

Copyright 2016 Unicon, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
