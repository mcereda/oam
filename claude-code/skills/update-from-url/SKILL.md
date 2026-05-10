---
name: update-from-url
description: >-
  Update a knowledge base article by comparing it against a reference URL. Use
  this skill when the user wants to enrich, update, or fill gaps in an existing
  article using a web page or article as reference — without copying text
  verbatim. Verifies source suitability and corroborates each proposed change
  via web search before presenting the plan. Also handles contradictions
  (proposing removal or rewrite of conflicting content) and source attribution.
  Trigger when the user says things like "update this doc based on <URL>", "use
  this link to improve the page", "check what's missing compared to <URL>", or
  "enrich this article from <reference>".
argument-hint: <url> [document-path]
model: opus
effort: xhigh
---

# Update From URL

You are updating a knowledge base article by using a reference URL to identify
missing concepts and gaps.

**Arguments:** $ARGUMENTS

The first argument is the reference URL (required). The second argument is the
path to the article to update (optional — defaults to the currently open file in
the IDE).

## Workflow

### Step 1: Gather inputs

Do both in parallel — they are independent:

- **Fetch the reference.** Use `WebFetch` to retrieve the full content. If the
  fetch fails, inform the user and stop.
- **Read the target article.** Understand its structure, voice, and what it
  already covers.

### Step 2: Verify the source

Before using the fetched content, verify it is suitable as a reference:

- **Content check.** Confirm the page returned meaningful content — not a login
  wall, paywall, error page, cookie banner, or empty body. If the fetch returned
  unusable content, inform the user and stop.
- **Relevance check.** Confirm the source covers the same topic as the target
  article. If the subject matter does not overlap, inform the user and stop.
- **Freshness check.** Look for publication or last-updated dates in the source.
  If the source is clearly older than the target article, warn the user — it may
  not be a useful reference.
- **Credibility check.** Consider the source's origin. Flag if the content
  appears auto-generated, speculative, or from an unreliable source so the user
  can decide whether to proceed. Proven findings > official docs > official blog
  \> independent blog articles.

If the content or relevance check fails, explain what you found and stop. For
freshness or credibility concerns, warn the user and ask whether to proceed — do
not stop automatically.

### Step 3: Analyze

Compare the two documents. The reference is a source of *ideas* for what to
cover, not a source of truth.

Identify concepts, practices, details, or sections that are:

- **Missing entirely** from the target article
- **Underrepresented** — mentioned briefly but covered in much more depth in the
  reference
- **Outdated or contradicted** — the reference contains newer or more accurate
  information that conflicts with existing content

Ignore differences that are purely stylistic or organizational. Focus on
substance. Flag separately any content from the reference that falls clearly
outside the established scope of the target article — it will be surfaced in
Step 5 for the user to decide what to do with.

If the article already covers everything in the reference, tell the user and
stop.

### Step 4: Verify proposed changes

For every addition or contradiction identified in Step 3, verify its accuracy
using `WebSearch`. Run all searches in parallel — they are independent of each
other.

For each proposed change, classify the result:

- **Corroborated** — at least one independent source confirms the claim. Proceed
  normally.
- **Unverified** — no independent source found. Mark it as unverified in the
  plan so the user can decide.
- **Contradicted** — independent sources disagree with the claim. Drop the
  proposed change and flag it to the user explaining what you found.

Do not include contradicted claims in the plan. Do not skip verification for any
proposed change.

### Step 5: Present the plan

Before making any edits, present a summary for the user to review. Format as
three sections:

**Additions** — a concise list of corroborated changes:

- What will be added or expanded
- Where in the article each addition fits
- Brief rationale for each (why it matters)

**Unverified** — list any additions that could not be corroborated by
independent sources in Step 4. For each:

- State the claim and its origin in the reference
- Explain that no independent source was found to confirm it
- Ask the user whether to include, skip, or investigate further

**Contradictions** — two kinds of conflicts belong here:

1. Claims from the reference that independent sources contradicted in Step 4
   (these were dropped as additions — explain why so the user is aware).
2. Existing content in the target article that the reference (backed by
   independent sources) shows to be outdated or incorrect.

For each contradiction:

- Quote the conflicting passage (from the article or the reference)
- Explain what independent sources say instead
- For type 1: no action needed, just inform. For type 2: propose whether to
  **remove, rewrite, or skip** the content.

Do not silently overwrite or remove — let the user decide on each contradiction
and unverified item.

If there are no contradictions or unverified items, say so.

**Out of scope** — list any content from the reference that falls outside the
established scope of the target article. For each item:

- Briefly describe what the reference covers that doesn't belong here
- Ask the user whether to: include it anyway, check whether another article
  in the knowledge base is a better home, or provide other guidance

**Source attribution** — if the reference URL is not already linked somewhere in
the article, propose where to add it (e.g., inline, in a "References" section,
or as a footnote) so the user can approve or adjust the placement.

**Wait for user confirmation before editing.**

### Step 6: Apply the changes

Edit the article to incorporate the approved additions. Follow these rules:

- **Do not copy text** from the reference. Rewrite concepts in the article's own
  voice and style.
- **Match the article's voice, not the reference's.** Before writing anything,
  study the target: sentence length, tone, how it introduces terms, how dense or
  spacious the prose is, what formatting patterns it uses. Write additions that
  could have been written by the same author.
- **Only remove content the user explicitly approved for removal** in the
  contradictions review.
- **Keep existing concepts intact.** When inserting new content near existing
  text, do not silently reframe, soften, or dilute correct existing claims.
  Additions sit alongside existing content; they do not revise it unless that
  revision was explicitly approved.
- **Explain new terms inline.** When an addition introduces a concept or term
  the article has not previously used, gloss it briefly at first mention — a
  short parenthetical or a dash-clause is enough. Use the existing article as
  the bar: if it explains comparable terms at that level of depth, match it. Do
  not assume the reader already knows what the reference assumes.
- **Respect the article's structure.** Place new content where it logically
  belongs.
- **Follow writing conventions** from the project's CLAUDE.md (line width, link
  style, markdown flavor, etc.).
- **Keep additions proportional.** A minor gap gets a sentence or two, not a new
  section.
- **Match the link style.** If the article uses reference-style links, add new
  definitions alongside existing ones.
- **Add the source link** in the location the user approved during the plan.

### Step 7: Summarize

After editing, briefly tell the user:

- What was added, removed, or rewritten
- What was skipped (unverified items the user chose not to include, contradicted
  claims from the reference)
- Where the source link was placed (or confirm it was already present)
