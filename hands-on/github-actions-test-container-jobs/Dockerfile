FROM node:16@sha256:f77a1aef2da8d83e45ec990f45df50f1a286c5fe8bbfb8c6e4246c6389705c0b

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
