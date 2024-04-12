#!/bin/bash

# Find all directories in the current directory
directories=$(find . -maxdepth 1 -type d)

# Initialize a variable to keep track of changes
changes_occurred=0

# Loop through each directory
for dir in $directories; do
    # Check if the directory is not the current directory or parent directory
    if [[ "$dir" != "." && "$dir" != ".." ]]; then
        # Change into the directory
        cd "$dir" || continue

        # Check if it's a git repository
        if [ -d ".git" ]; then
            # Get the current branch name
            branch=$(git rev-parse --abbrev-ref HEAD)

            # Pull changes from all branches
            pull_output=$(git pull --all 2>&1)

            # Check if any changes were pulled
            if [[ "$pull_output" != "Already up to date." ]]; then
                echo "Changes pulled in $dir:"
                echo "$pull_output"
                changes_occurred=1
            fi
        fi

        # Move back to the original directory
        cd -
    fi
done

# Print summary if changes occurred
if [ $changes_occurred -eq 0 ]; then
    echo "No changes pulled in any repositories."
fi

