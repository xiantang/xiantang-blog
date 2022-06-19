#!/bin/bash

# config git user
git config user.email "zhujingdi1998@gmail.com"
git config user.name "xiantang"


git config pull.rebase false
git add .
result=`git status -s`
git commit -m "$result"
git pull origin code
git push origin code
