FROM node:24@sha256:14078204b6bb268c107ceff6d3c43f45a888105e5c2b18b14c32b3409d93a1b0

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
