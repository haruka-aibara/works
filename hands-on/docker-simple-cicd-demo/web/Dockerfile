FROM node:24@sha256:3d27e5c11e5786e309ec3e03f93ae536eb36e6e5eb3714d5eb3300a36157add0 AS base
CMD [ "bash" ]

# Build
FROM base AS test-and-build
COPY . /workspace
WORKDIR /workspace
ARG REACT_APP_API_SERVER
RUN npm ci && npm run test && npm run build

# Hosting in nginx (non-root). Port 80 needs net.ipv4.ip_unprivileged_port_start=0,
# which Docker sets by default and .aws/task-definition.json sets on ECS.
FROM nginxinc/nginx-unprivileged:latest@sha256:31e97ebaac04c19c8e7da6012c5776e86a4414695565200719d6113cb68d0b78 AS production
COPY --from=test-and-build /workspace/build /var/www
COPY nginx.conf /etc/nginx/conf.d/default.conf
USER 101
