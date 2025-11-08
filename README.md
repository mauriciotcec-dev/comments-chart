Chart comments-system (configurado para Docker Hub y OpenShift).

Instrucciones resumidas:
1. Sustituye TU_DOCKERHUB_USER en values.yaml por tu usuario de Docker Hub o actualiza los valores en helm --set.
2. Crear los siguientes Secrets en GitHub (repo del chart y repos de microservicios):
   - DOCKERHUB_USERNAME
   - DOCKERHUB_TOKEN
   - KUBECONFIG_BASE64
   - MONGO_PASSWORD
3. Push de los repos de microservicios para que los workflows construyan y publiquen las imágenes en Docker Hub.
4. Ejecuta el workflow de deploy (o push a main) en el repo comments-chart: el workflow instala 'oc', crea/aplica el secret 'regcred' en el namespace y despliega con Helm.
