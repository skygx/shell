
#!/bin/bash
# Check if nginx process is running
if pgrep "nginx" > /dev/null
then
    echo "Nginx is running"
else
    echo "Nginx is not running"
fi

# Monitor nginx process every 5 seconds
while true
do
    if pgrep "nginx" > /dev/null
    then
        sleep 5
    else
        echo "Nginx is not running, starting nginx"
        nginx
    fi
done

# The code above checks if the nginx process is running and starts it if it is not. It also monitors the process every 5 seconds.

while :
do
    nginxpid=$(ps -C nginx --no-header | wc -l)
    if [ nginxpid -eq 0 ]; then
        ulimit -SHn 65535
        /usr/local/nginx/sbin/nginx
        sleep 5
    if [ nginxpid -eq 0 ]; then
        /etc/init.d/keepalived stop
    fi
    fi
    sleep 5
done