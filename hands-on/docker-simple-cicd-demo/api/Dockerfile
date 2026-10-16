FROM gradle:9@sha256:e4f9e3d037cc0c7d8fc42cd97edb976dfd19a5b7314212b88b6de3807d13cd47 AS base
CMD ["bash"]

# test-and-build
FROM base AS test-and-build
COPY . /workspace
WORKDIR /workspace
RUN ./gradlew build

# production
FROM openjdk:17 AS production
COPY --from=test-and-build /workspace/build/libs/api-0.0.1-SNAPSHOT.jar ./api.jar
USER nobody
CMD [ "java", "-jar", "api.jar" ]
