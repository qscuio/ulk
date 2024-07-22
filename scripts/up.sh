#!/bin/sh

# Add bridge 0
sudo brctl addbr br1
sudo brctl addbr br2
sudo brctl stp br1 off
sudo brctl stp br2 off
sudo brctl setfd br1 1
sudo brctl setfd br2 2
sudo brctl sethello br1 1
sudo brctl sethello br2 1

sudo tunctl -t tap1 -u root
sudo tunctl -t tap2 -u root
sudo brctl addif br1 tap1
sudo brctl addif br2 tap2
sudo ifconfig br1 10.10.10.254 netmask 255.255.255.0 up
sudo ifconfig br2 10.20.20.254 netmask 255.255.255.0 up
sudo ifconfig br1 inet6 add 2001:db8:10::254/64
sudo ifconfig br2 inet6 add 2001:db8:20::254/64
sudo ifconfig tap1 up
sudo ifconfig tap2 up
sudo ifconfig br1 up
sudo ifconfig br2 up
