# Descripcion
PoC para el test de una aplicación simple de SpringBoot en un entorno k8s.

Las pruebas se realizan en un cluster local con K3D (basado en k3s) con su propio registry.

*Importante!!!*

El enfoque de este PoC es facilitar el uso de kubernetes en un entorno local. Hay varias configuraciones que no son optimas para un entorno de Producción.



# Creacion del cluster K3D
## Instalación
Acudir a la guia oficial de instalación [aqui](https://k3d.io/v5.6.0/#installation)
Revisar tambien estos otros articulos:
- https://www.digestibledevops.com/devops/2021/03/24/k3d-on-windows.html
- https://www.youtube.com/watch?v=CfrUVMqH-R0


En Linux:
```
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

```
Tambien es necesario disponer de kubectl o alternativa para la aplicación de los manifiestos.

## Montaje del cluster
Una vez instalado el binario *k3d*, ejecutar:
```
k3d cluster create mycluster --registry-create mycluster-registry:5000 --api-port 6550 -p "80:80@loadbalancer"

```
Las opciones son:
- mycluster: nombre del cluster de K3D
- mycluster-registry: es la dirección y puerto (5000) del registry local. Automaticamente da de alta este registro en "registries.yaml", por lo que confia en él  sin necesidad de hacer nada mas.
- puertos con opción "-p": se usa para el mapeo externo (mediante Docker). La sintaxis es "puerto_externo(host):puerto_interno(k3s)@loadbalancer(si se ha publicado por el balanceador interno Traefik)".


# Creación y subida
## Construcción contenedor
Si usamos el Dockerfile proporcionado, podemos construir el contenedor java con la aplicación Spring boot ya compilada.

El Dockerfile es un multistage para compilar primero y luego copiar el jar al contenedor final. 

Tambien se proporcionan una serie de variables que afectan a Spring Cloud Config, en caso que se use.

Finalmente, disponemos de un script a modo de entrypoint ( *docker-entrypoint.sh* )que revisa variables de entorno y ejecuta la aplicación.

## Subida al registry
A la hora de construir el contenedor, podemos usar este comando para etiquetar el contenedor de forma que luego lo podamos subir al registry:
```
docker build -t localhost:5000/spb:1.0 .
```
Una vez construido, subimos el contenedor:
```
docker push localhost:5000/spb:1.0

```
Dado que desde el punto de vista de Docker el registry está en "localhost", no es necesario "https" ni modificar opciones de confianza en el demonio de Docker.

# Despliegue en K8s
A modo de referencia se entrega el fichero "test-spb-k8s.yaml" que cubre las opciones de configuración mediante variables de entorno con Secrets y mediante ConfigMap

##  Contenido del manifiesto
Dentro del manifiesto "test-spb-k8s.yaml" tenemos un par de declaraciones que no necesitan mucho más detalle:
- Ingress: usa el ingress por defecto (traefik) para publicar el servicio. Podemos usar urls del tipo "*.127-0-0-1.sslip.io" que apuntan al host local.
- Service: en el ejemplo con ClusterIP. Dado que es un entorno local y no vamos a disponer de muchos servicios, se puede usar este modo sin problema.

Donde está el core de la configuración es el *Deployment* . Las opciones que comentamos a continuación se pueden mezclar según nuestras necesidades ( no es necesario usar el "deployment" literalmente como está). 

## Recursos para configuración de la aplicación
En este PoC jugamos con las opciones de configuración que tiene Spring Boot.
A modo de referencia, en la siguiente [url](https://docs.spring.io/spring-boot/docs/1.0.1.RELEASE/reference/html/boot-features-external-config.html) podemos ver los mecanismos de configuración externa y **prioridades** de cada uno de ellos.

En este proyecto de ejemplo usamos estos mecanismos:
- Variables de entorno: que se pasan al contenedor mediante la clausula "env" del "deployment"
- Fichero de configuración applicacion.properties o application.yml externo: el cual lo podemos presentar al contenedor mediante un ConfigMap. Si el fichero se encuentra dentro de un subdirectorio "config" a la misma altura que el jar de la aplicación, automaticamente carga dicho fichero

Cuando usamos las variables de entorno, tenemos varias alternativas:
- inicializar el valor de la variable explicitamente: en el mismo yaml del *deployment* se puede indicar la pareja "name/value" con el nombre y valor respectivamente de la variable. Este caso puede servir para valores que cambian poco (nombre de la aplicación, por ejemplo) y que no contengan valores sensibles
- obtener el valor de un secret: (tal como se hace en el ejemplo). Usar este caso para valores como claves de acceso, urls de entorno, etc. Altenativamente, se puede usar un mecanismo parecido para obtener los valores de un configmap
- pasar un secret/configmap como fichero con variables de entorno: con la clausula "envFrom"


En el caso del *configmap*, se ha creado con el contenido representando un fichero (applicacion.properties). Con este configmap hacemos lo siguiente:
- se presenta como volumen al *deployment*: sección *volumes* del *deployment* . Con esto conseguimos que el contenido del configmap (esos ficheros "virtuales" que hemos generado) se presenten como un directorio con contenido al contenedor.
- se monta el volumen en una ruta concreta: sección *volumeMounts* . El "truco" está en que el punto de montaje es "/config" ya que nuestro "app.jar" está en el directorio "/". En caso que el jar esté en otro directorio (por ejemplo, "/work" o "/app") ajustar el directorio del punto de montaje (/work/config o /app/config). Dentro del directorio "config" del contenedor aparecerá un fichero "applicacion.properties" con el contenidor del ConfigMap.


Para rizar el rizo, dentro del configmap podemos hacer referencia a variables de entorno, que se han podido proporcionar por los mecanismos comentados anteriormente o bien porque son internas del contenedor (en el *Dockerfile* se declaran algunas variables por defecto)


Dentro del fichero de manifiesto tenemos ejemplos de Secret y ConfigMap.

# Código de la aplicación
La aplicación es muy simple, tan solo contiene:
- "main" de SpringBoot
- controlador (helloController) mapeado al contexto "/" y que responde con un mensaje en función de los valores de configuración que se hayan proporcionado.
- application.properties "interno": según la documentación, tiene baja prioridad frente a otras opciones de configuración externas, es decir, en caso que coincidan los identificadores de la "clave", se da prioridad al valor de la configuración externa frente a la interna.

Una vez hayamos finaliza la aplicación de los manifiestos, podemos acceder a la aplicación en:

http://spb.127-0-0-1.sslip.io/


