cd .
#!/bin/bash
#git config --global alias.make-patch

#git diff --cached --binary
git add --all
git commit -m "pre-patch"

git diff HEAD > patch000.patch


read -p "Press any key to continue." x     
