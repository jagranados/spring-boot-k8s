#!/bin/sh
DEFAULT_JAVA_OPTS="-Doracle.jdbc.fanEnabled=false -Djava.security.egd=file:/dev/./urandom -Djdk.tls.client.protocols=TLSv1.2"

# Podemos usar JAVA_OPTS para pasar valores de configuración adicionales: memoria, gc, agentes,  ...

CUSTOM_JAVA_OPTS="${DEFAULT_JAVA_OPTS} ${JAVA_OPTS} "
SPRING_OPTS=""

if [ "${CONFIG_ENABLED}" == "true" ] &&  [ "${CONFIG_SERVER}" != "" ] ; then
    SPRING_OPTS="${SPRING_OPTS} --spring.cloud.config.enabled=${CONFIG_ENABLED}"
	SPRING_OPTS="${SPRING_OPTS} --CONFIG_SERVER=${CONFIG_SERVER} "
	SPRING_OPTS="${SPRING_OPTS} --CONFIG_SERVER_USER=${CONFIG_SERVER_USER} "
	SPRING_OPTS="${SPRING_OPTS} --CONFIG_SERVER_PASSWORD=${CONFIG_SERVER_PASSWORD} "
	SPRING_OPTS="${SPRING_OPTS} --CONFIG_SERVER_LABEL=${CONFIG_SERVER_LABEL}"
	SPRING_OPTS="${SPRING_OPTS} --spring.cloud.config.failFast=${CONFIG_FAIL_FAST}"

fi



echo "Opciones: ${CUSTOM_JAVA_OPTS} | ${SPRING_OPTS}" 
exec java ${CUSTOM_JAVA_OPTS} -jar /app.jar ${SPRING_OPTS}
