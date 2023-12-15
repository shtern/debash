check_and_update_status() {
    global_json_file="$HOME/.git_update_status"

    if [ ! -f "$global_json_file" ]; then
        echo '{"repositories": []}' > "$global_json_file"
    fi
    json_content=$(cat $global_json_file)

    if git fetch origin -q; then
        local_commit=$(git log -n1 --pretty=format:%ct)
        remote_commit=$(git log -n1 origin/$(git rev-parse --abbrev-ref HEAD) --pretty=format:%ct)

        if [[ "$local_commit" -ge "$remote_commit" ]]; then
            status=1
        else
            status=0
        fi

        repo_name=$(basename $(git rev-parse --show-toplevel))
        branch_name=$(git rev-parse --abbrev-ref HEAD)
        timestamp=$(date +%s)

        # Check if the repository already exists in the JSON
        repo_exists=$(echo "$json_content" | jq --arg repo "$repo_name" '.repositories[] | select(has($repo))')

        if [ -z "$repo_exists" ]; then
            # Repository doesn't exist, add it along with the first branch
            updated_json=$(echo "$json_content" | jq \
                --arg repo "$repo_name" \
                --arg branch "$branch_name" \
                --arg status "$status" \
                --arg timestamp "$timestamp" \
                '.repositories += [{($repo): [{"\($branch)": { "status": $status, "timestamp": ($timestamp | tonumber) }}]}]')
        else
            updated_json=$(echo "$json_content" | jq \
                    --arg repo "$repo_name" \
                    --arg branch "$branch_name" \
                    --arg status "$status" \
                    --arg timestamp "$timestamp" \
                    '.repositories |= map(if .[$repo] then .[$repo] |= map(if .[$branch] then .[$branch] = { "status": $status, "timestamp": ($timestamp | tonumber) } else . + { ($branch): { "status": $status, "timestamp": ($timestamp | tonumber) } } end) else . end)')
        fi
        echo "$updated_json" > "$global_json_file.tmp" 

        mv "$global_json_file.tmp" "$global_json_file"
    fi
}

handle_unknown() {
    echo "unknown"
    (check_and_update_status > /dev/null 2>&1 & disown) 2> /dev/null
}

get_repo_status() {
    global_json_file="$HOME/.git_update_status"
    repo_name=$(basename "$(git rev-parse --show-toplevel)")
    branch_name=$(git rev-parse --abbrev-ref HEAD)

    if [ ! -f "$global_json_file" ]; then
        handle_unknown
        return
    fi

    json_content=$(cat "$global_json_file")

    repo_data=$(jq --arg repo "$repo_name" '.repositories[] | select(has($repo))' <<< "$json_content")

    if [ -z "$repo_data" ]; then
        handle_unknown
        return
    fi

    branch_data=$(jq --arg repo "$repo_name" --arg branch "$branch_name" '.[$repo][] | select(has($branch))' <<< "$repo_data")

    if [ -z "$branch_data" ]; then
        handle_unknown
        return
    fi

    stored_timestamp=$(jq --arg branch "$branch_name" '.[$branch].timestamp' <<< "$branch_data")

    if [ -z "$stored_timestamp" ]; then
        handle_unknown
        return
    fi

    current_timestamp=$(date +%s)
    time_difference=$((current_timestamp - stored_timestamp))
    status=$(jq --arg branch "$branch_name" '.[$branch].status' <<< "$branch_data" | tr -d '"')
    status=$((status))

    if [ "$time_difference" -le 900 ]; then
         if [ "$status" -eq 1 ]; then
            echo "up-to-date"
        else
            echo "outdated"
        fi
    else
        handle_unknown
        return
    fi
}


