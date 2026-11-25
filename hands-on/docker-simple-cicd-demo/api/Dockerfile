FROM gradle:9@sha256:a16370cdf4fab2bdec80810ba7f7d577fc2ce86eb1332b067031fcc19d947ed5 AS base
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
