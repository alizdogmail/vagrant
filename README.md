Es un vagrantfile para virtualbox para montar un pequeño lab de Elasticsearch Stack totalmente automatizado.

En el momento de escribir estos scripts se esta usuando la version 8.19.12 de elk stack

La contraseña del elastisearch la encontrareis en el archivo /etc/logstash/conf.d/beats.conf

Los puertos expuestos 9201 para elastic, 5602 para kibana y 8080 para el wordpress
* http://127.0.0.1:5602/ --> Kibana
* http://localhost:8080/ --> wordpress
* https://127.0.0.1:9201/ --> elasticsearch solo para ver que responde
