#!/bin/sh

if [ -z $1 ]
then
    echo "Is needed to enter an argument with the destiny folder!"
else
    echo "Moving docker files to $1"
    cp docker-compose.yml Dockerfile .env $1
    if [ $? -eq 0 ]; then
        echo "Enjoy your zephyr docker!"
    else
        echo "Some problem occurred with destiny passed!"
    fi
fi




