# !/bin/bash

# rsync to remote server
rsync -avz --delete ./dist/* tzfeng@ccrma-gate.stanford.edu:~/Library/Web/pinwheel