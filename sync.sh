git add .
result=`git status -s`
git commit -m "$result"
git pull origin code
git push origin code
