#!/usr/bin/env bash

# Stop on error
set -e

SITE_PATH="$(pwd)"
DEPLOY_PATH="$(pwd)/_ghpages_worktree"

# 1️⃣ Ensure gh-pages branch exists
if ! git show-ref --verify --quiet refs/heads/gh-pages; then
    echo "gh-pages branch does not exist. Creating orphan branch..."
    git checkout --orphan gh-pages
    git rm -rf . --ignore-unmatch
    git commit --allow-empty -m "Init gh-pages branch"
    git push origin gh-pages
    git checkout main
fi

# 2️⃣ Use a worktree for gh-pages
if [ -d "$DEPLOY_PATH" ]; then
    rm -rf "$DEPLOY_PATH"
fi

echo "=== Adding gh-pages worktree ==="
git worktree add "$DEPLOY_PATH" gh-pages

# 3️⃣ Clear old files in worktree
echo "=== Cleaning gh-pages worktree ==="
find "$DEPLOY_PATH" -mindepth 1 -maxdepth 1 ! -name ".git" -exec rm -rf {} +

# 4️⃣ Copy site contents into worktree (excluding git and deploy artifacts)
echo "=== Copying site contents ==="
rsync -a --exclude='.git' \
         --exclude='_ghpages_worktree' \
         --exclude='deploy.sh' \
         "$SITE_PATH/" "$DEPLOY_PATH/"

# Ensure .nojekyll exists so GitHub doesn't process files through Jekyll
touch "$DEPLOY_PATH/.nojekyll"

# 5️⃣ Commit & push from worktree
cd "$DEPLOY_PATH"
git add .
if git diff --cached --quiet; then
    echo "Nothing to commit (no changes)"
else
    git commit -m "Deploy static site"
    git push origin gh-pages
fi

# 6️⃣ Clean up
cd "$SITE_PATH"
git worktree remove "$DEPLOY_PATH" --force

echo "✅ Deployment complete!"
