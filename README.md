tmux-wrapper
============

A sh wrapper around tmux to setup sessions with custom layouts easily.

Usage
=====

```sh
# Start new tmux session:
# Note: All args are optional, Use a "" to skip argument.
new_session "NEW_SESSION_NAME" "NEW_WINDOW_NAME" /STARTING/PATH "COMMANDS"

# Add a new tab and switch to it
# Note: All args are optional, Use a "" to skip argument.
new_window WINDOW_NAME /STARTING/PATH "COMMAND TO RUN"

# Split the window
vsplit PANE_NAME /STARTING/PATH PERCENT_TO_SPLIT "COMMANDS TO RUN"

# Select the top pane
tmux select-pane -D -t ${SESSION_NAME}:1

# Finish and join the new session we just created
join_session
```

Examples
========

Simple Example
--------------

```sh
#!/bin/sh

# Load the tmux-wrapper sh library
. tmux-wrapper.sh

new_session "test_session" "home" "~/" "" "1"
vsplit "" "" 25
pane_up

new_window "etc" "/etc/"
new_window "varlog" "/var/log/"

join_session
```

Open each directory in its own window
-------------------------------------

```sh
#!/bin/sh

BASE_PATH=~/Devel/projects

# Load our tmux bash library
. tmux-wrapper.sh

BPN="`basename "${BASE_PATH}"`"
new_session "${BPN}" "${BPN}" "${BASE_PATH}"
for i in `find "${BASE_PATH}" -mindepth 1 -maxdepth 1 -type d`; do
    BN="`basename "$i"`"
    new_window "${BN}" "$i"
done

join_session
```

