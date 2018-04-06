#!/bin/bash
openssl genrsa -out /etc/csync2_ssl_key.pem 1024
openssl req -new -key /etc/csync2_ssl_key.pem -out /etc/csync2_ssl_cert.csr
openssl x509 -req -days 900 -in /etc/csync2_ssl_cert.csr -signkey /etc/csync2_ssl_key.pem -out /etc/csync2_ssl_cert.pem
/usr/sbin/csync2 -k /etc/csync2.cluster.key
