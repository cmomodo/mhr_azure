# Push and Deploy

Use this sequence to build the app image, push it to Azure Container Registry, and update the Azure Container App.
Replace the placeholder values with the correct registry, image, app, and resource group names for the target environment.

```sh
az acr login --name <acr-name>
docker build -t <acr-login-server>/<image-name>:latest ./app
docker push <acr-login-server>/<image-name>:latest
az containerapp update \
  --name <container-app-name> \
  --resource-group <resource-group> \
  --image <acr-login-server>/<image-name>:latest
```

To inspect revisions before or after a deployment:

```sh
az containerapp revision list \
  --name <container-app-name> \
  --resource-group <resource-group> \
  --query "[].{name:name,active:properties.active,createdTime:properties.createdTime,health:properties.healthState}" \
  -o table
```

To deploy a specifically tagged image instead of `latest`:

```sh
az containerapp update \
  --name <container-app-name> \
  --resource-group <resource-group> \
  --image <acr-login-server>/<image-name>:<tag>
```
