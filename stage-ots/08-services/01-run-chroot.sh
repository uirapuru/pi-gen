#!/bin/bash -e

sudo systemctl daemon-reload
sudo systemctl enable opentakserver
sudo systemctl start opentakserver

sudo systemctl enable cot_parser
sudo systemctl start cot_parser

sudo systemctl enable eud_handler
sudo systemctl start eud_handler

sudo systemctl enable eud_handler_ssl
sudo systemctl start eud_handler_ssl