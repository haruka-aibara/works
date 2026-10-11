FROM node:24@sha256:3d27e5c11e5786e309ec3e03f93ae536eb36e6e5eb3714d5eb3300a36157add0

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
