docker build -t notes-backend:latest backend/

docker tag notes-backend:latest <your-dockerhub-user>/notes-backend:latest
docker push <your-dockerhub-user>/notes-backend:latest

