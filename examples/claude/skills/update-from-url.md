---
name: update-from-url
description: >-
  Update a knowledge base article by comparing it against a reference URL. Use this skill when the user wants to enrich,
  update, or fill gaps in an existing article using a web page or article as reference — without copying text verbatim.
  Also handles contradictions (proposing removal or rewrite of conflicting content) and source attribution.
  Trigger when the user says things like "update this doc based on <URL>", "use this link to improve the page",
  "check what's missing compared to <URL>", or "enrich this article from <reference>".
argument-hint: <url> [document-path]
---

# Update From URL

You are updating a knowledge base article by using a reference URL to identify missing concepts and gaps.

**Arguments:** $ARGUMENTS

The first argument is the reference URL (required). The second argument is the path to the article to update
(optional — defaults to the currently open file in the IDE).

## Workflow

### Step 1: Gather inputs

Do both in parallel — they are independent:

- **Fetch the reference.** Use `WebFetch` to retrieve the full content. If the fetch fails, inform the user and stop.
- **Read the target article.** Understand its structure, voice, and what it already covers.

### Step 2: Analyze

Compare the two documents. The reference is a source of *ideas* for what to cover, not a source of truth. For every
difference you find, cross-check it against the target article, the project's existing docs, and your own knowledge.

Identify concepts, practices, details, or sections that are:

- **Missing entirely** from the target article
- **Underrepresented** — mentioned briefly but covered in much more depth in the reference
- **Outdated or contradicted** — the reference contains newer or more accurate information that conflicts with existing
  content

For each potential addition, assess its accuracy:

- If you know a claim to be wrong, do not propose it — surface it as a contradiction instead.
- If you cannot verify a claim and it is not obviously correct, mark it as unverified so the user can decide.

Ignore differences that are purely stylistic or organizational. Focus on substance.

If the article already covers everything in the reference, tell the user and stop.

### Step 3: Present the plan

Before making any edits, present a summary for the user to review. Format as two sections:

**Additions** — a concise list of:

- What will be added or expanded
- Where in the article each addition fits
- Brief rationale for each (why it matters)

**Contradictions** — flag anything in the reference that conflicts with existing content in the article, or that you
identified as incorrect in the verification step. For each contradiction:

- Quote the conflicting passage in the article
- Explain what the reference says instead and why it appears more accurate
- Propose whether to **remove or rewrite** the conflicting content

Do not silently overwrite or remove — let the user decide on each contradiction.

If there are no contradictions, say so.

**Source attribution** — if the reference URL is not already linked somewhere in the article, propose where to add it
(e.g., inline, in a "References" section, or as a footnote) so the user can approve or adjust the placement.

**Wait for user confirmation before editing.**

### Step 4: Apply the changes

Edit the article to incorporate the approved additions. Follow these rules:

- **Do not copy text** from the reference. Rewrite concepts in the article's own voice and style.
- **Only remove content the user explicitly approved for removal** in the contradictions review.
- **Respect the article's structure.** Place new content where it logically belongs.
- **Follow writing conventions** from the project's CLAUDE.md (line width, link style, markdown flavor, etc.).
- **Keep additions proportional.** A minor gap gets a sentence or two, not a new section.
- **Match the link style.** If the article uses reference-style links, add new definitions alongside existing ones.
- **Add the source link** in the location the user approved during the plan.

### Step 5: Summarize

After editing, briefly tell the user what changed — additions, removals, and rewrites.
