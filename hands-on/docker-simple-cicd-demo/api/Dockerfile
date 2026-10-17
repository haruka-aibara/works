FROM gradle:9@sha256:4a80c8083135754f689c3e31bb858a22282c66f5625cafb09ed217814b363ee5 AS base
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
