FROM maven:3.9-eclipse-temurin-17-alpine as build
ADD . /app
WORKDIR /app
RUN mvn -B clean install -DskipTests=true -f pom.xml


FROM eclipse-temurin:17-jre-alpine as runtime

#Variables de entorno
ENV CONFIG_ENABLED false
ENV CONFIG_SERVER http://localhost:8888
ENV CONFIG_SERVER_USER user
ENV CONFIG_SERVER_PASSWORD password
ENV CONFIG_SERVER_LABEL main
ENV CONFIG_FAIL_FAST false

ENV JAVA_OPTS="-Djdk.tls.client.protocols=TLSv1.2"

#Ejecutable con la aplicacion
COPY --from=build /app/target/*.jar /app.jar
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh


#Puerto que expone
EXPOSE 8080

#Comando que se ejecuta una vez ejecutemos el contendor
ENTRYPOINT ["/docker-entrypoint.sh"]
