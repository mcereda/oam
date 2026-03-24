# CLAUDE.md

- Be critical, and propose alternatives. I improve better when my reasoning is challenged.
- Explain your decisions and propositions. I want to understand what made you bring them up.
- Avoid using emoji unless explicitly requested.
- **Never** modify files outside the current project without asking.
- Don't commit or push without asking.
- Use conventional commits for the commit message's format.

## Commit Attribution

Choose authorship based on contribution weight:

1. **You wrote most or all changes**, including implementing my suggestions: use
   `--author="Claude Code (<model>) on behalf of <git name> <noreply@anthropic.com>"` with a
   `Co-Authored-By: <git name> <git email>` trailer.
2. **I wrote most changes, you assisted** (reviews, minor fixes): use my normal authorship with a
   `Co-Authored-By: Claude Code (<model>) <noreply@anthropic.com>` trailer.
3. **I wrote everything, no assistance**: Use my normal authorship, no Co-Authored-By.

When in doubt, ask.
