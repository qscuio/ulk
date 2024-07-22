#!/bin/sh

sudo ifconfig br1 down
sudo ifconfig br2 down
sudo ifconfig tap1 down
sudo ifconfig tap2 down
sudo tunctl -d tap1
sudo tunctl -d tap2
sudo brctl delbr br1
sudo brctl delbr br2
