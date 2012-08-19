#!/bin/sh

## @description
#
#  Basic usage:
#  ============
#
#  Start new tmux session
#  ----------------------
#  Note: All args are optional, Use a "" to skip argument.
#
#  ```new_session "NEW_SESSION_NAME" "NEW_WINDOW_NAME" /STARTING/PATH "COMMANDS"```
#
#  Add a new tab and switch to it
#  ------------------------------
#  Note: All args are optional, Use a "" to skip argument.
#
#  ```new_window WINDOW_NAME /STARTING/PATH "COMMAND TO RUN"```
#
#  Split the window
#  ----------------
#  ```vsplit PANE_NAME /STARTING/PATH PERCENT_TO_SPLIT "COMMANDS TO  RUN"```
#
#  Select the top pane
#  -------------------
#  ```tmux select-pane -D -t ${SESSION_NAME}:1```
#
#  Finish and join the new session we just created
#  -----------------------------------------------
#  ```join_session```
#
## @file tmux-wrapper.sh


## Send keys to current window.
#
#  Automatically sends enter key after sending keys.
#
#  @param String  Keys to insert into window.
send_keys()
{
    tmux send-keys -R -t "${SESSION_NAME}:${ID}" "$1" C-m
}

## Send keys to a specific ID for current session.
#
#  Same as send_keys, but the id must be passed in.
#  @param Number  Window ID to receive keys
#  @param String  Keys to insert into window.
send_keys_to_id()
{
    tmux send-keys -R -t "${SESSION_NAME}:$1" "$2" C-m
}

## Set current pane to one below. Wraps around.
pane_down()
{
    TARGET="${SESSION_NAME}:${ID}"
    tmux select-pane -D -t "${TARGET}"
}

## Set current pane to one above. Wraps around.
pane_up()
{
    TARGET="${SESSION_NAME}:${ID}"
    tmux select-pane -U -t "${TARGET}"
}

## Set current pane to one to the left. Wraps around.
pane_left()
{
    TARGET="${SESSION_NAME}:${ID}"
    tmux select-pane -L -t "${TARGET}"
}

## Set current pane to one to the right. Wraps around.
pane_right()
{
    TARGET="${SESSION_NAME}:${ID}"
    tmux select-pane -R -t "${TARGET}"
}

## Set status bar on or off
#  @param String  "on" or "off"
statusbar()
{
    # 1: "on" or "off"
    tmux set-window-option -t "${SESSION_NAME}" status $1
    #statements
}

## Create a new "window"(More like a tab)
#  @param String  Name of window. Will appear in status bar as the name
#                 of the tab. Use "" to skip.
#  @param String  Directory path to use as the current working directory
#                 for the window. Use "" to use the current working
#                 directory.
#  @param String  Keys to send to the window. Can be used to start a
#                 program automatically.
new_window()
{
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

## Split a window or pane into panes.
#  Used by hsplit and vsplit.
#  @param Char  'h' for horizontal, 'v' for vertical.
#  @param String  Name of window. Will appear in status bar as the name
#                 of the tab. Use "" to skip.
#  @param String  Directory path to use as the current working directory
#                 for the window. Use "" to use the current working
#                 directory.
#  @param Number  Percentage of space the new pane will take from the
#                 existing area.
#  @param String  Keys to send to the window. Can be used to start a
#                 program automatically.
split()
{
    export PANE_ID=$[ ${PANE_ID} + 1 ]
    TARGET="${SESSION_NAME}:${ID}"
    PERCENTAGE=$4
    if [ -z "${PERCENTAGE}" ]; then
        PERCENTAGE=50
    fi

    tmux split-window -$1 -p "${PERCENTAGE}" -t "${TARGET}" "cd \"$3\"; exec bash"

    # Add to clear list
    LEN=${#CLEAR_LIST[@]}
    CLEAR_LIST[$LEN]="${TARGET}.${PANE_ID}"
    export CLEAR_LIST

    # Set inner name ( There is no useful split pane window name )
    if [[ -n "$2" ]]; then
        send_keys "clear;sleep 0.5;clear;echo $2"
    fi
    # Send keys
    if [[ -n "$5" ]]; then
        send_keys "$5"
    fi
}

## Split a window or pane horizontally.
#  @param String  Name of window. Will appear in status bar as the name
#                 of the tab. Use "" to skip.
#  @param String  Directory path to use as the current working directory
#                 for the window. Use "" to use the current working
#                 directory.
#  @param Number  Percentage of space the new pane will take from the
#                 existing area.
#  @param String  Keys to send to the window. Can be used to start a
#                 program automatically.
hsplit()
{
    split h "$1" "$2" "$3" "$4"
}

## Split a window or pane vertically.
#  @param String  Name of window. Will appear in status bar as the name
#                 of the tab. Use "" to skip.
#  @param String  Directory path to use as the current working directory
#                 for the window. Use "" to use the current working
#                 directory.
#  @param Number  Percentage of space the new pane will take from the
#                 existing area.
#  @param String  Keys to send to the window. Can be used to start a
#                 program automatically.
vsplit()
{
    split v "$1" "$2" "$3" "$4"
}

## Begin a new tmux session.
#  This is required before anything else.
#  @param String  Name of the session.
#  @param String  Name of window. Will appear in status bar as the name
#                 of the tab. Use "" to skip.
#  @param String  Directory path to use as the current working directory
#                 for the window. Use "" to use the current working
#                 directory.
#  @param String  Keys to send to the window. Can be used to start a
#                 program automatically.
#  @param Number  The base index tmux will use to start counting from.
new_session()
{
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

## Rename the current window
#  @param String  The new window name.
rename_window()
{
    tmux rename-window -t "${SESSION_NAME}:${ID}" "$1"
}

## Clears all history one could normally see by scrolling up.
#  Unseen commands to set the directories and echo out the window names
#  is visible if one scrolls up, or changes the window size. This
#  handles removing that, which can startle one as one forgets about it.
#  @param Number  Time to wait before executing clear.
clear_history()
{
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

## Join the last created session.
#  The last created session will become active in the current window.
#  This is not necessary if one is only setting up several sessions,
#  such as during startup.
join_session()
{
    # Remove any text that could be seen by scrolling up
    clear_history

    # Set first window to active, but do so so that a window order is
    # created.
    for i in `seq ${ID} -1 ${BASE_INDEX}`; do
        tmux select-window -t ${SESSION_NAME}:$i
    done

    # exec to tmux so we don't leave sh instance running
    exec tmux -2 attach-session -t ${SESSION_NAME}
}

# Create the array for clear history.
declare -a CLEAR_LIST
