FROM node:24@sha256:7b559cf7f77d837192392499a850abb1a3d1f49fbc2bd0692d54b212c9e38f6d

# this is just demo code, so we don't need to worry about security
ENV MONGODB_CONNECTION_PROTOCOL mongodb+srv
ENV MONGODB_DB_NAME gha-demo1
ENV MONGODB_CLUSTER_ADDRESS cluster0.ntrwp.mongodb.net
ENV MONGODB_USERNAME maximilian
# MONGODB_PASSWORD is passed at run time (docker run -e MONGODB_PASSWORD=...).

WORKDIR /app

COPY package*.json .

RUN npm install

COPY . .

USER node

CMD ["npm", "start"]
