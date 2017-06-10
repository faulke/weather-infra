#!/bin/bash
sudo npm install forever -g
cd /home/ec2-user/weatherapp/
sudo forever start -c "node -r babel-register" tools/distServer.js > /dev/null 2> /dev/null < /dev/null &
