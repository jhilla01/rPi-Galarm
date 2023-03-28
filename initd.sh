#!/bin/sh

### BEGIN INIT INFO
# Provides:          Alarm
# Required-Start:    $network
# Required-Stop:     $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

# Defaults
DAEMON_NAME="AlarmClock"
DAEMON_EXECUTABLE="/home/pi/Alarm/rise"
DAEMON_OPTIONS=""
DAEMON_HOMEDIR="/home/pi/Alarm"
DAEMON_PIDFILE="/var/run/Alarm"
DAEMON_LOGFILE="/var/log/Alarm"
INIT_SLEEPTIME="2"

# Defaults can be overridden in this file
DAEMON_DEFAULTS_FILE="/etc/default/rise"

PATH=/sbin:/bin:/usr/sbin:/usr/bin

# Load alternate configuration if exists
test -f $DAEMON_DEFAULTS_FILE && . $DAEMON_DEFAULTS_FILE

. /lib/lsb/init-functions

# Function to check if daemon is already running
is_running () {
  if [ -f "$DAEMON_PIDFILE" ]; then
    read PID < "$DAEMON_PIDFILE"
    if [ -n "$PID" ] && ps -p "$PID" > /dev/null; then
      return 0
    fi
  fi
  return 1
}

# Function to check if user is root
root_only () {
  if [ "$(id -u)" != "0" ]; then
    echo "Only root should run this operation"
    exit 1
  fi
}

# Function to start the daemon
start_daemon () {
  if is_running; then
    PID="$(cat $DAEMON_PIDFILE)"
    echo "Daemon is already running as PID $PID"
    return 1
  fi

  cd "$DAEMON_HOMEDIR"
  nohup "$DAEMON_EXECUTABLE" "$DAEMON_OPTIONS" >> "$DAEMON_LOGFILE" 2>&1 &
  echo $! > "$DAEMON_PIDFILE"
  read PID < "$DAEMON_PIDFILE"

  sleep "$INIT_SLEEPTIME"
  if ! is_running; then
    echo "Daemon died immediately after starting. Please check your logs and configurations."
    return 1
  fi

  echo "Daemon is running as PID $PID"
  return 0
}

# Function to stop the daemon
stop_daemon () {
  if is_running; then
    read PID < "$DAEMON_PIDFILE"
    kill "$PID"
  fi
  sleep "$INIT_SLEEPTIME"
  if is_running; then
    while is_running; do
      echo "Waiting for daemon to die (PID $PID)"
      sleep "$INIT_SLEEPTIME"
    done
  fi
  rm -f "$DAEMON_PIDFILE"
  return 0
}

# Main script
case "$1" in
  start)
    root_only
    log_daemon_msg "Starting $DAEMON_NAME"
    start_daemon
    log_end_msg $?
    ;;
  stop)
    root_only
    log_daemon_msg "Stopping $DAEMON_NAME"
    stop_daemon
    log_end_msg $?
    ;;
  restart)
    root_only
    $0 stop && $0 start
    ;;
  status)
    if is_running; then
      echo "Daemon is running"
      exit 0
    else
      echo "Daemon is not running"
      exit 1
start_daemon () {
  if is_running; then
    PID="$(cat $DAEMON_PIDFILE)"
    echo "Daemon is already running as PID $PID"
    return 1
  fi

  cd $DAEMON_HOMEDIR

  nohup $DAEMON_EXECUTABLE $DAEMON_OPTIONS >>$DAEMON_LOGFILE 2>&1 &
  echo $! > $DAEMON_PIDFILE
  read PID < "$DAEMON_PIDFILE"

  sleep $INIT_SLEEPTIME
  if ! is_running; then
    echo "Daemon died immediately after starting. Please check your logs and configurations."
    return 1
  fi

  echo "Daemon is running as PID $PID"
  return 0
}

stop_daemon () {
  if is_running; then
    read PID < "$DAEMON_PIDFILE"
    kill $PID
  fi
  sleep $INIT_SLEEPTIME
  if is_running; then
    while is_running; do
      echo "waiting for daemon to die (PID $PID)"
      sleep $INIT_SLEEPTIME
    done
  fi
  rm -f "$DAEMON_PIDFILE"
  return 0
}

case "$1" in
  start)
    root_only
    log_daemon_msg "Starting $DAEMON_NAME"
    start_daemon
    log_end_msg $?
    ;;
  stop)
    root_only
    log_daemon_msg "Stopping $DAEMON_NAME"
    stop_daemon
    log_end_msg $?
    ;;
  restart)
    root_only
    $0 stop && $0 start
    ;;
  status)
    status_of_proc \
      -p "$DAEMON_PIDFILE" \
      "$DAEMON_EXECUTABLE" \
      "$DAEMON_NAME" \
      && exit 0 \
      || exit $?
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
  ;;
esac