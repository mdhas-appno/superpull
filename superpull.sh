#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to check a repository
check_repository() {
    local dir=$1

    # Change into the directory
    cd "$dir" >/dev/null || return 1

    # Check if it's a git repository
    if [ -d ".git" ]; then
        # Get the current branch name
        branch=$(git rev-parse --abbrev-ref HEAD)

        # Get the default branch name
        default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

        # Check if there's a default branch and a remote branch
        if [ -z "$default_branch" ] && [ -z "$(git ls-remote)" ]; then
            # Treat the repository as a local repository only
            echo -n -e "${YELLOW}$dir${NC}... ${YELLOW}Local repository, no remote branch or default branch${NC}\n"
            return 3
        else
            # Pull changes from all branches
            pull_output=$(git pull --all 2>&1)

            # Check if any changes were pulled
            if [[ "$pull_output" != "Already up to date." ]]; then
                echo -n -e "Checking ${GREEN}$dir${NC}... Changes pulled in $dir: ${GREEN}Yes${NC}\n"
                echo "$pull_output"
                return 0
            else
                echo -n -e "Checking ${GREEN}$dir${NC}... Changes pulled in $dir: ${RED}No${NC}\n"
                return 2
            fi
        fi
    else
        echo -n -e "Checking ${RED}$dir${NC}... ${RED}Not a git repository, skipping...${NC}\n"
        return 4
    fi

    # Move back to the original directory and suppress output
    cd - >/dev/null
}

# Function to print summary for changes pulled
print_summary_changes() {
    local changed_repositories=("$@")

    echo -e "${GREEN}Changes pulled in ${#changed_repositories[@]} repositories:${NC}"
    for repo in "${changed_repositories[@]}"; do
        echo -e "${GREEN}- $repo${NC}"
    done
}

# Function to print summary for repositories with no changes
print_summary_unchanged() {
    local unchanged_repositories=("$@")

    echo -e "${RED}No changes pulled in ${#unchanged_repositories[@]} repositories:${NC}"
    for repo in "${unchanged_repositories[@]}"; do
        echo -e "${RED}- $repo${NC}"
    done
}

# Function to print summary for local repositories
print_summary_local() {
    local local_repositories=("$@")

    echo -e "${YELLOW}Local repositories (no default branch or remote branch):${NC}"
    for repo in "${local_repositories[@]}"; do
        echo -e "${YELLOW}- $repo${NC}"
    done
}

# Function to print summary for skipped repositories
print_summary_skipped() {
    local skipped_repositories=("$@")

    echo -e "${RED}Skipped ${#skipped_repositories[@]} repositories (not Git repositories):${NC}"
    for repo in "${skipped_repositories[@]}"; do
        echo -e "${RED}- $repo${NC}"
    done
}

# Main script

# Get the top-level directory
top_level_dir=$(pwd)

# Find all directories in the current directory
directories=$(find . -maxdepth 1 -type d)

# Initialize arrays to keep track of repositories
changed_repositories=()
unchanged_repositories=()
skipped_repositories=()
local_repositories=()

# Loop through each directory
for dir in $directories; do
    # Check if the directory is not the current directory or parent directory
    if [[ "$dir" != "." && "$dir" != ".." ]]; then
        # Check the repository
        check_repository "$dir"
        result=$?

        case $result in
            0) changed_repositories+=("$dir") ;;
            2) unchanged_repositories+=("$dir") ;;
            3) local_repositories+=("$dir") ;;
            4) skipped_repositories+=("$dir") ;;
        esac
    fi
done

# Print summary
echo -e "\n${GREEN}Summary:${NC}"
print_summary_changes "${changed_repositories[@]}"
print_summary_unchanged "${unchanged_repositories[@]}"
print_summary_local "${local_repositories[@]}"
print_summary_skipped "${skipped_repositories[@]}"

