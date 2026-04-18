WINDOW_F="/mnt/c/Users/velunae/Desktop/mvp-vpn"

git diff --name-only | while read -r file; do
  mkdir -p "$WINDOW_F/$(dirname "$file")"
  cp "$file" "$WINDOW_F/$file"
done
