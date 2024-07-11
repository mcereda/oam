# mermaid.js

JavaScript based diagramming and charting tool.<br/>
Renders Markdown-inspired text definitions to create and modify diagrams dynamically.

1. [Live editor](#live-editor)
1. [Diagrams](#diagrams)
   1. [Flowchart (a.k.a. graph)](#flowchart-aka-graph)
   1. [Commit flow](#commit-flow)
1. [Further readings](#further-readings)

## Live editor

Mermaid.js offers a [live editor] to check the graph code.

## Diagrams

### Flowchart (a.k.a. graph)

```md
:::mermaid
graph TB
  sq[Square shape] --> ci((Circle shape))

  subgraph A
      od>Odd shape]-- Two line<br/>edge comment --> ro
      di{Diamond with <br/> line break} -.-> ro(Rounded<br>square<br>shape)
      di==>ro2(Rounded square shape)
  end

  %% Notice that no text in shape are added here instead that is appended further down
  e --> od3>Really long text with linebreak<br>in an Odd shape]

  %% Comments after double percent signs
  e((Inner / circle<br>and some odd <br>special characters)) --> f(,.?!+-*ز)

  cyr[Cyrillic]-->cyr2((Circle shape Начало));

  classDef green fill:#9f6,stroke:#333,stroke-width:2px;
  classDef orange fill:#f96,stroke:#333,stroke-width:4px;
  class sq,e green
  class di orange
:::
```

:::mermaid
graph TB
  sq[Square shape] --> ci((Circle shape))

  subgraph A
      od>Odd shape]-- Two line<br/>edge comment --> ro
      di{Diamond with <br/> line break} -.-> ro(Rounded<br>square<br>shape)
      di==>ro2(Rounded square shape)
  end

  %% Notice that no text in shape are added here instead that is appended further down
  e --> od3>Really long text with linebreak<br>in an Odd shape]

  %% Comments after double percent signs
  e((Inner / circle<br>and some odd <br>special characters)) --> f(,.?!+-*ز)

  cyr[Cyrillic]-->cyr2((Circle shape Начало));

  classDef green fill:#9f6,stroke:#333,stroke-width:2px;
  classDef orange fill:#f96,stroke:#333,stroke-width:4px;
  class sq,e green
  class di orange
:::

### Commit flow

```md
:::mermaid
gitGraph:
  commit
  branch develop
  checkout develop
  commit id:"customId"
  commit tag:"customTag"
  checkout main
  commit type: HIGHLIGHT
  commit
  merge develop
  commit
  branch test
  commit
:::
```

:::mermaid
gitGraph:
  commit
  branch develop
  checkout develop
  commit id:"customId"
  commit tag:"customTag"
  checkout main
  commit type: HIGHLIGHT
  commit
  merge develop
  commit
  branch test
  commit
:::

## Further readings

- Official [documentation]
- [Markdown]
- [mermaid-cli]
- [Examples]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[documentation]: https://mermaid.js.org/intro/
[examples]: https://mermaid.js.org/syntax/examples.html
[live editor]: https://mermaid.live

<!-- Knowledge base -->
[markdown]: markdown.md
[mermaid-cli]: mermaid-cli.md
