#!/bin/bash

# --- Configuration ---
# Set the duration of your work and rest periods in minutes.
WORK_MINUTES=25
REST_MINUTES=5

# --- New: Long Break Configuration ---
LONG_BREAK_MINUTES=15
SESSIONS_PER_CYCLE=4 # Trigger a long break after this many work sessions.

# The file to store the process ID, used for stopping the script.
PID_FILE="/tmp/pomodoro.pid"
# --- End Configuration ---


# A reusable function to send notifications using osascript.
# Usage: notify "Title" "Subtitle" "Message"
notify() {
    osascript -e "display notification \"$3\" with title \"$1\" subtitle \"$2\" sound name \"Crystal\""
}

# The main loop that cycles between work and rest.
main_loop() {
    # Trap the EXIT signal to ensure the PID file is cleaned up when the script stops.
    trap "rm -f '$PID_FILE'" EXIT
    
    local session_count=0
    
    echo "Pomodoro started. PID: $$"
    notify "Pomodoro Started" "A new cycle begins!" "Work for $WORK_MINUTES minutes."

    while true; do
        # --- WORK CYCLE ---
        sleep $((WORK_MINUTES * 60))
        ((session_count++))

        # --- BREAK CYCLE ---
        # Check if it's time for a long break.
        if (( session_count % SESSIONS_PER_CYCLE == 0 )); then
            # Long break
            notify "Long Break Time!" "You've completed $SESSIONS_PER_CYCLE sessions. Great job! 🥳" "Take a $LONG_BREAK_MINUTES minute break."
            sleep $((LONG_BREAK_MINUTES * 60))

            # Notification for next work session after long break
            notify "Long Break Over!" "Back to it! A new cycle begins. 💪" "Work for $WORK_MINUTES minutes."
        else
            # Short break
            notify "Work Timer is up!" "Take a Break 😊 (Session ${session_count}/${SESSIONS_PER_CYCLE})" "Rest for $REST_MINUTES minutes."
            sleep $((REST_MINUTES * 60))

            # Notification for next work session after short break
            notify "Break is over!" "Get back to work 😬" "Work for $WORK_MINUTES minutes."
        fi
    done
}

# Function to start the pomodoro timer in the background.
start_pomo() {
    if [ -f "$PID_FILE" ]; then
        echo "Pomodoro is already running. Use 'stop' command to stop it."
        exit 1
    fi

    # Start the main_loop in the background
    main_loop &
    
    # Save the PID of the background process to the PID file
    echo $! > "$PID_FILE"
    echo "Pomodoro timer started in the background."
}

# Function to stop the pomodoro timer.
stop_pomo() {
    if [ ! -f "$PID_FILE" ]; then
        echo "Pomodoro is not running."
        exit 1
    fi

    # Read the PID from the file and kill the process
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        rm "$PID_FILE"
        echo "Pomodoro timer stopped."
        notify "Pomodoro Stopped" "See you next time!" "Your session has ended."
    else
        echo "Pomodoro process not found. Cleaning up stale PID file."
        rm "$PID_FILE"
    fi
}

# Main command handling
case "$1" in
    start)
        start_pomo
        ;;
    stop)
        stop_pomo
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac

exit 0
