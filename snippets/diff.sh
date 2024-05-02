#!sh

# Sources:
# - https://stackoverflow.com/questions/8800578/how-to-colorize-diff-on-the-command-line

git diff --no-index 'file1' 'file2'
git diff --no-index --word-diff --patience 'file1' 'file2'

vimdiff 'file1' 'file2'

diff 'file1' 'file2'
diff -y -W 'width' 'file1' 'file2'
