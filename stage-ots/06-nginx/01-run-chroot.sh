#!/bin/bash -e

if ! grep -q "stream {" /etc/nginx/nginx.conf; then
cat >> /etc/nginx/nginx.conf <<NGINX

stream {
        include /etc/nginx/streams-enabled/*;
}

NGINX
fi

rm -f /etc/nginx/sites-enabled/*

sed -i "s~SERVER_CERT_FILE~/home/tak/ots/ca/certs/opentakserver/opentakserver.pem~g" /etc/nginx/sites-available/ots_https
sed -i "s~SERVER_CERT_FILE~/home/tak/ots/ca/certs/opentakserver/opentakserver.pem~g" /etc/nginx/sites-available/ots_certificate_enrollment
sed -i "s~SERVER_CERT_FILE~/home/tak/ots/ca/certs/opentakserver/opentakserver.pem~g" /etc/nginx/streams-available/rabbitmq
sed -i "s~SERVER_CERT_FILE~/home/tak/ots/ca/certs/opentakserver/opentakserver.pem~g" /etc/nginx/streams-available/mediamtx

sed -i "s~SERVER_KEY_FILE~/home/tak/ots/ca/certs/opentakserver/opentakserver.nopass.key~g" /etc/nginx/sites-available/ots_https
sed -i "s~SERVER_KEY_FILE~/home/tak/ots/ca/certs/opentakserver/opentakserver.nopass.key~g" /etc/nginx/sites-available/ots_certificate_enrollment
sed -i "s~SERVER_KEY_FILE~/home/tak/ots/ca/certs/opentakserver/opentakserver.nopass.key~g" /etc/nginx/streams-available/rabbitmq
sed -i "s~SERVER_KEY_FILE~/home/tak/ots/ca/certs/opentakserver/opentakserver.nopass.key~g" /etc/nginx/streams-available/mediamtx

sed -i "s~CA_CERT_FILE~/home/tak/ots/ca/ca.pem~g" /etc/nginx/sites-available/ots_https
sed -i "s~CA_CERT_FILE~/home/tak/ots/ca/ca.pem~g" /etc/nginx/sites-available/ots_certificate_enrollment

ln -sf /etc/nginx/sites-available/ots_https /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/ots_certificate_enrollment /etc/nginx/sites-enabled/

ln -sf /etc/nginx/streams-available/rabbitmq /etc/nginx/streams-enabled/
ln -sf /etc/nginx/streams-available/mediamtx /etc/nginx/streams-enabled/

systemctl enable nginx
systemctl restart nginx