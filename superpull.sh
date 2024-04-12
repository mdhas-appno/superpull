#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get the top-level directory
top_level_dir=$(pwd)

# Find all directories in the current directory
directories=$(find . -maxdepth 1 -type d)

# Initialize variables to keep track of changes and skipped repositories
changes_occurred=0
repositories_skipped=0
local_repositories=0

# Arrays to store information for the summary
changed_repositories=()
unchanged_repositories=()
skipped_repositories=()
local_repositories=()

# Loop through each directory
for dir in $directories; do
    # Check if the directory is not the current directory or parent directory
    if [[ "$dir" != "." && "$dir" != ".." ]]; then
        # Change into the directory
        cd "$dir" >/dev/null || continue

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
                local_repositories=$((local_repositories + 1))
                local_repositories+=("$dir") # Add local repository to the array
            else
                # Pull changes from all branches
                pull_output=$(git pull --all 2>&1)

                # Check if any changes were pulled
                if [[ "$pull_output" != "Already up to date." ]]; then
                    echo -n -e "Checking ${GREEN}$dir${NC}... Changes pulled in $dir: ${GREEN}Yes${NC}\n"
                    echo "$pull_output"
                    changes_occurred=$((changes_occurred + 1))
                    changed_repositories+=("$dir")
                else
                    echo -n -e "Checking ${GREEN}$dir${NC}... Changes pulled in $dir: ${RED}No${NC}\n"
                    unchanged_repositories+=("$dir")
                fi
            fi
        else
            echo -n -e "Checking ${RED}$dir${NC}... ${RED}Not a git repository, skipping...${NC}\n"
            repositories_skipped=$((repositories_skipped + 1))
            skipped_repositories+=("$dir")
        fi

        # Move back to the original directory and suppress output
        cd - >/dev/null
    fi
done

# Print summary for changes pulled
echo -e "\n${GREEN}Summary:${NC}"
echo -e "${GREEN}Changes pulled in ${#changed_repositories[@]} repositories:${NC}"
for repo in "${changed_repositories[@]}"; do
    echo -e "${GREEN}- $repo${NC}"
done

# Print summary for repositories with no changes
echo -e "\n${RED}No changes pulled in ${#unchanged_repositories[@]} repositories:${NC}"
for repo in "${unchanged_repositories[@]}"; do
    echo -e "${RED}- $repo${NC}"
done

# Print summary for local repositories
echo -e "\n${YELLOW}Local repositories (no default branch or remote branch):${NC}"
for repo in "${local_repositories[@]}"; do
    echo -e "${YELLOW}- $repo${NC}"
done

# Print summary for skipped repositories
echo -e "\n${RED}Skipped ${repositories_skipped} repositories (not Git repositories):${NC}"
for repo in "${skipped_repositories[@]}"; do
    echo -e "${RED}- $repo${NC}"
done

