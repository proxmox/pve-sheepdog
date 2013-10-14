#!/bin/sh
### BEGIN INIT INFO
# Provides:          sheepdog
# Required-Start:    $network $remote_fs $syslog cman
# Required-Stop:     $network $remote_fs $syslog cman
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
SCRIPTNAME=/etc/init.d/$NAME
PIDFILE="/var/run/sheep.pid"

# Exit if the package is not installed
[ -x $DAEMON ] || exit 0

ROOTDIR="/var/lib/sheepdog/"
JOURNALSIZE="256"
DAEMON_ARGS=""

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

if [ "$START" != "yes" ]; then
        exit 0
fi

. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
        mkdir -p /var/run

 	# Return
	#   0 if daemon has been started
	#   1 if daemon was already running
	#   2 if daemon could not be started
	ulimit -n 1024000 #avoid check_host_env(395) WARN: Allowed open files 1024 too small, suggested 1024000 warning message
	ulimit -c unlimited #avoid check_host_env(404) Allowed core file size 0, suggested unlimited warning message
	DAEMON_ARGS="${DAEMON_ARGS} --pidfile ${PIDFILE}"
	DAEMON_ARGS="${DAEMON_ARGS} $ROOTDIR"

	# /path/to/meta-store,/path/to/disk1{,/path/to/disk2,...}
	for d in $ROOTDIR/disc*
	do
	    if [ -d "$d" ]; then
		DAEMON_ARGS="${DAEMON_ARGS},$d"
	    fi
	done

	if [ -d "$ROOTDIR/journal" ]; then
		DAEMON_ARGS="${DAEMON_ARGS} -j dir=$ROOTDIR/journal,size=$JOURNALSIZE"

	fi
        status_of_proc -p ${PIDFILE} $DAEMON "$NAME" >/dev/null && continue
        start-stop-daemon --start --quiet --pidfile ${PIDFILE} --exec $DAEMON -- $DAEMON_ARGS || return 2

	return 0
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

	start-stop-daemon --stop --oknodo --retry=TERM/20/KILL/5 --quiet --pidfile ${PIDFILE} --exec $DAEMON || return 2
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
	    status_of_proc -p ${PIDFILE} $DAEMON "$NAME ${dir}" || exit 1
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

