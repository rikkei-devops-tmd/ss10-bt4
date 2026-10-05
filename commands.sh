#!/bin/bash
set -e

docker network create --driver bridge app-net

docker volume create db-data

docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  postgres:15-alpine

sleep 5

docker run -d \
  --name app-container \
  --network app-net \
  -p 8080:3000 \
  -e DB_HOST=db-server \
  -e DB_PORT=5432 \
  -e DB_NAME=mydb \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  hw-backend:v1

sleep 3

docker network ls | grep app-net
docker volume ls | grep db-data
docker network inspect app-net

docker exec -i db-server psql -U postgres -d mydb -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(50)); INSERT INTO users (name) VALUES ('Alice'), ('Bob');"
docker exec -i db-server psql -U postgres -d mydb -c "SELECT * FROM users;"

docker rm -f db-server

docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  postgres:15-alpine

sleep 5

docker exec -i db-server psql -U postgres -d mydb -c "SELECT * FROM users;"
