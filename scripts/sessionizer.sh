#!/usr/bin/env bash

# Check to see if yq exists 
if ! command -v yq &> /dev/null; then
    echo "yq could not be found. Please install it to proceed."
    exit 1
fi

# Get the location of the Tmux Session Config
sessionizer_config="${TMUX_SESSIONIZER:-$HOME/.config/tmux/sessionizer.config.yaml}"

# Check if the Tmux Session Config exists
if [[ ! -f $sessionizer_config ]]; then
    echo "Tmux session config file not found: $sessionizer_config"
    exit 1
fi

# Read the "paths" array, mindepth, and maxdepth from the yaml file using yq
paths=$(yq eval '.search_paths.paths[]' "$sessionizer_config" 2>/dev/null)
mindepth=$(yq eval '.search_paths.mindepth' "$sessionizer_config" 2>/dev/null)
maxdepth=$(yq eval '.search_paths.maxdepth' "$sessionizer_config" 2>/dev/null)

if [[ -z $paths ]]; then
    echo "No paths found in the session config file."
    exit 1
fi

if [[ -z $mindepth ]]; then
    mindepth=1  
fi

if [[ -z $maxdepth ]]; then
    maxdepth=3
fi

# Convert the paths into a format usable by find command
paths_array=()
while IFS= read -r line; do
    expanded_path=$(eval echo "$line")
    paths_array+=("$expanded_path")
done <<< "$paths"

# Build the selected directories while ignoring directories without .git or session.config.yaml
declare -A project_map  

# Build the selected directories while ignoring directories without .git
if [[ $# -eq 1 ]]; then
    selected=$1
else
    dirs=$(
        find "${paths_array[@]}" \
            -mindepth "$mindepth" \
            -maxdepth "$maxdepth" \
            \( \
                \( -type d -name ".git" -exec dirname {} \; \) -o \
                \( -type f -name ".session.config.yaml" -exec dirname {} \; \) \
            \) |
        sort -u
    )

    options=$(
        while read -r dir; do
            if [[ -f "$dir/.session.config.yaml" ]]; then
                name=$(yq eval '.name' "$dir/.session.config.yaml" 2>/dev/null)
                if [[ -n "$name" && "$name" != "null" ]]; then
                    echo -e "$name\t$dir"
                    continue
                fi
            fi
            echo -e "$dir\t$dir"
        done <<< "$dirs"
    )

    selected_line=$(echo "$options" | fzf --with-nth=1)
    selected=$(echo -e "$selected_line" | awk -F'\t' '{print $2}')
fi

echo "$selected"

[[ -z $selected ]] && exit 0

# Read session configuration
session_yaml="$selected/.session.config.yaml"

if [[ -f "$session_yaml" ]]; then
    session_name=$(yq eval '.name' "$session_yaml" 2>/dev/null)
    session_directory=$(eval echo "$(yq eval '.directory' "$session_yaml" 2>/dev/null)")
else
    session_name=$(basename "$selected" | tr . _)
    session_directory="$selected"
fi

if [[ -z "$session_name" || "$session_name" == "null" ]]; then
    session_name=$(basename "$selected" | tr . _)
fi

if [[ -z "$session_directory" || "$session_directory" == "null" ]]; then
    session_directory="$selected"
fi

tmux_running=$(pgrep tmux)


# Check if session exists already 
if ! tmux has-session -t="$session_name" 2> /dev/null; then
    tmux new-session -d -s "$session_name" -c "$session_directory"

    setup_script_length=$(yq eval '.setup_script | length' "$session_yaml" 2>/dev/null)

    if [[ $setup_script_length -gt 0 ]]; then
        for ((i=0; i<setup_script_length; i++)); do
            script=$(yq eval ".setup_script[$i]" "$session_yaml" 2>/dev/null)
            if [[ -n "$script" && "$script" != "null" ]]; then
                tmux send-keys -t "$session_name:" "$script" C-m
            fi
        done
    fi

    # Setup Session Windows 
    if [[ -f "$session_yaml" ]]; then
        window_length=$(yq eval '.windows | length' "$session_yaml" 2>/dev/null)
        
        for ((window_count=0; window_count<window_length; window_count++)); do
            window_name=$(yq eval ".windows[$window_count].name" "$session_yaml" 2>/dev/null)
            # Expanded directory path because of ~
            window_directory=$(eval echo "$(yq eval ".windows[$window_count].directory" "$session_yaml" 2>/dev/null)")

            if [[ -z "$window_name" || "$window_name" == "null" ]]; then
                window_name="window_$window_count"
            fi

            if [[ -z "$window_directory" || "$window_directory" == "null" ]]; then
                window_directory="$session_directory"
            fi
            
            if [ $window_count -eq 0 ]; then
                tmux rename-window -t "$session_name:" "$window_name"
                window_id=$(tmux list-windows -F "#{window_id}" -t "$session_name" | grep -m 1 "$window_name")
                tmux send-keys -t "$session_name:$window_name" "cd $window_directory" C-m
            else
                window_id=$(tmux new-window -P -F "#{window_id}" -t "$session_name" -n "$window_name" -c "$window_directory")
            fi

            script_length=$(yq eval ".windows[$window_count].script | length" "$session_yaml" 2>/dev/null)

            if [[ $script_length -gt 0 ]]; then
                for ((i=0; i<script_length; i++)); do
                    script=$(yq eval ".windows[$window_count].script[$i]" "$session_yaml" 2>/dev/null)
                    if [[ -n "$script" && "$script" != "null" ]]; then
                        tmux send-keys -t "$session_name:$window_name" "$script" C-m
                    fi
                done
            fi

            # TODO: Support window panes configuration.
            # If window has panes, window should not accept a script. The panes should accept the script isntead.
        done
    fi
fi

if [[ -z $TMUX ]]; then
    tmux attach-session -t "$session_name"
else
    tmux switch-client -t "$session_name"
fi
