docker build -t notes-frontend:latest frontend/
docker tag notes-frontend:latest <dockerhub-user>/notes-frontend:latest
docker push <dockerhub-user>/notes-frontend:latest
