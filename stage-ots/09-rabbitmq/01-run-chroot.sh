#!/bin/bash -e

sudo rabbitmq-plugins enable rabbitmq_mqtt rabbitmq_auth_backend_http ; \
sudo systemctl restart rabbitmq-server ; \
echo "${GREEN}Finished configuring RabbitMQ${NC}" ; \
rm -fr $INSTALLER_DIR ; \
deactivate ; \