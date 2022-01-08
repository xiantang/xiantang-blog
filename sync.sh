git add .
result=`git status -s`
git commit -m "$result"
git pull origin master
git push origin master
