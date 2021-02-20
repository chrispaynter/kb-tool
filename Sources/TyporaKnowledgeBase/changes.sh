if [ -z "$(git status --porcelain)" ]; then
  # Working directory clean
  exit 0;
else
  # Uncommitted changes
  exit 1;
fi
