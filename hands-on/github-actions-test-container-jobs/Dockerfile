FROM node:26@sha256:f8e5d4bb28fa55c74f1345166a082a10b7c68f22304350c1ce0d18358ae94996

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
