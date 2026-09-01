# I don't recommend running this, it's just a reference since this is a delicate operation
echo "just read me bro"
exit

BAD_FILE="path/to/badfile"
TGT_BRANCH="event_dump_fix"
# Logs/1339.28/1339.28.39_main.log

# confirm current branch
git status -b

# # create a safety backup of the full repo
# git clone --mirror . ../repo_backup.git

# verify exact path and commit introducing it
git log --follow --diff-filter=A -- $BAD_FILE

# (note the introducing commit hash, call it BAD)

# stay on current branch; rewrite only this branch
git filter-repo \
  --refs "$(git branch --show-current)" \
  --path "$BAD_FILE" \
  --invert-paths \
  --force

# clean filter-repo backups
rm -rf .git/refs/original
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# verify file is gone from history and tree
git log -- $BAD_FILE
git ls-tree -r --name-only HEAD | grep -F "$BAD_FILE" || echo "file removed"

# confirm your development tip still exists (new hash now)
git log -1

# # continue working from new head
# # (optionally reattach upstream if this branch tracked remote)
# git branch --set-upstream-to=origin/$(git branch --show-current) 2>/dev/null || true

# # when ready to publish the cleaned branch
# git push origin $(git branch --show-current) --force

# # --------------------------   Worked example   ------------------------------------
# # event_dump_fix
# # 08aa9b3f6a3cf61abde759e0ccfa1a76da7ae963
# # Logs/1339.28/1339.28.39_main.log
git filter-repo \
  --refs "08aa9b3f6a3cf61abde759e0ccfa1a76da7ae963^..HEAD" \
  --path "Logs/1339.28/1339.28.39_main.log" \
  --invert-paths \
  --force

# git ls-tree -r --name-only HEAD | grep -F 'Logs/1339.28/1339.28.39_main.log' || echo "file removed"