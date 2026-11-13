#!/bin/sh
### Custom user script called by zapret.sh
### $1 - action: start/stop/reload/restart

post_start()
{
    return 0
}

post_stop()
{
    return 0
}

post_reload()
{
    return 0
}

post_restart()
{
    return 0
}

case "$1" in
    start)
        post_start
    ;;
    stop)
        post_stop
    ;;
    reload)
        post_reload
    ;;
    restart)
        post_restart
    ;;
esac
