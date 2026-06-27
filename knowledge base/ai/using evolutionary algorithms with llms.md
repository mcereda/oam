# Using evolutionary algorithms with LLMs

[Evolutionary algorithms] are being applied to modern AI systems, particularly to [large language models][LLMs].<br/>
See [evolutionary algorithms] for the foundational concepts (the core loop, classical families, selection pressure,
quality diversity).

1. [TL;DR](#tldr)
1. [Evolution strategies at scale](#evolution-strategies-at-scale)
1. [LLM x EA: the operator inversion](#llm-x-ea-the-operator-inversion)
1. [Transferable strategy patterns](#transferable-strategy-patterns)
   1. [Using LoRA to score fitness](#using-lora-to-score-fitness)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

These concepts are especially load-bearing here:

- _Deceptive fitness_ is when the score's gradient points _away_ from the optimum, which makes score-driven search
  **actively** harmful. This is the canonical motivation for
  [novelty search][evolutionary algorithms / Quality Diversity].
- Evolving a program that _builds_ a solution (genotype) vs. _evolving_ the solution (phenotype) directly is the insight
  provided by [FunSearch][Mathematical discoveries from program search with large language models].

## Evolution strategies at scale

Researchers are trying to scale [evolution strategies][evolutionary algorithms] to LLMs with billions of
parameters.<br/>
Each generation requires scoring many candidate perturbations, and doing that to a billion-parameter model even once is
expensive.

[Salimans et al. (OpenAI, 2017)][Evolution Strategies as a Scalable Alternative to Reinforcement Learning] made the
first compelling case that evolution strategies could compete with deep reinforcement learning on standard benchmarks.
ES were able to massively parallelize, scaling to 1,000+ workers avoiding bandwidth bottleneck and offering results with
properties that RL can't easily match (invariance to action frequency, tolerance of long horizons and delayed rewards,
no need for value-function approximation or temporal discounting).

<details style='padding: 0 0 1rem 1rem'>

The research solved 3D humanoid walking in 10 minutes, and obtained competitive results on most Atari games after 1
hour of training.

Workers transmitted scalar fitness scores alongside shared random seeds to each other over the network instead of full
gradients (which would be prohibitively expensive). Each worker knows the seed, which allows them to reconstruct what
perturbation its neighbors tried and achieve the kind of coordination that required gradients at scalar cost.

</details>

[Qiu et al. (ES at Scale, 2025)][Evolution Strategies at Scale: LLM Fine-Tuning Beyond Reinforcement Learning] took that
one step forward by applying ES to full-parameter fine-tuning of billion-parameter LLMs **without** using
dimensionality-reduction shortcuts. Reported results claimed to outperform RL on long-horizon and delayed-reward tasks,
with reduced reward-hacking and better stability.

[Sarkar et al. (EGGROLL, 2025)][Evolution Strategies at the Hyperscale] addressed the remaining efficiency gap with
_Evolution Guided GeneRal Optimisation via Low-rank Learning_. EGGROLL structures each perturbation as a [LoRA] matrix
of rank _r_ instead of naively apply ES on billion-parameter models and fully processing perturbations as dense
matrices, turning it into a form GPUs are already optimized for.

<details style='padding: 0 0 1rem 1rem'>

The process leverages _arithmetic intensity_: a rank _r_ perturbation uses far fewer multiply-accumulate operations
than a dense one. Modern accelerators are built around compact, structured operations. It results in ~100× training
speedup for billion-parameter models, up to 91% of pure batch-inference throughput. This competes with GRPO (a popular
RL method for LLMs) on post-training reasoning tasks.

</details>

## LLM x EA: the operator inversion

LLMs make excellent mutation operators. Given a candidate (prompt, code, idea) and using "make this better" as the
task's prompt, an LLM can propose semantically meaningful variations.<br/>
This result is far smarter than using random perturbation, because the LLM encodes priors about what "better" might
mean.

The [evolutionary algorithms article][evolutionary algorithms / LLMs] covers the systems in detail. These are the
structural patterns they introduced:

- [PromptBreeder] evolves prompts, **including** the very same mutation prompts that mutate the task prompts
  (_self-referential_).
- [EvoPrompt] wraps classical GA/DE structures around LLMs as crossover/mutation operators.<br/>
  Uses _fixed_ mutation prompts (in contrast with PromptBreeder).
- [FunSearch][Mathematical discoveries from program search with large language models] evolves Python functions.
  An automated executor gates fitness (hallucinations get filtered).

  Its structural keys are best-shot prompting, program _skeletons_ with only the priority-function evolving, and
  **island-based parallel populations**.
- [AlphaEvolve][AlphaEvolve: A coding agent for scientific and algorithmic discovery] (FunSearch's successor) evolves
  whole codebases using an ensemble of a fast, cheap model for high-throughput generation and a slow, stronger model for
  occasional high-quality leaps.

The LLM's priors _are_ the search bias. The search gravitates toward whatever the model finds plausible. LLM-driven EAs
inherit the model's aesthetic preferences.

## Transferable strategy patterns

Evolutionary algorithms' application can be used for more than just fine-tuning model weights. Prompt systems, agent
pipelines, and memory management greatly benefit from borrowing _shapes_ from algorithms instead of naively running
gradient-free optimization over parameters.

Some patterns that travel well are the following:

- Using [MAP-Elites][evolutionary algorithms / MAP-Elites] for pruning recurrent concepts (e.g., memories).

  When pruning by score, and the score itself is suspect (e.g., "did this idea recur?") recurrence may favor whatever
  the model **already** believes (its existing biases).<br/>
  Instead of ranking by score alone, using  by picking _descriptor axes_ one wants diversity along (say, _register_ ×
  _topic shape_ × _valence_), partitioning the space into cells, and keeping the highest-quality item _per cell_ offers
  a structural alternative that catches rare-but-valuable entries that pure score-based pruning silently kills.

- Search for [novelty][evolutionary algorithms / Quality Diversity] instead of selecting by score.

  When the fitness landscape is _deceptive_ (the score pulls search toward a dead end), replace scoring with _novelty
  distance_ to the existing archive. It gives better results than score-driven search on those landscapes where the
  shortest path to high score diverges from the path to anything genuinely new.<br/>
  It can be useful as a temporary seeding strategy, even if planning to reintroduce scoring later.

- Use **self-referential** mutations
  ([PromptBreeder][PromptBreeder]'s pattern).

  [PromptBreeder] evolves the prompts that evolve the prompts, making the mutation operators themselves subject to
  evolution alongside the population. The payoff is that one can stop hand-tuning the meta-level indefinitely, because
  the system now discovers its own effective mutation operators.

- Run several **parallel** populations (_island_), and make **rare** migration of individuals between them.

  Without islands, globally-connected populations tend to collapse onto a single solution shape as selection pressure
  rises. Islands preserve parallel different hypotheses. Occasionally migrating individuals between each of them injects
  a winning variant from one population into another, **without** disrupting the rest.<br/>
  Both [FunSearch][Mathematical discoveries from program search with large language models] and
  [AlphaEvolve][AlphaEvolve: A coding agent for scientific and algorithmic discovery] credit this method essential for
  finding diverse high-quality solutions.

- Use LLMs in multiple tiers.

  This is the pattern used by [AlphaEvolve][AlphaEvolve: A coding agent for scientific and algorithmic discovery].<br/>
  Use a fast, cheap model to handle high-throughput candidate generation, and a slow, stronger model to make occasional
  high-quality leaps. The cheaper tiers handle the inner evolutionary loops, the stronger tiers evaluate or mutate the
  most promising candidates.

- Evolve a skeleton.

  This is [FunSearch][Mathematical discoveries from program search with large language models]'s pattern.<br/>
  Rather than evolving whole artifacts, fix their _skeletons_ (the template, header, or schema) and evolve only their
  leaf details. This lowers the search dimension and raises the signal-to-noise ratio. The skeleton anchors the form
  while the leaves carry all the variation.

- Anneal selection pressure.

  Use _low_ selection pressure (= high diversity) early and apply _high_ pressure (= exploit the best) later in the
  process when premature convergence is a bigger risk than wasted exploration. By applying strong pressure too early,
  the population collapses before it has sampled enough of the landscape. Gradually increasing pressure lets the search
  explore broadly, and only then refine.

### Using LoRA to score fitness

_LoRA_ (Low-Rank Adaptation) adapters are small parameter matrices that steer a frozen base model's behavior. They rest
on the order of 1 to 100M parameters instead of the full-model billions.

Multi-tenant inference frameworks like [vLLM][vllm] and [SGLang][sglang] can keep many adapters in memory, and batch
inference across them. That infrastructure opens two complementary moves for evolutionary systems:

- **LoRA as the candidate**: evolve LoRA deltas as the _individual_ being selected.

  The search space is dramatically smaller than full-model weights, EGGROLL's low-rank perturbation insight applies
  natively (the candidate space _is_ already low-rank), and multi-tenant serving makes scoring many candidates cheap.

- **LoRA as the fitness scorer**: train a small LoRA judge on `(candidate, score)` pairs and use it as a cheap learned
  proxy for whatever the expensive ground-truth evaluation would be (benchmarks, a strong model, human ratings).

Inner loops use the judge (fast, cheap, many candidates per generation); outer loops use ground truth to recalibrate
the judge when the two disagree:

```text
ground-truth-fitness(candidate) → expensive but trustworthy
LoRA-judge(candidate)           → cheap proxy, retrain on disagreements
```

This leverages the _surrogate-assisted optimization_ pattern from classical EA literature, and ports it to LLM fitness
signals: the surrogate amortizes the cost of the expensive fitness function across many candidates. The critical
discipline is the recalibration step. Without it, the inner loop will exploit whatever blind spots the judge has.

Watch out for **reward hacking**: the judge is itself a model with failure modes, and evolution is very good at finding
shortcuts to achieve defined results by cheating.

## Further readings

### Sources

- [Evolution Strategies as a Scalable Alternative to Reinforcement Learning]
- [Evolution Strategies at Scale: LLM Fine-Tuning Beyond Reinforcement Learning]
- [Evolution Strategies at the Hyperscale]
- [PromptBreeder]
- [EvoPrompt]
- [FunSearch][Mathematical discoveries from program search with large language models]
- [AlphaEvolve][AlphaEvolve: A coding agent for scientific and algorithmic discovery]

<!-- Reference-style links -->

<!-- Knowledge base -->
[evolutionary algorithms / LLMs]: ../evolutionary%20algorithms.md#llms-as-the-mutation-operator
[evolutionary algorithms / MAP-Elites]: ../evolutionary%20algorithms.md#map-elites
[evolutionary algorithms / Quality Diversity]: ../evolutionary%20algorithms.md#quality-diversity
[evolutionary algorithms]: ../evolutionary%20algorithms.md
[llms]: lms.md#large-language-models
[LoRA]: lms.md#compression

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[AlphaEvolve: A coding agent for scientific and algorithmic discovery]: https://arxiv.org/abs/2506.13131
[EvoPrompt]: https://arxiv.org/abs/2309.08532
[Evolution Strategies as a Scalable Alternative to Reinforcement Learning]: https://arxiv.org/abs/1703.03864
[Evolution Strategies at Scale: LLM Fine-Tuning Beyond Reinforcement Learning]: https://arxiv.org/abs/2509.24372
[Evolution Strategies at the Hyperscale]: https://arxiv.org/abs/2511.16652
[Mathematical discoveries from program search with large language models]: https://www.nature.com/articles/s41586-023-06924-6
[PromptBreeder]: https://arxiv.org/abs/2309.16797
[sglang]: https://github.com/sgl-project/sglang
[vllm]: https://github.com/vllm-project/vllm
