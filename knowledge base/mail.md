# Mail

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Just test the presence for new emails.
# Exit status '0' means there are, '1' there is none.
mail -e

# Read all unread emails at once.
cat '/var/mail/username'

# Read automatically saved messages.
cat "$HOME/mbox"

# Send emails.
mail -s 'Subject' 'recipient@mail.server'
echo '' | mail -a 'attachment.file' -s 'Subject' 'recipient@mail.server'

# Send larger files.
cat 'file.txt' | mail -s 'Subject' 'recipient@mail.server'

# Make "email-safe" the contents of a file before sending it.
uuencode 'file.txt' | mail -s 'Subject' 'recipient@mail.server'

# Delete all emails at once.
echo -n > '/var/mail/username'
sudo rm '/var/mail/username'
```

| Command                                                       | Description                                          |
| ------------------------------------------------------------- | ---------------------------------------------------- |
| `?`                                                           | View the help                                        |
| `p`, `print`<br/>`p 3`<br/>`p 3 6`<br/>`p 3-10`<br/>`p *`     | Print all messages in the list to the default output |
| `t`, `type`                                                   | Synonym for `p`                                      |
| `mo`, `more`<br/>`mo 3`<br/>`mo 3 6`<br/>`mo 3-10`<br/>`mo *` | Print all messages in the list to the default pager  |
| `n`, `next`<br/>`n 3`<br/>`n 3 6`<br/>`n 3-10`<br/>`n *`      | Print the next message in the list                   |
| `d`, `delete`<br/>`d 3`<br/>`d 3 6`<br/>`d 3-10`<br/>`d *`    | Mark all messages in the list as deleted             |
| `q`, `quit`                                                   | Quit saving unresolved messages under `~/mbox`       |
| `x`, `ex`, `exit`                                             | Quit **without** making changes to the mailbox       |

## Further readings

### Sources

- [`man` page][man page]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[linux mail command examples]: https://www.binarytides.com/linux-mail-command-examples/
[man page]: https://linux.die.net/man/1/mail
[uuencode]: https://linux.101hacks.com/unix/uuencode/
