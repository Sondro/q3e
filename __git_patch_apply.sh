cd .
#!/bin/bash
# git revert 55eb4d18ff0add59ddf1a303bb665b0cdc3d40a6  f880707a9727938cd81bedcb43ac183a00358e2b

#git config --global alias.make-patch
git diff --cached --binary > patch000.patch
git apply patch000.patch
patch --forward --strip=1 < patch000.patch
read -p "Press any key to continue." x     
