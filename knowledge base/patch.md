# Patch

Tools and formats for creating and applying patches to text files.

1. [TL;DR](#tldr)
1. [Traditional unified diff format](#traditional-unified-diff-format)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Create traditional unified diff patch files.
diff -u 'original_file' 'modified_file' > 'output.patch'

# Create git-format patch files (includes a/ b/ path prefixes).
git diff > 'output.patch'
git diff HEAD~1 HEAD > 'output.patch'


# Apply traditional patch files.
patch -p1 < 'file.patch'
patch -p1 -o '/dev/stdout' 'path/to/original/file' < 'file.patch'

# Apply git-format patches.
git apply 'file.patch'
git apply --check 'file.patch'    # dry run; non-zero exit on failure
git apply --reverse 'file.patch'  # undo a previously applied patch
```

</details>

## Traditional unified diff format

```diff
--- a/path/to/file
+++ b/path/to/file
@@ -9,13 +9,24 @@
 context line
 context line
+added line
-removed line
 context line
```

Lines starting with `-` are **removed** from the old file.<br/>
Lines starting with `+` are **added** in the new file.<br/>
Lines starting with ` ` (space) are unchanged context shown for orientation.

Each hunk starts with `@@ -a,b +c,d @@`:

| Field | Meaning                                                           |
| ----- | ----------------------------------------------------------------- |
| `a`   | Starting line number in the **old** file                          |
| `b`   | Number of lines shown from the **old** file (space + minus lines) |
| `c`   | Starting line number in the **new** file                          |
| `d`   | Number of lines shown from the **new** file (space + plus lines)  |

To recount `b` and `d` manually when editing a patch by hand:

```plaintext
b = (number of lines in hunk body starting with ' ') + (lines starting with '-')
d = (number of lines in hunk body starting with ' ') + (lines starting with '+')
```

Context lines count toward **both** `b` and `d`, removed lines count only toward `b`, and added lines count only
toward `d`.

## Further readings

### Sources

- [GNU diffutils manual]
- [`git-apply` documentation]

<!--
  Reference
  ═╬═Time══
  -->

[GNU diffutils manual]: https://www.gnu.org/software/diffutils/manual/diffutils.html
[`git-apply` documentation]: https://git-scm.com/docs/git-apply
