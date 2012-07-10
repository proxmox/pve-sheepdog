#!/bin/sh
### BEGIN INIT INFO
# Provides:          sheepdog
# Required-Start:    $network $remote_fs $syslog
# Required-Stop:     $network $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Sheepdog server
# Description:       Sheepdog server
### END INIT INFO

# Author: Proxmox Support Team <support@proxmox.com>

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="Sheepdog Server"        # Introduce a short description here
NAME=sheepdog                 # Introduce the short server's name here
DAEMON=/usr/sbin/sheep        # Introduce the server's location here
DAEMON_ARGS=""                # Arguments to run the daemon with
##PIDFILE=/var/run/sheep.pid
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x $DAEMON ] || exit 0

# Defaults
SHEEPDOG_PATH="/var/lib/sheepdog"

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

if [ "$START" != "yes" ]; then
        exit 0
fi

. /lib/lsb/init-functions

status()
{
	pid=$(pidof $1 2>/dev/null)
	rtrn=$?
	if [ $rtrn -ne 0 ]; then
		echo "$1 is stopped"
	else
		echo "$1 (pid $pid) is running..."
	fi
	return $rtrn
}

#
# Function that starts the daemon/service
#
do_start()
{
        mkdir -p /var/run

        mkdir -p $SHEEPDOG_PATH

	# Return
	#   0 if daemon has been started
	#   1 if daemon was already running
	#   2 if daemon could not be started

 	status "$DAEMON" >/dev/null && return 1

	start-stop-daemon --start --quiet --exec $DAEMON -- $DAEMON_ARGS $SHEEPDOG_PATH || return 2
}

#
# Function that stops the daemon/service
#
do_stop()
{
	# Return
	#   0 if daemon has been stopped
	#   1 if daemon was already stopped
	#   2 if daemon could not be stopped
	#   other if a failure occurred

        status "$DAEMON" >/dev/null || return 1

	start-stop-daemon --stop --retry=TERM/20/KILL/5 --exec $DAEMON
	RETVAL="$?"
	[ "$RETVAL" = 2 ] && return 2

	# Many daemons don't delete their pidfiles when they exit.
	# rm -f $PIDFILE

	return "$RETVAL"
}

case "$1" in
    start)
	log_daemon_msg "Starting $DESC " "$NAME"
	do_start
	case "$?" in
	    0|1) log_end_msg 0 ;;
	    2) log_end_msg 1 ;;
	esac
	;;
    stop)
	log_daemon_msg "Stopping $DESC" "$NAME"
	do_stop
	case "$?" in
	    0|1) log_end_msg 0 ;;
	    2) log_end_msg 1 ;;
	esac
	;;
    status)
	status "$DAEMON" && exit 0 || exit $?
	;;
    restart|force-reload)
	log_daemon_msg "Restarting $DESC" "$NAME"
	do_stop
	case "$?" in
	    0|1)
		do_start
		case "$?" in
		    0) log_end_msg 0 ;;
		    1) log_end_msg 1 ;; # Old process is still running
		    *) log_end_msg 1 ;; # Failed to start
		esac
		;;
	    *)
	  	# Failed to stop
		log_end_msg 1
		;;
	esac
	;;
    *)
	echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
	exit 3
	;;
esac

:

