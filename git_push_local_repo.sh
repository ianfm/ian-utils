# From the new repo starter page on github
# prereqs: git init .; git add .; git commit -m "first commit"
#          created EMPTY repo on github
GIT_REPO = ""
GIT_USER = ""
git remote add origin git@github.com:$GIT_USER/$GIT_REPO.git
git branch -M main
git push -u origin main
