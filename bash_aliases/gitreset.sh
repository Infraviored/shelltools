gitreset() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git reset --hard origin/$(git symbolic-ref --short HEAD)
  else
    echo "Not in a git repository"
  fi
}
