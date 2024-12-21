#!/bin/bash
# Enhanced changelog generation script with better organization

set -euo pipefail

generate_header() {
    cat << EOF
#+TITLE: Changelog
#+DATE: $(date +%Y-%m-%d)
* [Unreleased]
** Changed

EOF
}

# Primary change types in order of importance
TYPES=(
    "Features"
    "Refactor"
    "Documentation"
    "Fixes"
    "Chores"
    "Build"
)

# Common feature scopes that deserve subsections
FEATURE_SCOPES=(
    "dev-env"
    "setup"
    "build"
    "scripts"
    "env"
)

parse_commit() {
    local msg="$1"
    local type scope description
    
    # Extract parts using sed, handling both feat(scope) and feat: formats
    if echo "$msg" | grep -q "^[a-z]\+([^)]\+):"; then
        # Format: type(scope): description
        type=$(echo "$msg" | sed -n 's/^\([a-z]*\)(\([^)]*\)): .*/\1/p')
        scope=$(echo "$msg" | sed -n 's/^\([a-z]*\)(\([^)]*\)): .*/\2/p')
        description=$(echo "$msg" | sed -n 's/^\([a-z]*\)(\([^)]*\)): \(.*\)/\3/p')
    else
        # Format: type: description
        type=$(echo "$msg" | sed -n 's/^\([a-z]*\): .*/\1/p')
        scope="general"
        description=$(echo "$msg" | sed -n 's/^\([a-z]*\): \(.*\)/\2/p')
    fi
    
    # Default values if parsing fails
    type=${type:-other}
    scope=${scope:-general}
    description=${description:-$msg}
    
    # Normalize type names
    case "$type" in
        feat|feature)     echo "Features|$scope|$description" ;;
        fix)             echo "Fixes|$scope|$description" ;;
        docs)            echo "Documentation|$scope|$description" ;;
        style)           echo "Style|$scope|$description" ;;
        refactor)        echo "Refactor|$scope|$description" ;;
        test)            echo "Tests|$scope|$description" ;;
        chore)           echo "Chores|$scope|$description" ;;
        build)           echo "Build|$scope|$description" ;;
        *)               echo "Other|$scope|$description" ;;
    esac
}

generate_feature_section() {
    local commits="$1"
    local printed_header=false
    
    for scope in "${FEATURE_SCOPES[@]}"; do
        local scope_commits=$(echo "$commits" | grep "Features|$scope|" || true)
        if [ -n "$scope_commits" ]; then
            if [ "$printed_header" = false ]; then
                echo "*** Features"
                printed_header=true
            fi
            # Convert scope to title case
            scope_title=$(echo "$scope" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
            echo "**** $scope_title"
            echo "$scope_commits" | cut -d'|' -f3 | sed 's/^/- /'
            echo
        fi
    done
    
    # Handle any remaining features
    local other_commits=$(echo "$commits" | grep "Features|" | grep -v -E "Features|($(IFS=\|; echo "${FEATURE_SCOPES[*]}"))|" || true)
    if [ -n "$other_commits" ]; then
        if [ "$printed_header" = false ]; then
            echo "*** Features"
        fi
        echo "$other_commits" | cut -d'|' -f3 | sed 's/^/- /'
        echo
    fi
}

generate_section() {
    local type="$1"
    local commits="$2"
    
    local section_commits=$(echo "$commits" | grep "^$type|" || true)
    if [ -n "$section_commits" ]; then
        echo "*** $type"
        while IFS='|' read -r _ scope description; do
            if [ "$scope" != "general" ]; then
                echo "- $description ($scope)"
            else
                echo "- $description"
            fi
        done <<< "$section_commits"
        echo
    fi
}

generate_changelog() {
    local last_tag current_date range
    
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    current_date=$(date +%Y-%m-%d)
    
    # Generate header
    generate_header
    
    # Get range of commits
    if [ -n "$last_tag" ]; then
        range="$last_tag..HEAD"
    else
        range="HEAD"
    fi
    
    # Process all commits and store the formatted output
    local all_commits=$(git log --format="%s" $range | while read -r commit_msg; do
        # Skip merge commits
        if [[ $commit_msg != Merge* ]]; then
            parse_commit "$commit_msg"
        fi
    done)
    
    # Generate Features section with subsections
    generate_feature_section "$all_commits"
    
    # Generate other sections
    for type in "${TYPES[@]}"; do
        if [ "$type" != "Features" ]; then
            generate_section "$type" "$all_commits"
        fi
    done
    
    # Add previous releases if they exist
    if [ -n "$last_tag" ]; then
        echo "* Previous Releases"
        git tag -l --sort=-v:refname | while read -r tag; do
            local tag_date
            tag_date=$(git log -1 --format=%ai "$tag" | cut -d' ' -f1)
            echo "** [$tag] - $tag_date"
            git log --format="- %s" "$tag" -n 1
            echo
        done
    fi
}

main() {
    if ! generate_changelog > CHANGELOG.org; then
        echo "Error generating changelog"
        exit 1
    fi
    
    echo "Changelog generated at CHANGELOG.org"
    
    # Commit if requested
    if [ "${1:-}" = "--commit-message" ]; then
        shift
        message=${1:-"docs(changelog): update changelog [skip ci]"}
        git add CHANGELOG.org
        git commit -m "$message"
        echo "Changelog committed with message: $message"
    fi
}

main "$@"
