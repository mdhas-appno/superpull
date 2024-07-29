#!/bin/bash

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[0m'

# Function to check if a directory is a Git repository
is_git_repository() {
  [ -d "$1/.git" ]
}

# Function to check a repository
check_repository() {
  local repo_dir="$1"
  local fast_forward="$2"

  if ! is_git_repository "$repo_dir"; then
    if [[ "$verbose" == "true" ]]; then
      echo -n -e "Checking ${WHITE}$repo_dir${WHITE}... ${WHITE}Not a git repository, skipping...${WHITE}\n"
    fi
    return 4
  fi

  local default_branch=$(git -C "$repo_dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

  if [[ -z "$default_branch" ]]; then
    if [[ "$verbose" == "true" ]]; then
      echo -n -e "${YELLOW}$repo_dir${WHITE}... ${YELLOW}Local repository, no remote branch or default branch${WHITE}\n"
    fi
    return 3
  fi

  git -C "$repo_dir" fetch --all > /dev/null 2>&1 || {
    echo -e "${RED}Error fetching from $repo_dir${WHITE}"
    return 1
  }

  if [[ "$fast_forward" == "true" ]]; then
    merge_options="--ff-only"
  else
    merge_options=""
  fi

  git -C "$repo_dir" merge $merge_options origin/main > /dev/null 2>&1 || {
    echo -e "${RED}Error merging changes in $repo_dir${WHITE}"
    return 1
  }

  # ... rest of your function ...
}

# Function to print summary for changes pulled
print_summary_changes() {
  local changed_repositories=("$@")

  echo -e "${GREEN}Changes pulled in ${#changed_repositories[@]} repositories:${WHITE}"
  for repo in "${changed_repositories[@]}"; do
    echo -e "${GREEN}- $repo${WHITE}"
  done
  echo -e "\n"
}

# Function to print summary for repositories with no changes
print_summary_unchanged() {
  local unchanged_repositories=("$@")

  echo -e "${RED}No changes pulled in ${#unchanged_repositories[@]} repositories:${WHITE}"
  for repo in "${unchanged_repositories[@]}"; do
    echo -e "${RED}- $repo${WHITE}"
  done
  echo -e "\n"
}

# Function to print summary for local repositories
print_summary_local() {
  local local_repositories=("$@")

  echo -e "${YELLOW}Local repositories - ${#local_repositories[@]}:${WHITE}"
  for repo in "${local_repositories[@]}"; do
    echo -e "${YELLOW}- $repo${WHITE}"
  done
  echo -e "\n"
}

# Function to print summary for skipped repositories
print_summary_skipped() {
  local skipped_repositories=("$@")

  echo -e "${WHITE}Skipped ${#skipped_repositories[@]} repositories (not Git repositories):${WHITE}"
  for repo in "${skipped_repositories[@]}"; do
    echo -e "${WHITE}- $repo${WHITE}"
  done
  echo -e "\n"
}

# Function to print help message
print_help() {
  echo -e "Usage: $0 [OPTIONS]"
  echo -e "Options:"
  echo -e "  --summary  Show summary only"
  echo -e "  --verbose  Show detailed information"
  echo -e "  --path     Specify a path to check (optional)"
  echo -e "  --fast-forward  Enable fast-forward merges (optional)"
  echo -e "  --help     Display this help message"
}

# Check if the script is running from within a Git repository
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  top_level_dir=$(git rev-parse --show-toplevel)
else
  top_level_dir=$(pwd)
fi

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --summary)
      summary="true"
      shift # past argument
      ;;
    --verbose)
      verbose="true"
      shift # past argument
      ;;
    --path)
      path="$2"
      shift 2 # past argument and value
      ;;
    --fast-forward)
      fast_forward="true"
      shift # past argument
      ;;
    --help)
      print_help
      exit 0
      ;;
    *)  # unknown option
      echo "Unknown option: $key"
      exit 1
      ;;
  esac
done

# Determine repositories to process
if [[ -n "$path" ]]; then
  repositories=("$path")
else
  repositories=(*)
fi

# Initialize arrays to keep track of repositories
changed_repositories=()
unchanged_repositories=()
skipped_repositories=()
local_repositories=()

# Loop through each directory
for dir in $repositories; do
  check_repository "$dir" "$fast_forward"
  result=$?

  case $result in
    0) changed_repositories+=("$dir") ;;
    2) unchanged_repositories+=("$dir") ;;
    3) local_repositories+=("$dir") ;;
    4) skipped_repositories+=("$dir") ;;
  esac
done

# Print summary if --summary is passed
if [[ "$summary" == "true" ]]; then
  echo -e "\n${WHITE}Summary:\n"
  print_summary_changes "${changed_repositories[@]}"
  print_summary_local "${local_repositories[@]}"
  print_summary_unchanged "${unchanged_repositories[@]}"
  print_summary_skipped "${skipped_repositories[@]}"
fi

