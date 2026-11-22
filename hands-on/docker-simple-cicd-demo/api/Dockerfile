FROM gradle:9@sha256:39d599d8df1777d73b00b5bf928254ecd121802d518577fe08d41a3cf86aa45f AS base
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
