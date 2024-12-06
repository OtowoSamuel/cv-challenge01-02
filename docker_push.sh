#!/bin/bash

# Build frontend and backend images
echo "Building frontend and backend images..."
sudo docker compose build frontend
sudo docker compose build backend

# Pull dependencies to ensure latest versions are available locally
echo "Pulling required dependencies..."
sudo docker compose pull db adminer proxy nginx prometheus grafana loki promtail cadvisor

# Tag images with the appropriate Docker Hub repository
echo "Tagging images..."
sudo docker tag cv-challenge01-frontend:latest otowosamuel/frontend:latest
sudo docker tag cv-challenge01-backend:latest otowosamuel/backend:latest
sudo docker tag postgres:latest otowosamuel/postgres:latest
sudo docker tag adminer:latest otowosamuel/adminer:latest
sudo docker tag jc21/nginx-proxy-manager:latest otowosamuel/nginx-proxy-manager:latest
sudo docker tag nginx:latest otowosamuel/nginx:latest
sudo docker tag prom/prometheus:latest otowosamuel/prometheus:latest
sudo docker tag grafana/grafana:latest otowosamuel/grafana:latest
sudo docker tag grafana/loki:2.8.2 otowosamuel/loki:2.8.2
sudo docker tag grafana/promtail:2.8.2 otowosamuel/promtail:2.8.2
sudo docker tag gcr.io/cadvisor/cadvisor:latest otowosamuel/cadvisor:latest

# Push images to Docker Hub
echo "Pushing images to Docker Hub..."
sudo docker push otowosamuel/frontend:latest
sudo docker push otowosamuel/backend:latest
sudo docker push otowosamuel/postgres:latest
sudo docker push otowosamuel/adminer:latest
sudo docker push otowosamuel/nginx-proxy-manager:latest
sudo docker push otowosamuel/nginx:latest
sudo docker push otowosamuel/prometheus:latest
sudo docker push otowosamuel/grafana:latest
sudo docker push otowosamuel/loki:2.8.2
sudo docker push otowosamuel/promtail:2.8.2
sudo docker push otowosamuel/cadvisor:latest

# Print success message
echo "Okay, All images have been tagged and pushed successfully!"
