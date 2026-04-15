#!/usr/bin/env bash
# release.sh — merge main to production, bump version, and create GitHub release
#
# Usage:
#   ./release.sh 0.2.0          # release version 0.2.0
#   ./release.sh 0.2.0 --dry-run  # show what would happen
#
# Requires: gh CLI authenticated with GitHub

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAIN_BRANCH="main"
PROD_BRANCH="production"

usage() {
  cat <<EOF
usage: $0 <version> [--dry-run]

Steps:
  1. Merge $MAIN_BRANCH → $PROD_BRANCH
  2. Bump VERSION in claude-custom
  3. Tag with v<version>
  4. Push to GitHub
  5. Create GitHub release with claude-custom as artifact

Options:
  --dry-run   show commands without executing
  --help      show this help
EOF
}

DRY_RUN=""
VERSION=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --help) usage; exit 0 ;;
    -*) die "unknown option: $arg" ;;
    *) VERSION="$arg" ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  echo "error: version required"
  usage
  exit 1
fi

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must be in semver format (e.g. 0.2.0)"
  exit 1
fi

TAG="v$VERSION"
PROD_BRANCH="$PROD_BRANCH"
CLONE_DIR=""
NEED_CLEANUP=0

cleanup() {
  if [[ -n "$CLONE_DIR" && -d "$CLONE_DIR" ]]; then
    rm -rf "$CLONE_DIR"
  fi
}
trap cleanup EXIT

run() {
  if [[ -n "$DRY_RUN" ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

echo "=== Release $TAG ==="
echo

# Step 1: Clone the repo
echo "Cloning repository..."
CLONE_DIR=$(mktemp -d)
run git clone "https://github.com/sunapi386/claude-custom.git" "$CLONE_DIR"
cd "$CLONE_DIR"

# Step 2: Fetch all
echo "Fetching all branches and tags..."
run git fetch --all --tags

# Step 3: Ensure production branch exists and is up to date with main
echo "Merging $MAIN_BRANCH → $PROD_BRANCH..."
if git rev-parse --verify "$PROD_BRANCH" &>/dev/null; then
  run git checkout "$PROD_BRANCH"
  run git merge "$MAIN_BRANCH" --no-edit
else
  echo "Creating new $PROD_BRANCH branch from $MAIN_BRANCH..."
  run git checkout -b "$PROD_BRANCH" "$MAIN_BRANCH"
fi

# Step 4: Update VERSION
echo "Updating VERSION to $VERSION..."
if grep -q "^VERSION=\"$VERSION\"" claude-custom 2>/dev/null; then
  echo "Version is already $VERSION, skipping version bump"
else
  run sed -i "s/^VERSION=\".*\"/VERSION=\"$VERSION\"/" claude-custom

  # Step 5: Commit the version bump
  echo "Committing version bump..."
  run git add claude-custom
  if git diff --cached --quiet; then
    echo "No changes to commit"
  else
    run git commit -m "Bump version to $TAG"
  fi
fi

# Step 6: Tag
echo "Tagging $TAG..."
if git rev-parse --verify "$TAG" &>/dev/null; then
  echo "Tag $TAG already exists"
else
  run git tag -a "$TAG" -m "Release $TAG"
fi

# Step 7: Push
echo "Pushing to GitHub..."
run git push origin "$PROD_BRANCH"
run git push origin "$TAG"

# Step 8: Create GitHub release with artifact
echo "Creating GitHub release..."
RELEASE_NOTES="## claude-custom $TAG

See the [changelog](https://github.com/sunapi386/claude-custom/blob/$PROD_BRANCH/README.md) for details.

### Download the script
\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/sunapi386/claude-custom/$PROD_BRANCH/claude-custom -o claude-custom
chmod +x claude-custom
\`\`\`
"

if [[ -n "$DRY_RUN" ]]; then
  echo "[dry-run] Would create release with notes:"
  echo "$RELEASE_NOTES"
else
  gh release create "$TAG" \
    --title "claude-custom $TAG" \
    --notes "$RELEASE_NOTES" \
    --target "$PROD_BRANCH" \
    "./claude-custom"
fi

echo
echo "=== Done! ==="
echo "Version $VERSION released."
echo "GitHub release: https://github.com/sunapi386/claude-custom/releases/tag/$TAG"
