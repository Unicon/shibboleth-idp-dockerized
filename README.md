
Create your IdP config:

```
docker run -it -v $(pwd):/ext-mount --name=shib_deleteme unicon/shibboleth-idp init-idp.sh; docker rm shib_deleteme
```

> This creates a temporary container and exports the new configuration to the local file system. After the process completes, the temporary container is deleted as it is no longer needed.