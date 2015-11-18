## Overview
This Docker image contains a deployed Shibboleth IdP 3.1.2 running on Java Runtime 1.8 update 65 and Jetty 9.3.5 running on the latest CentOS 7 base. This image is a base image and should be used to set the configuration with local changes. 

Every component (Java, Jetty, Shibboleth IdP, and extensions) in this image is verified using cryptographic hashes obtained from each vendor and stored in the Dockerfile directly. This makes the build essentially deterministic. 

> Use of this image requires acceptance of the *Oracle Binary Code License Agreement for the Java SE Platform Products*  (<http://www.oracle.com/technetwork/java/javase/terms/license/index.html>).

## Creating a Shibboleth IdP Configuration
To create your initial IdP config, run it with:

```
docker run -it -v $(pwd):/ext-mount --name=shib_deleteme unicon/shibboleth-idp init-idp.sh; docker rm shib_deleteme
```

> This downloads the base image, if it does not already exists, creates a temporary container and exports the new configuration to the local file system. After the process completes, the temporary container is deleted as it is no longer needed.

The files in the `customized-shibboleth-idp/` directory are your idp specific files. Safe guard them, especially the `credentials/` directory.

## Using the Image
This image is ideal for use as a base image for ones own deployment. 

Assuming that you have a similar layout with your configuration, credentials, and war customizations. The directory structure could look like:

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
|   |   |-- idp-encryption.crt
|   |   |-- idp-encryption.key
|   |   |-- idp-signing.crt
|   |   |-- idp-signing.key
|   |   |-- sealer.jks
|   |   |-- sealer.kver
|   |-- metadata/
|   |   |-- idp-metadata.xml
|   |   |-- [sp metadatafiles.xml]
|   |-- webapp/
|   |   |-- images/
|   |   |   |-- dummylogo-mobile.png
|   |   |   |-- dummylogo.png
|   |   |-- WEB-INF/
|   |   |   |-- web.xml
```

Next, assuming you create a Dockerfile similar to this example:

```
FROM unicon/shibboleth-idp

MAINTAINER <your_contact_email>

ADD shibboleth-idp/ /opt/shibboleth-idp/
```

The dependant image can be built by running:

```
docker build --tag="<org_id>/shibboleth-idp" .
```

> This will download the base image that is available in the Docker Hub repository. Next, your files are overlaid replacing the base image's counter-parts.

Now, execute the new image:

```
$ docker run -dP --name="shib-local-test" <org_id>/shibboleth-idp 
```

**TODO: Document parameters the start**

**TODO: Document externalizing the secrets and credentials.**

## Logging 
Jetty Logs and Shibboleth IdP's `idp-process.log`are redirected to the console and are exposed via the `docker logs` command and other Docker logging methods. Restoring the baseline `logback.xml` via overlaying will cause the default file logging behavior to occur.

## Building from source:

```
$ docker build --tag="<org_id>/shibboleth-idp" github.com/unicon/shibboleth-idp-dockeriezed
```

## Authors/Contributors

  * John Gasper (<jgasper@unicon.net>)

## LICENSE

Copyright 2015 Unicon, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
