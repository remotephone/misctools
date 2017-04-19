#!/bin/bash

# get it ready
apt-get update && apt-get upgrade

# make your directories and get into them
apt-get install openvpn easy-rsa awscli -y
mkdir -p ~/aws-openvpn/key-store
cp -R /usr/share/easy-rsa/ ~/aws-openvpn
cd ~/aws-openvpn/easy-rsa

# clean up first just in case

/root/aws-openvpn/easy-rsa/clean-all
source /root/aws-openvpn/easy-rsa/vars
/root/aws-openvpn/easy-rsa/clean-all

# build the certs

/root/aws-openvpn/easy-rsa/build-ca --batch
/root/aws-openvpn/easy-rsa/build-dh --batch
/root/aws-openvpn/easy-rsa/build-key-server --batch vpnserver nopass
/usr/sbin/openvpn --genkey --secret /root/vpn.tlsauth
/root/aws-openvpn/easy-rsa/build-key --batch client nopass
/usr/bin/openssl pkcs12 -export -in /root/aws-openvpn/easy-rsa/keys/client.crt -inkey /root/aws-openvpn/easy-rsa/keys/client.key -certfile /root/aws-openvpn/easy-rsa/keys/ca.crt -out /root/client.p12 -password pass:

# Send the client config to the s3 bucket
aws s3 cp /root/apr2017.p12 s3://<AWSS3BUCKET>/
aws s3 cp /root/vpn.tlsauth s3://<AWSS3BUCKET>/

# move the vpn config to your vpn server and run it.
aws s3 cp s3://<AWSS3BUCKET>/server.conf /root/server.conf
/usr/sbin/openvpn —config /root/server.conf


# On the client machine, you'll need to run this:
## aws s3 cp s3://<AWSS3BUCKET>/client.conf ./client.conf
## aws s3 cp s3://<AWSS3BUCKET>/client.p12 /root/aws-openvpn/easy-rsa/client.p12
## aws s3 cp s3://<AWSS3BUCKET>/vpn.tlsauth /root/aws-openvpn/easy-rsa/vpn.tlsauth
