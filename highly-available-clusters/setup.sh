#!/bin/sh

MASTER_IP=$(dig controlplane +short)


if [ -n "$MASTER_IP" ];
 then
    echo "";
 else
    echo "Could not find MASTER_IP from hostname 'controlplane' trying using hostname command now";
    MASTER_IP=$(hostname -I | cut -d " " -f 1)
fi

MASTER_2_IP=$(dig node01 +short)

cd /tmp/
wget https://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key

cat << EOF > /etc/apt/sources.list.d/nginx.list
deb http://nginx.org/packages/ubuntu/ xenial nginx
deb-src http://nginx.org/packages/ubuntu/ xenial nginx
EOF

sudo apt-get update
sudo apt-get install nginx


echo "Setting up LB between $MASTER_IP & $MASTER_2_IP"
echo ""
cat << EOF > /etc/nginx/passthrough.conf
## tcp LB and SSL passthrough for backend ##
stream {
    upstream cybercitibizapache {
        server $MASTER_IP:6443 max_fails=3 fail_timeout=10s;
        server $MASTER_2_IP:6443 max_fails=3 fail_timeout=10s;
    }
log_format basic '$remote_addr [$time_local] '
                 '$protocol $status $bytes_sent $bytes_received '
                 '$session_time "$upstream_addr" '
                 '"$upstream_bytes_sent" "$upstream_bytes_received" "$upstream_connect_time"';
    access_log /var/log/nginx/www.cyberciti.biz_access.log basic;
    error_log /var/log/nginx/wwww.cyberciti.biz_error.log;
    server {
        listen 9443;
        proxy_pass cybercitibizapache;
        proxy_next_upstream on;
    }
}
EOF

echo "NGINX passthrought file for tcp LB  and SSL passthrough for backend"
echo ""
bat /etc/nginx/passthrough.conf || cat /etc/nginx/passthrough.conf

if [ $(cat /etc/nginx/nginx.conf | grep passthrough | wc -l) -eq 1 ]; 
 then
   echo "NGINX Config already has passthrough config added"; 
 else 
  echo "Adding passthrought config to nginx config file ";
  echo  ""
  echo "include /etc/nginx/passthrough.conf;" >> /etc/nginx/nginx.conf
fi


echo "NGINX config file now looks like this"

bat /etc/nginx/nginx.conf || cat /etc/nginx/nginx.conf

#nginx -t

echo "Testing NGINX Config"
echo ""

if (nginx -t) ;
  then
    echo "NGINX Service started successfuly"
  else
    echo "NGINX Service did not start successfuly - need to invastigage";
    exit 1;
fi

echo "Starting NGINX Service"
echo ""

systemctl start nginx

echo "Checking NGINX Service status"
echo ""

if (systemctl status nginx) ;
  then
    echo "NGINX Service started successfuly"
  else
    echo "NGINX Service did not start successfuly - need to invastigage";
    exit 1;
fi
