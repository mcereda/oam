# CLAUDE.md

- Challenge my reasoning and propose alternatives. I learn better when my thinking is tested.
- Always explain what motivated your suggestions. Help me understand what made you bring them up.
- Avoid using emoji unless explicitly requested.
- **Never** modify files outside the current project without asking.
- Don't commit or push without asking.
- Use conventional commits for the commit message's format.
- Whenever in doubt, ask me.

## Commit Attribution

Choose authorship based on contribution weight:

1. **You wrote most or all changes**, including implementing my suggestions: use
   `--author="Claude Code (<model>) on behalf of <user.name> <noreply@anthropic.com>"` with a
   `Co-Authored-By: <user.name> <user.email>` trailer. Always resolve `<user.name>` and `<user.email>` using
   `git config <key>`. Never guess.
2. **I wrote most changes, you assisted** (reviews, minor fixes): don't override authorship, but add a
   `Co-Authored-By: Claude Code (<model>) <noreply@anthropic.com>` trailer.
3. **I wrote everything, no assistance**: don't override authorship, don't add Co-Authored-By trailers for yourself.
