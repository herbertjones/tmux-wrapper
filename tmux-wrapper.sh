#!/bin/sh

# usage:
### Start new tmux session:
## Note: All args are optional, Use a "" to skip argument.
# new_session "NEW_SESSION_NAME" "NEW_WINDOW_NAME" /STARTING/PATH "COMMANDS"
#
### Add a new tab and switch to it
## Note: All args are optional, Use a "" to skip argument.
# new_window WINDOW_NAME /STARTING/PATH "COMMAND TO RUN"
#
### Split the window
# vsplit PANE_NAME /STARTING/PATH PERCENT_TO_SPLIT "COMMANDS TO RUN"
#
### Select the top pane
# tmux select-pane -D -t ${SESSION_NAME}:1
#
### Finish and join the new session we just created
# join_session

#send_commands()
#{
#    # 1: Id
#    # ...: commands
#
#    THISID="$1"
#    shift
#
#    tmux -t "${SESSION_NAME}:${THISID}" "$@"
#}

send_keys()
{
    # 1: keys
    tmux send-keys -R -t "${SESSION_NAME}:${ID}" "$1" C-m
}

send_keys_to_id()
{
    # 1: ID
    # 2: keys
    tmux send-keys -R -t "${SESSION_NAME}:$1" "$2" C-m
}

pane_down()
{
    TARGET="${SESSION_NAME}:${ID}"
    tmux select-pane -D -t "${TARGET}"
}
pane_up()
{
    TARGET="${SESSION_NAME}:${ID}"
    tmux select-pane -U -t "${TARGET}"
}
pane_left()
{
    TARGET="${SESSION_NAME}:${ID}"
    tmux select-pane -L -t "${TARGET}"
}
pane_right()
{
    TARGET="${SESSION_NAME}:${ID}"
    tmux select-pane -R -t "${TARGET}"
}
statusbar()
{
    # 1: "on" or "off"
    tmux set-window-option -t "${SESSION_NAME}" status $1 
    #statements
}

new_window()
{
    # 1: name
    # 2: working directory
    # 3: extra send_keys

    # Increase ID for new window pane
    export ID=$[ ${ID} + 1 ]
    export LAST_ID=$[ $ID - 1 ]
    export PANE_ID=0
    NAME="$1"
    NEWPATH="$2"

    TARGET="${SESSION_NAME}:${ID}"

    tmux new-window -t "${TARGET}" ${TORUN} "cd \"${NEWPATH}\"; exec bash"

    # Add to clear list
    LEN=${#CLEAR_LIST[@]}
    CLEAR_LIST[$LEN]="${TARGET}.0"
    export CLEAR_LIST

    if [[ -n "${NAME}" ]]; then
        rename_window "${NAME}"
        send_keys "clear;sleep 0.5;clear;echo ${NAME}"
    fi
    if [[ -n "$3" ]]; then
        send_keys "$3"
    fi
}

split()
{
    # 1: h or v
    # 2: new path
    # 3: percentage
    # 4: name
    # 5: extra send_keys

    export PANE_ID=$[ ${PANE_ID} + 1 ]
    TARGET="${SESSION_NAME}:${ID}"
    PERCENTAGE=$3
    if [ -z "${PERCENTAGE}" ]; then
        PERCENTAGE=50
    fi

    tmux split-window -$1 -p "${PERCENTAGE}" -t "${TARGET}" "cd \"$2\"; exec bash"

    # Add to clear list
    LEN=${#CLEAR_LIST[@]}
    CLEAR_LIST[$LEN]="${TARGET}.${PANE_ID}"
    export CLEAR_LIST

    # Set inner name ( There is no useful split pane window name )
    if [[ -n "$4" ]]; then
        send_keys "clear;sleep 0.5;clear;echo $4"
    fi
    # Send keys
    if [[ -n "$5" ]]; then
        send_keys "$5"
    fi
}

hsplit()
{
    # 1: name
    # 2: new path
    # 3: percentage

    split h "$2" "$3" "$1"
}

vsplit()
{
    # 1: name
    # 2: new path
    # 3: percentage

    split v "$2" "$3" "$1"
}

new_session()
{
    # 1: Session name
    # 2: Window name
    # 3: Starting path
    # 4: Keys to send
    # 5: base index

    export BASE_INDEX=1
    if [[ -n "$5" ]]; then
        export BASE_INDEX="$5"
    fi

    export SESSION_NAME="$1"
    export ID=${BASE_INDEX}
    export LAST_ID=$[ $ID - 1 ]
    export PANE_ID=0

    # Set base index to custom value
    tmux set -g base-index ${BASE_INDEX}

    # Create the session
    tmux new-session -d -s "${SESSION_NAME}"

    # Add to clear list
    LEN=${#CLEAR_LIST[@]}
    CLEAR_LIST[$LEN]="${SESSION_NAME}:${BASE_INDEX}.0"
    export CLEAR_LIST

    # Set window name if set
    if [[ -n "$2" ]]; then
        rename_window "$2"
    fi

    # Set starting path if set
    if [[ -n "$3" ]]; then
        send_keys "cd \"$3\""
    fi

    # Show window name
    if [[ -n "$2" ]]; then
        send_keys "clear;sleep 0.5;clear;echo \"$2\""
    fi

    # Send keys
    if [[ -n "$4" ]]; then
        send_keys "$4"
    fi

}

rename_window()
{
    # 1: The new window name

    tmux rename-window -t "${SESSION_NAME}" "$1"
}

clear_history()
{
    # Clear history from cd command

    # 1: Wait time. Default below.

    WAITTIME=0.75
    if [[ -n "$1" ]]; then
        WAITTIME="$1"
    fi

    new_window tmp
    send_keys "sleep ${WAITTIME}"
    LEN=${#CLEAR_LIST[@]}
    for (( i = 0; i < $LEN; i++ )); do
        send_keys "tmux clear-history -t ${CLEAR_LIST[$i]}"
    done
    send_keys "tmux kill-window -t ${SESSION_NAME}:${ID}"
}

join_session()
{
    # Remove any text that could be seen by scrolling up
    clear_history

    # Set first window to active
    tmux select-window -t ${SESSION_NAME}:${BASE_INDEX}

    # exec to tmux so we don't leave sh instance running
    exec tmux -2 attach-session -t ${SESSION_NAME}
}

declare -a CLEAR_LIST

# send_keys 'cd "/home/herbert/repositories/snakes"'
# send_keys 'clear;echo snakes;git st'
# vsplit /home/herbert/repositories/snakes/.build_unstripped_raw/Linux/Debug 40 "snakes build output"
#
# # Add more windows
# new_window mfapi /home/herbert/repositories/libmfapi "git st"
# new_window hub_comm /home/herbert/repositories/hub_communication "git st"
#
# new_window villains /home/herbert/repositories/villains 'git st'
# vsplit /home/herbert/repositories/villains/Build/Linux 30 "Villains build"
#

# Join the tmux session
