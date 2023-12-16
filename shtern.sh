RED="\[\033[01;31m\]"
YELLOW="\033[01;33m"
WHITE_ON_YELLOW="\033[97;43m"
GREEN="\[\033[01;32m\]"
WHITE_ON_GREEN="\[\033[97;42m\]"
BLUE="\[\033[01;34m\]"
WHITE_ON_BLUE="\[\033[97;44m\]"
NO_COLOR="\033[00m"
WHITE="\[\033[01;37m\]"
GREEN_ON_BLUE="\033[0;32;44m"
ORANGE="\033[38;5;208m"  # Orange text
WHITE_ON_ORANGE="\033[97;48;5;208m"  # White text on orange background
CYAN="\033[0;36m"
BLUE_ON_CYAN="\033[0;44m"
WHITE_ON_CYAN="\033[97;46m"   # White text on cyan background

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/git_update_status.sh"

git_status_summary() {
    local status_output
    status_output=$(git status --porcelain)

    local modified_count=0
    local added_count=0
    local deleted_count=0
    local renamed_count=0
    local copied_count=0
    local untracked_count=0
    local ignored_count=0
    local conflicted_count=0

    while IFS= read -r line; do
        case ${line# } in
            M*) ((modified_count++)) ;;
            A*) ((added_count++)) ;;
            D*) ((deleted_count++)) ;;
            R*) ((renamed_count++)) ;;
            C*) ((copied_count++)) ;;
            \?\?*) ((untracked_count++)) ;;
            \!\!*) ((ignored_count++)) ;;
            U*) ((conflicted_count++)) ;;
        esac
    done <<< "$status_output"

    local summary=""
    if ((modified_count > 0)); then
        summary+=" ${modified_count}+-"
    fi
    if ((added_count > 0)); then
        summary+=" ${added_count}+"
    fi
    if ((deleted_count > 0)); then
        summary+=" ${deleted_count}-"
    fi
    if ((renamed_count > 0)); then
        summary+=" ${renamed_count}R"
    fi
    if ((copied_count > 0)); then
        summary+=" ${copied_count}C"
    fi
    if ((untracked_count > 0)); then
        summary+=" ${untracked_count}??"
    fi
    if ((ignored_count > 0)); then
        summary+=" ${ignored_count}!!"
    fi
    if ((conflicted_count > 0)); then
        summary+=" ${conflicted_count}U"
    fi
    repo_status="$(get_repo_status)"
    repo_status_trimmed="${repo_status// /}"

    if [[ "$repo_status_trimmed" == "outdated" ]]; then
        summary+=" outdated  "
    fi
    echo "${summary# }"
}

function parse_git_branch() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    local branch_name=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
    local git_status=$(git_status_summary)
    
    if [ -n "$branch_name" ]; then
      local status_info=""
      if [ -n "$git_status" ]; then
        status_info=" ($git_status)"
      fi
      echo -ne "${WHITE_ON_CYAN}  $branch_name${NO_COLOR}${CYAN}$status_info"
    else
      echo ""
    fi
  else
    echo ""
  fi
}

PS1="${WHITE_ON_GREEN}$USER${NO_COLOR}${GREEN_ON_BLUE}${WHITE_ON_BLUE}\w${NO_COLOR}${BLUE}\$(parse_git_branch)\n$BLUE $WHITE"

# Function to reset text color after command execution
reset_color() {
    echo -ne "${NO_COLOR}"
}

# Trap command to reset text color after command execution
trap  'reset_color' DEBUG