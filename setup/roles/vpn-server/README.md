docker run -v /services/vpn-server/data:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_genconfig -u udp://78.70.3.180
docker run -v /services/vpn-server/data:/etc/openvpn --log-driver=none --rm -it kylemanna/openvpn ovpn_initpki
docker run -v /services/vpn-server/data:/etc/openvpn --name oepnvpn_server --restart unless-stopped -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn
docker run -v /services/vpn-server/data:/etc/openvpn --log-driver=none --rm -it kylemanna/openvpn easyrsa build-client-full CLIENTNAME nopass
docker run -v /services/vpn-server/data:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn

