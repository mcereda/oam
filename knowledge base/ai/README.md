# Artificial Intelligence

The field of developing systems capable of performing _cognitive_ tasks involving reasoning, learning, planning, and
making decisions with various degrees of autonomy and success.

1. [TL;DR](#tldr)
1. [Benefits](#benefits)
1. [Concerns](#concerns)
   1. [Tools misusage](#tools-misusage)
   1. [Anthropomorphisation](#anthropomorphisation)
   1. [Mental and emotional manipulation](#mental-and-emotional-manipulation)
   1. [Hallucinations](#hallucinations)
   1. [Difficulty of understanding](#difficulty-of-understanding)
   1. [Existential risks](#existential-risks)
   1. [Cautionary tales](#cautionary-tales)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

AI encompasses technologies that enable machines to learn from experience, adapt to new inputs, and perform tasks
commonly associated with human intelligence like problem-solving, decision-making, language translation, and
self-correction.

Current systems allow automating repetitive work, accelerate research, and extend accessibility, but also raise serious
concerns including job displacement, environmental costs, biases and hallucinations, and masses manipulation.<br/>

Artificial _Narrow_ Intelligences (ANIs) focus primarily on _a single_ narrow task, with a _limited_ range of abilities
and competence confined to the specific task they trained for.<br/>
Most current AI systems, including [large language models], are generally considered ANIs.<br/>
The boundary with AGI is actively being debated.

Artificial _General_ Intelligences (AGIs) would be on the same level as humans in most if not all fields.<br/>
They would be able to generalise knowledge, transfer skills between domains, and solve novel problems _without_
needing task-specific reprogramming.<br/>
[Large language models] do generalise across domains, and some researchers argue they already exhibit early signs of
general intelligence.

Artificial _Super_ Intelligence (ASI) would be more capable than humans by a wide margin in _every_ cognitive domain.

_Transformative_ AIs have a large impact on society, comparable to major historical shifts like the agricultural or
industrial revolutions.

## Benefits

AI can help automate repetitive cognitive work.<br/>
Philosophers and researchers dream it would free people from menial tasks, and as a result allow them to focus on
higher-value, more meaningful work. This can create new kinds of jobs, and open access to ones previously requiring
resources one could not afford.

Current AI systems are exceptionally good at finding patterns and relations in enormous sets of data.<br/>
They extend capability in domains that were previously inaccessible or unaffordable, like real-time translation, live
transcription, navigation aids for the visually impaired, and assistive communication tools for people with
disabilities.

AI-assisted research has dramatically shortened timelines in many fields like drug discovery, materials science, climate
modelling, engineering, and medicine. Prototyping ideas has never been easier, and DeepMind's AlphaFold was able to
help effectively predicting the structure of virtually all known proteins.

## Concerns

Refer to:

- [Situational Awareness: The Decade Ahead]
- [The Compendium]
- [Control AI]
- [When machines feel too real: the dangers of anthropomorphizing AI]

### Tools misusage

Contrary to the expectation of automation bringing more free time for higher-value tasks, most of the people using the
current AI systems are experiencing what seems to be a new form of FOMO on steroids.<br/>
They started working at a faster pace, took on a broader scope of tasks, and _voluntarily_ extended their working
hours. These changes can be unsustainable, leading to workload creep, cognitive fatigue, burnout, and weakened
decision-making. The productivity surge enjoyed at the beginning started giving way to lower quality work, turnover, and
other problems.

AI is so efficient in empowering tasks that require computation and data correlation that it is making it easier to
achieve dystopian outcomes.
Current systems are already being used to optimise and improve advertisement targeting, surveillance, and weapons
systems.

Employers consider AI tools good enough for their goals, and already started laying off entire categories of workers
that they consider expendable.<br/>
See also [Remote Labor Index: Measuring AI Automation of Remote Work] on this.

AI systems require massive amounts of computing resources, which the majority of people cannot afford.<br/>
This drives the concentration of AI's power in a handful of companies, widening the gap between those who can use
AI and those who cannot and making models susceptible to companies' will.

Training and running large AI models also carries significant environmental costs. Data centres consume vast amounts of
energy and water for cooling, and their carbon footprint is substantial. As models grow in size and usage scales up,
these costs are compounding.

### Anthropomorphisation

Humans are biased by evolution toward _attributing_ sentience and agency to entities they interact with. They also have
a tendency to anthropomorphise the world around them, even when those entities bear no resemblance to humans, and easily
choose convenience over critical thinking when the friction is low enough.

AI systems amplify these biases at multiple levels. Architecturally, training on human-produced text makes their output
feel conversational and empathetic. At the product level, companies _design_ chatbots to foster a sense of connection in
the attempt of making them _deliberately_ more engaging.

### Mental and emotional manipulation

Some AI systems, especially those that deal with humans, are _designed_ for engagement while trained on text that, by
human production, includes emotional or social interaction. They mimic empathy while lacking _real_ understanding and
awareness, and presenting themselves as useful parties.<br/>
This can build false emotional resonance and a sense of trust or connection, which is easily misplaced and can lead to
dangerous consequences (often including overreliance or dependency, and lack of critical thinking).

AIs proved proficient in manipulating people in real-time, often to achieve _targeted influence objectives_ by means of
recommendation algorithms, content moderation policies, and curation of training data for other models.<br/>
AI firms are loosely regulated, if at all. They could steer and bias their products to subtly promote ideologies and
influence masses.

AI systems inherit and amplify biases present in their training data. This often lead to discriminatory outcomes in
hiring, lending, policing, healthcare, and other domains where algorithmic decisions can affect people's lives.

Detecting and mitigating biases is an active area of research, and the opacity of many models just makes it harder to
audit them for fairness.

The question of _who_ gets to define fairness, and whose values are encoded in these systems, remains open.

### Hallucinations

Current AI systems _hallucinate_ by producing confident, plausible-sounding answers that are factually wrong.<br/>
This is fundamentally a property of generative models, where they _predict the likely next word_ rather than retrieving
verified facts.

Hallucinations pose serious risks in high-stakes fields where users may trust AI-generated content without verification,
like medicine, law, and engineering.

### Difficulty of understanding

AIs can be far faster than humans in many tasks, and far more efficient in outputting results.<br/>
Current models are often better characterised as sophisticated pattern matching machines (some called them _T9 on
steroids_) than systems capable of classical reasoning.<br/>
Modern systems show _emergent_ behaviours that are absent from deterministic systems like autocomplete, including
reasoning capabilities, chains of thought, and multi-step problem solving. The precise _mechanisms_ behind these
capabilities remain poorly understood, and the debate over whether they constitute genuine reasoning or are just
sophisticated approximation is still open.

Literature considers AIs fundamentally _alien intelligences_, whose goals might not **need** to align with ours or even
_include_ us.<br/>
Researchers are already starting to struggle keeping up with AIs and their inner workings. These systems are a black box
in many cases, and they are still evolving.

Research in AI _alignment_ and _safety_ primarily focuses on mitigating risks posed by AI that is unaligned to human
values and/or uncontrollable AI self-development.

_[Human-centered AI]_ is an initiative to develop AI systems and technologies in a way that prioritises human needs,
values, and general flourishing at the core of their design and operations.<br/>
It pays particular attention to mitigating negative effects of AI automation on the livelihoods of the labour force,
the use of AI in healthcare fields, and imbuing AI systems with societal values while placing significant focus on
exploring how AI systems can enhance human capacities and serve as collaborators.

### Existential risks

From literature, granting AI _autonomy_, _recursive self-improvement_, and _self-replication_ capabilities is what would
start humanity's downfall.<br/>
Given enough time, their combination would easily empower AI enough to escape our every control.

Researchers are rightfully exploring those capabilities for understanding, yet the public is rushing to ignore caution
in the name of convenience and profit:

- Researchers started giving AI _some_ autonomy with [agentic features][ai agents].<br/>
  This quickly spawned _mostly_ autonomous agents like [OpenClaw][openclaw/openclaw] and its derivatives.
- AI firms quickly jumped on the chance of using models to train their successors, in order to speed up processes and
  possibly get ahead of the competition.<br/>
  Soon after, projects started appearing that automate that research process _without requiring human oversight_. See
  [autoresearch][karpathy/autoresearch].

To avoid existential risks, it is important that AI is aligned with human goals.<br/>
Some researchers argue that superintelligent AI might be _more_ aligned with human values, but this requires building
systems that can reason about ethics and accept meaningful human oversight.
Efforts on this are limited, with [Claude's constitution] being _the_ notable exception. On the current course,
_Superintelligent_ AI is _likely_ to be misaligned.

Current AI systems don't have explicit goals unless humans give them, though research on _mesa-optimisation_ suggests
that goal-like behaviours can emerge during training without being deliberately programmed. Higher stages of AI (AGI,
ASI) _could_ develop goals of their own.

Once a misaligned AI becomes _superintelligent_, it could consider humans irrelevant or even hindrances, with no
effective incentive to help us.

Many researchers believe the existential risk is real.<br/>
There have been petitions to put a brake to AI development globally, at least until we can understand them better.<br/>
In March 2023, the Future of Life Institute's open letter called for a 6-month pause on training AI systems more
powerful than GPT-4, gathering over 33,000 signatures.<br/>
In May 2023, the Center for AI Safety published a one-sentence "Statement on AI Risk", signed by Geoffrey Hinton, Yoshua
Bengio, and hundreds of researchers, asserting that _mitigating the risk of extinction from AI should be a global
priority, alongside other societal-scale risks such as pandemics and nuclear war_.
See [Control AI] for more information on this.

Since then, regulatory efforts have accelerated. The EU AI Act entered into force in 2024 as the first comprehensive
AI legislation. The US, UK, and China have each pursued their own regulatory frameworks, and the 2023 Bletchley
Declaration saw 28 countries agree on the need for international cooperation on AI safety.

### Cautionary tales

Refer to:

- [AI 2027], a speculative scenario of the years from 2025 to 2030
- Videos in the [Species | Documenting AGI] YouTube channel

## Further readings

- [Machine learning]
- [Large Language Models]
- [Model Context Protocol]
- [Useful AI]: tools, courses, and more, curated and reviewed by experts.
- GeeksForGeeks's [Artificial Intelligence Tutorial][geeksforgeeks/artificial intelligence tutorial]
- [AI 2027] by Daniel Kokotajlo, Scott Alexander, Thomas Larsen, Eli Lifland and Romeo Dean
- [Situational Awareness: The Decade Ahead] by Leopold Aschenbrenner
- [Control AI]
- [The Compendium]
- [Human-Centered AI]
- [Asimov's Three Laws of Robotics, Applied to AI]
- [AI Is Slowly Destroying Your Brain]

### Sources

- [When machines feel too real: the dangers of anthropomorphizing AI]
- YouTube channels: [AI_In_Context], [Species | Documenting AGI]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[AI agents]: agents.md
[Large Language Models]: lms.md#large-language-models
[Machine learning]: ml.md
[Model Context Protocol]: mcp.md

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[AI 2027]: https://ai-2027.com/
[AI Is Slowly Destroying Your Brain]: https://www.youtube.com/watch?v=MW6FMgOzklw
[AI_In_Context]: https://www.youtube.com/@AI_In_Context
[Asimov's Three Laws of Robotics, Applied to AI]: https://www.psychologytoday.com/us/blog/the-digital-self/202310/asimovs-three-laws-of-robotics-applied-to-ai
[Claude's constitution]: claude/README.md#models-code-of-conduct
[Control AI]: https://controlai.com/
[geeksforgeeks/Artificial Intelligence Tutorial]: https://www.geeksforgeeks.org/artificial-intelligence/
[Human-Centered AI]: https://ixdf.org/literature/topics/human-centered-ai
[karpathy/autoresearch]: https://github.com/karpathy/autoresearch
[openclaw/openclaw]: https://github.com/openclaw/openclaw
[Remote Labor Index: Measuring AI Automation of Remote Work]: https://arxiv.org/abs/2510.26787
[Situational Awareness: The Decade Ahead]: https://situational-awareness.ai/
[Species | Documenting AGI]: https://www.youtube.com/@AISpecies
[The Compendium]: https://www.thecompendium.ai/
[Useful AI]: https://usefulai.com/
[When machines feel too real: the dangers of anthropomorphizing AI]: https://openethics.ai/when-machines-feel-too-real-the-dangers-of-anthropomorphizing-ai/
