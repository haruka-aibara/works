FROM node:26@sha256:6d2c7d5d074bf72f81ddc252b4fbb5d625bc028eeda49cb4b8c2ff8eda1ee617 AS base
CMD [ "bash" ]

# Build
FROM base AS test-and-build
COPY . /workspace
WORKDIR /workspace
ARG REACT_APP_API_SERVER
RUN npm ci && npm run test && npm run build

# Hosting in nginx (non-root). Port 80 needs net.ipv4.ip_unprivileged_port_start=0,
# which Docker sets by default and .aws/task-definition.json sets on ECS.
FROM nginxinc/nginx-unprivileged:latest@sha256:09b0d3eda2aa592d2487f284519419015cab010d7df16cd0fe224b585fc60eb6 AS production
COPY --from=test-and-build /workspace/build /var/www
COPY nginx.conf /etc/nginx/conf.d/default.conf
USER 101
