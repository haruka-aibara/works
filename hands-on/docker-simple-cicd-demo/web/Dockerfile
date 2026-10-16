FROM node:24@sha256:14078204b6bb268c107ceff6d3c43f45a888105e5c2b18b14c32b3409d93a1b0 AS base
CMD [ "bash" ]

# Build
FROM base AS test-and-build
COPY . /workspace
WORKDIR /workspace
ARG REACT_APP_API_SERVER
RUN npm ci && npm run test && npm run build

# Hosting in nginx (non-root). Port 80 needs net.ipv4.ip_unprivileged_port_start=0,
# which Docker sets by default and .aws/task-definition.json sets on ECS.
FROM nginxinc/nginx-unprivileged:latest@sha256:94193d5c4c5df716f412bb08eb97956d98fe6b59886f0bc57d6d3a3402a88a02 AS production
COPY --from=test-and-build /workspace/build /var/www
COPY nginx.conf /etc/nginx/conf.d/default.conf
USER 101
