# Tag files in GNU/Linux

The most native way is to use extended attributes.<br/>
This allows to store the information within the file in its "filesystem entry", and it stays with the file when one moves it on the drive.

Query them with [`getfattr`][getfattr].<br/>
Set, modify and remove them using [`setfattr`][setfattr].

## Sources

- [How to tag any file on the Unix system?]

<!--
  References
  -->

<!-- Knowledge base -->
[getfattr]: getfattr.md
[setfattr]: setfattr.md

<!-- Others -->
[how to tag any file on the unix system?]: https://unix.stackexchange.com/questions/683017/how-to-tag-any-file-on-the-unix-system
