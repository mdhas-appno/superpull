#!/bin/bash

# Find all directories in the current directory
directories=$(find . -maxdepth 1 -type d)

# Loop through each directory
for dir in $directories; do
    # Check if the directory is not the current directory or parent directory
    if [[ "$dir" != "." && "$dir" != ".." ]]; then
        # Change into the directory
        cd "$dir" || continue

        # Check if it's a git repository
        if [ -d ".git" ]; then
            echo "Pulling changes in $dir"
            # Get the current branch name
            branch=$(git rev-parse --abbrev-ref HEAD)
            # Pull from the current branch
            git pull origin "$branch"
        else
            echo "$dir is not a git repository, skipping..."
        fi

        # Move back to the original directory
        cd -
    fi
done
