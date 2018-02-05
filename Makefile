#GNU Make file to easier the build commands and steps


.PHONY: dcompose-deploy dcompose-clean k8s-deploy kdeployVolumes  kdeploy kservice cleam clean-volumes clean-deploy clean-svc minikube-image


#------------------------#
# Docker-Compose part
#------------------------#
dcompose-deploy:
	   ${INFO} "Build App image"
	   @ docker-compose build
		 ${INFO} "Bootstrape DB"
		 @ docker-compose run --user "$(id -u):$(id -g)" drkiq rake db:reset
		 @ docker-compose run --user "$(id -u):$(id -g)" drkiq rake db:migrate
		 ${INFO} "Run Docker-compose service"
		 @ docker-compose up -d
		 ${INFO} "For testing ,run  curl http://localhost:8000 Search for <h1>The meaning of life is 42</h1> "

dcompose-clean:
	   ${INFO} "Remove Containers & Volumes"
		 @ docker-compose down -v

#----------------------------------------------------------------------------------------------------------------#
clean: clean-volumes clean-deploy clean-svc clean-configmap

clean-volumes:
		 ${INFO} "Deleteing persistant-volumes - Data lost forever"
		 @ kubectl delete persistentvolumeclaim drkiq-postgres drkiq-redis


clean-deploy:
		${INFO} "Delete All deployments"
		@ kubectl delete deploy drkiq sidekiq redis postgres
		${INFO} "Delete Jobs"
		@ kubectl delete job resetdb


clean-svc:
	  ${INFO} "Clean all service"
		@ kubectl delete svc drkiq sidekiq redis postgres

clean-configmap:
	  ${INFO} "Clean ConfigMap"
		@kubectl delete configmap special-config1
#-----------------------------------------------------#
k8s-deploy: kdeployVolumes kdeploy kservices kdeploycongigMap showall

kdeployVolumes:
		${INFO} "Deploy persistentVolumes"
		@ kubectl create -f k8s/volumes/drkiq-postgres-persistentvolumeclaim.yaml
		@ kubectl create -f k8s/volumes/drkiq-redis-persistentvolumeclaim.yaml
	  ${INFO} "List of created Volumes"
		@ kubectl get persistentvolume

kdeploycongigMap:
	  ${INFO} "Deploy COnfigMap"
		@ kubectl create configmap special-config1  --from-literal=SECRET_TOKEN=asecuretokenwouldnormallygohere \
                                          --from-literal=WORKER_PROCESSES=1 \
                                          --from-literal=LISTEN_ON=0.0.0.0:8000 \
                                          --from-literal=CACHE_URL=redis://redis:6379/0 \
                                          --from-literal=JOB_WORKER_URL=redis://redis:6379/0 \
                                          --from-literal=DATABASE_URL=postgresql://drkiq:yourpassword@postgres:5432/drkiq?encoding=utf8&pool=5&timeout=5000

kdeploy:
	${INFO} "Deploy All Pods to K8s"
	${INFO} "Deploy Postgres"
	@ kubectl create -f k8s/deploy/postgres-deployment.yaml
	${INFO} "Deploy Redis"
	@ kubectl create -f k8s/deploy/redis-deployment.yaml
	${INFO} "Deploy resetdb job"
	@ kubectl create -f k8s/jobs/dbreset.yaml
	${INFO} "Deploy drkiq"
	@ kubectl create -f k8s/deploy/drkiq-deployment.yaml
	${INFO} "Deploy sidekiq"
	@ kubectl create -f k8s/deploy/sidekiq-deployment.yaml

kservices:
	${INFO} "Deploy services to K8s"
	@ kubectl create -f k8s/svc/drkiq-service.yaml
	@ kubectl create -f k8s/svc/sidekiq-service.yaml
	@ kubectl create -f k8s/svc/redis-service.yaml
	@ kubectl create -f k8s/svc/postgres-service.yaml

showall:
	@ kubectl get all

rerun-resetdb:
	${INFO} "Resetting Postgres DB"
	@ kubectl get job "resetdb" -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels)' | kubectl replace --force -f -

minikube-image:
	@ docker build . -t=drkiq
	@ docker tag drkiq sidekiq

# Output-color Settings
YELLOW := "\e[1;33m"
NC := "\e[0m"

# INFO Function
INFO := @bash -c '\
printf $(YELLOW); \
echo "=> $$1"; \
printf $(NC)' SOME_VALUE
