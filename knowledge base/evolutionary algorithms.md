# Evolutionary algorithms

Family of search algorithms inspired by biological evolution. They promise to solve problems that are easy to score but
difficult to directly engineer.<br/>
They

- Keep a _population_ of candidate solutions.
- Score each individual against a goal.
- Breed the better individuals together while adding random mutations to make a new generation.
- Repeat the process for many generations.

The population drifts naturally toward solutions that score well against the fitness function, even though no human
ever wrote down how to solve the problem directly.

As a concrete example, imagine wanting a small application to find prime numbers efficiently. Instead of writing one
oneself, one can generate 100 random programs, run each on a test suite, keep the better ones, mutate them slightly,
and rinse and repeat. After thousands of rounds, the results will include at least one efficient application for
finding primes, _because_ it survived selection over many generations and not because anyone designed it directly.

1. [TL;DR](#tldr)
1. [Jargon](#jargon)
1. [Genotype vs phenotype](#genotype-vs-phenotype)
1. [Core loop](#core-loop)
1. [Classical families](#classical-families)
1. [Selection pressure](#selection-pressure)
1. [Quality Diversity](#quality-diversity)
   1. [MAP-Elites](#map-elites)
   1. [Variants](#variants)
1. [LLMs as the mutation operator](#llms-as-the-mutation-operator)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

EAs are a good option when the following are available:

- A way to **score** candidate solutions against a well defined goal (the fitness function).
- A way to make **small changes** (_mutations_) to a candidate, and ideally a way to combine features from two or more
  candidates (_crossover_).
- A **batch** of candidates at once (the _population_), instead of just one at a time.

The algorithm iterates by:

1. **Scoring** every candidate (a.k.a _evaluating their fitness_).
1. **Selecting** the ones with a higher score (which _should™_ be the ones most fitting the goal).
1. Making **_variations_** of the selected individuals by introducing small random changes together with possible
   combinations.
1. **Replacing** the old population with the new generation.
1. Repeating the whole process until scores stop improving.

The non-trivial design knobs are _selection pressure_ (how aggressively the process favors the best individual) and
_diversity preservation_ (how aggressively the process keep candidates from all collapsing into a single shape). Most
algorithm choices reduce to tuning these parameters.

EAs are a **poor** fit when the goal is mathematically _well-behaved_ (have a single clear peak and smooth slopes
everywhere, and the thing one measures is the thing one wants). In those cases, using _gradient descent_ (or a direct
solver) is faster and more reliable.<br/>
EAs **shine** when the search space is _rugged_, _multimodal_, _deceptive_, _non-differentiable_, or _noisy_, or when
the score itself is a _suspect proxy_ for what you actually care about.<br/>
See the next section for definitions.

There is **no** general-purpose best algorithm; the algorithm choice has to encode the problem's structure. Following
the _No Free Lunch theorem_ (Wolpert and Macready), averaged over _all possible_ problems, every search algorithm
performs identically.

## Jargon

| Term                  | Summary                                                                                                                                       |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Crossover             | The combination of features from two parent individuals into a child                                                                          |
| Fitness function      | A scalar (or vector) that measures how good a candidate is with respect to the goal                                                           |
| Fitness landscape     | The geometry of the search space (visualize a terrain whose height is the fitness level)                                                      |
| Mutation              | A **random** change to a single candidate                                                                                                     |
| Population            | The set of candidate solutions (a.k.a. _genotypes_)                                                                                           |
| Replacement           | The rule for which individuals survive into the next generation                                                                               |
| Selection             | Sampling, biased toward high fitness                                                                                                          |
| Variation             | Mutation, crossover, or both; anything that produces offspring different from parents                                                         |
| Premature convergence | The population collapses around one peak before exploring others.<br/>The most common failure mode.<br/>Strongly linked to loss of diversity. |
| Deceptive fitness     | The local slope points **away** from the optimum. Greedy methods get stuck.<br/>Canonical motivation for novelty search.                      |
| Darwinian algorithm   | An individual's lifetime experience does **not** propagate to its genotype                                                                    |
| Lamarckian algorithm  | An individual _can_ overwrite its genotype with what local search learned during its lifetime                                                 |

Use an analogy to internalize what the _fitness landscape_ is: imagine a hiker trying to find the highest point of some
terrain. The elevation is the fitness. The definitions below describe what the terrain might look like.

A _smooth_, _unimodal_ landscape is one big mountain. Every direction agrees: walk uphill, one'll get to the top. The
math is well-behaved, the thing you measure is exactly the thing you want. There is no surprise, nor way to get
confused. Gradient descent solves this perfectly; EAs would be wasteful.

A _multimodal_ landscape has several distinct peaks separated by valleys. Local measurements only tell about the peak
is currently nearest to; one cannot tell from where one stands that there's a taller peak across the valley. Mutations
occasionally produce a child far from its parent, which is what gives EAs the chance to discover the farther peak.

A _rugged_ landscape has lots of small bumps everywhere. A simple uphill-walker gets stuck on the **first** bump it
climbs. Maintaining a _population_ of walkers spread out across the terrain is what lets some of them escape local
bumps.

_Gradient descent_ is the simple uphill-walker: asks the ground which way is up, takes a step that way, rinse and
repeat. Cheap and effective on smooth terrain, useless on rugged or discontinuous terrain.

_Deception_ happens when the slope is **actively** misleading: the optimum is in one direction, but the local gradient
points elsewhere. Following the slope takes one farther from the goal. Sometimes, the only way out is to stop optimizing
the score and optimize for _novelty_ instead.

_Non-differentiable_ terrains have cliffs and walls instead of slopes. The math of "which direction is up?" simply
doesn't apply at the edges. EAs don't care: they only ever _compare_ scores, no slopes needed.

_Noisy_ measurements give back a slightly **different** value for the **same** point each time one checks. The terrain
is fine, but one's altimeter is unreliable. Comparing many candidates at once averages out the noise; gradient methods
are dominated by it.

A _suspect proxy_ is a score one can compute but isn't quite what one wants, like measuring elevation when one actually
wants the prettiest view. They correlate, but maximizing the proxy can lead one away from the real goal.
Quality-Diversity methods (see below) hedge against this by keeping a _spread_ of solutions instead of collapsing to
the proxy's peak.

## Genotype vs phenotype

The _genotype_ is what the algorithm directly encodes and mutates: bits, numbers, a tree of operations. The _phenotype_
is what those encodings _produce_ when run, and this is what gets scored.

The mapping between the two is itself a design decision, and is often the most leveraged one in the whole system.

<details>
  <summary>Example</summary>

One can evolve a 100×100-pixel image directly (10,000 numbers per individual), or evolve a 50-line program that _draws_
an image.<br/>
The second approach explores a much larger space of possible images with far fewer parameters, and it tends to find
more structured-looking ones. That's because programs naturally express patterns, while raw pixels don't.

</details>

This is the same insight that makes [FunSearch][Mathematical discoveries from program search with large language models]
work: rather than evolving a hard-to-find mathematical object directly, evolve a small _program that constructs it_.

## Core loop

```text
initialize population
while not done:
    score each individual
    select parents (biased toward higher scores)
    mutate / cross over → offspring
    replace some/all of population
return best
```

In practice:

- `initialize population`: usually random, sometimes seeded with hand-designed candidates to give the search a head
  start or initial nudge.
- `done`: typically "scores stopped improving for N generations" or "ran out of compute budget". Sometimes "found a
  candidate above X fitness threshold".
- `replace`: strategies vary, going from **full** replacement (offspring _are_ the next generation), to **generational**
  replacement with elitism (top K parents always survive untouched), to  **steady-state** (one offspring replaces one
  parent at a time).

## Classical families

Named lineages. They overlap in practice, with modern competition winners typically blending ideas from several of
these.

| Family                        | Origin                                                        | What it evolves         | Distinctive move                                                                                                                                                                                   |
| ----------------------------- | ------------------------------------------------------------- | ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Genetic Algorithm (GA)        | [Holland, 1975][Adaptation in Natural and Artificial Systems] | Bit / character strings | Crossover-driven; the classic "swap two parents' halves" move                                                                                                                                      |
| Genetic Programming (GP)      | Koza, 1992                                                    | Programs (as trees)     | Evolves _executable code_, not values                                                                                                                                                              |
| Evolution Strategies (ES)     | Rechenberg / Schwefel, 1960s                                  | Vectors of real numbers | _Self-adaptive_ mutation step sizes: the magnitude of random perturbations evolves alongside the candidates                                                                                        |
| CMA-ES                        | [Hansen, 1996][Wikipedia / CMA-ES]                            | Vectors of real numbers | Adapts the **covariance matrix** of the mutation distribution to learn which directions in the search space are productive and nudges next variations that way; _quasi-parameter-free_ in practice |
| Differential Evolution (DE)   | Storn / Price, 1997                                           | Vectors of real numbers | Uses _vector-difference mutations_ (adds the scaled difference between two randomly-chosen individuals as the perturbation)                                                                        |
| Evolutionary Programming (EP) | Fogel, 1960s                                                  | Finite-state machines   | Mutation only, no crossover                                                                                                                                                                        |

For modern continuous optimization (real-valued vectors), CMA-ES and DE dominate.<br/>
For discrete or combinatorial problems (graphs, schedules, bit-strings), GA-family methods stay the default.<br/>
GP is alive in symbolic regression (find a formula that fits this data) and program synthesis.

## Selection pressure

Selection pressure is how strong the bias is toward higher fitness when sampling parent individuals. It controls more
of the **exploration-exploitation tradeoff** than the mutation rate does. New practitioners tend to fiddle with the
mutation rate, but the field's consensus is that selection is where the real character of an EA lives.

Strong selection pressure (only the fittest individuals reproduce) makes the population _converge_ fast, but onto
whichever local optimum it found **first**, after which it stops exploring (the _premature convergence_ failure mode).
Weak selection pressure (everyone reproduces with roughly equal probability) preserves diversity, but drifts slowly.
The right balance usually varies over the run: weak early (allowing broader exploration), strong late (tightening
refinement of the best regions found).

The most common selection schemes are the following ones, listed roughly from least to most pressure:

| Scheme                          | What it does                                                                      | Trade-off                                                                                                                                                 |
| ------------------------------- | --------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Linear rank                     | Reproduction probability ∝ (depends on) fitness _rank_, not fitness itself        | Highest diversity, slowest convergence                                                                                                                    |
| Tournament (of size _k_)        | Sample _k_ random candidates; the highest-fitness one wins reproduction           | Pressure ∝ _k_; used as the de-facto default in practice (typically with k=2 or 3)                                                                        |
| Fitness proportional / roulette | Reproduction probability ∝ fitness                                                | High pressure when fitness gaps are extreme; prone to premature convergence; pressure also _decays_ as the population converges (causing late stagnation) |
| (μ,λ) / (μ+λ) (ES)              | Pick the top μ from λ offspring (`,`) or from the μ+λ parent-offspring pool (`+`) | Deterministic and rank-based; _invariant to monotonic transforms_ of the fitness function                                                                 |
| Elitism                         | The top N individuals always survive untouched into the next generation           | Strong exploitation; risks diversity collapse if overused                                                                                                 |

_Monotonic transforms_ are functions that preserve **order**: if `f(a) > f(b)`, then `g(f(a)) > g(f(b))` for any
monotonic `g` (e.g. squaring positive numbers, taking the log). The `(μ,λ)` invariance to such transforms means the
algorithm only depends on the _ranking_ of fitness values, not their absolute magnitudes. Useful when "candidate A is
better than candidate B" is trustworthy, but "A scored 0.83" is not.

The modern default is **adaptive pressure**: low pressure early (allowing broader exploration), ramping up over
generations (tightening refinement). This avoids both the premature convergence of pure-elitism and the slow drift of
pure-rank.

## Quality Diversity

Sometimes the score one computes **actively** misleads the search. The optimum is in some direction, but the local slope
points elsewhere. _Greedy_ algorithms, like gradient descent and strong-pressure EAs, follow the slope and end up far
from the actual optimum. This is also know ans _deceptive fitness_.

[Lehman & Stanley (2008)][Novelty search] proved that, on certain deceptive problems (e.g. maze navigation, where the
score gradient pointed _into_ dead ends), searching for **novelty** alone and ignoring the score entirely actually found
the goal **faster** than actively searching for the score. The score was a worse guide than _just keep doing things you
haven't done before_.

_Quality Diversity_ (QD) generalizes this idea. Instead of finding the **single** best solution, look for a
**collection** of solutions that are both individually high-scoring **and** behaviorally diverse (many different ways
to be good).

### MAP-Elites

[Mouret & Clune, 2015][Illuminating search spaces by mapping elites] introduced what is currently the **canonical** QD
algorithm:

1. Pick _behavioral descriptors_ (axes one wants diversity along).

   For a robot, this might be _walking speed_ × _stability_. For a level generator, _difficulty_ × _length_.

1. Lay out a grid of cells over a descriptor space (e.g. 10×10 = 100 cells).
1. Let each cell hold at most **one** individual (the highest-scoring one whose behavior falls into that cell).
1. Generate offspring by mutating an individual sampled **uniformly at random** from filled cells.
1. For each offspring, compute its descriptors → look up its cell → replace the current occupant if the offspring beats
   it, otherwise discard.

Basing reproduction on **uniform sampling** instead of fitness is the radical move. Selection pressure is on _diversity_
(which cells get filled), not directly on _quality_. Quality shall be enforced per-cell, with cells competing for
**filling**, not for reproduction.

The result is a map of high-quality solutions across the descriptor space, which is often more useful than a single best
both for understanding the problem and for adapting to changing conditions later.

### Variants

- _CMA-MAE_: combines CMA-ES's adaptive Gaussian mutation with the MAP-Elites archive. Fixes three known weak spots
  of vanilla MAP-Elites by stopping abandoning the score too aggressively, handling flat scoring landscapes better, and
  working with low-resolution archives.
- _[Dominated Novelty Search]_ (2025): drops the predefined grid entirely. Descriptor topology **emerges** from local
  competition between candidates.
- _Surprise Search_: measures novelty against **predicted** future behavior, not the past one. Catches genuinely
  surprising candidates rather than just unfamiliar ones.
- _Multi-Objective MAP-Elites_ (MOME): each cell holds a Pareto front (a set of solutions where none dominates another)
  instead of a single individual. Useful when you have multiple competing scores per cell.

## LLMs as the mutation operator

[LLMs] make excellent mutation operators.

Classical EAs use _syntactic_ mutations (flip a bit, swap a subtree, perturb a vector). The change is structurally
local, but semantically arbitrary; one usually needs **many** generations to stumble into something really useful.

LLMs allow for _semantic_ mutations. Handed one a candidate (a prompt, a code snippet, an idea) and asked it to "make it
better", the LLM can propose variations that are far smarter than random ones. This happens because LLMs have priors
about what "better" means in the relevant domain.<br/>
A handful of LLM-driven generations can match thousands of random-mutation generations.

The catch to this approach is that **the LLM's priors _are_ the search bias**. The search drifts toward whatever **the
LLM** finds plausible. LLM-driven EAs inherit the model's aesthetic preferences, which can be a feature (sensible
defaults) or a bug (blind spots in the model become blind spots in the search).

Notable systems:

<details style='padding: 0 0 0 1rem'>
  <summary>PromptBreeder</summary>

[PromptBreeder][Promptbreeder: Self-Referential Self-Improvement Via Prompt Evolution] (DeepMind, Fernando et al. 2023)
evolves prompts. It is _self-referential_, and also evolves the _mutation_ prompts used to mutate the _task_'s
prompts.

It uses various mutation classes (_direct_, _distribution-estimation_, _hyper_, _Lamarckian_, etc.). Its most famous
discovery is a simple `SOLUTION:` prompt reaching 83.9% on GSM8K (a math reasoning benchmark), beating much more
elaborate prompts.

</details>

<details style='padding: 0 0 0 1rem'>
  <summary>EvoPrompt</summary>

[EvoPrompt][EvoPrompt: Connecting LLMs with Evolutionary Algorithms Yields Powerful Prompt Optimizers] (Guo et al. 2023)
wraps classical GA/DE structures around LLMs as crossover and mutation operators.

It got up to 25% improvement on Big-Bench Hard (a hard reasoning benchmark). Uses **fixed** mutation prompts (vs.
PromptBreeder's evolving ones) and starts from a hand-designed initial population.

</details>

<details style='padding: 0 0 0 1rem'>
  <summary>FunSearch</summary>

[FunSearch][Mathematical discoveries from program search with large language models] (DeepMind, Romera-Paredes et al.
2023, _Nature_) evolves **computer programs**, specifically Python functions.

Its architecture uses an LLM as the creative mutator, together with an automated executor as fitness gate (to filter out
hallucinations; the program either runs and gets a score, or it doesn't).<br/>
It discovered genuinely new mathematical constructions on the **cap set problem** in extremal combinatorics.<br/>
It feeds the highest-scoring programs back to the LLM as examples, creates a program **skeleton** with only the
priority-function evolving (everything else is fixed boilerplate), and uses **island-based parallel populations** to
prevent the search from collapsing onto one shape.

</details>

<details style='padding: 0 0 0 1rem'>
  <summary>AlphaEvolve/OpenEvolve</summary>

[AlphaEvolve][AlphaEvolve: A coding agent for scientific and algorithmic discovery] (DeepMind, May 2025) is FunSearch's
successor. It evolves whole codebases instead of single functions.

Uses an ensemble of Gemini models. It managed to:

- Beat Strassen's 56-year-old record for 4×4 complex matrix multiplication (49 → 48 scalar multiplications).
- Find a heuristic that Borg (Google's cluster scheduler) uses in production, recovering 0.7% of Google's compute
  continuously.
- Reduce by 1% Gemini's training time via a discovered matmul kernel.
- Solve 50+ open math problems in analysis, combinatorics, and number theory.

The LLM rewrite _is_ the mutation operator.

[OpenEvolve][OpenEvolve: An Open Source Implementation of Google DeepMind's AlphaEvolve] is available as the open-source
implementation of AlphaEvolve.

</details>

## Further readings

- [Quality Diversity from Novelty Search to MAP-Elites]
- [Large Language Models][llms]
- [Using evolutionary algorithms with LLMs]

### Sources

- Wikipedia: [1][Wikipedia / Evolutionary algorithm], [2][Wikipedia / CMA-ES], [3][Wikipedia / Evolution strategy]
- [Evolutionary Algorithms for Parameter Optimization - Thirty Years Later]
- [Trade-off between exploration and exploitation with genetic algorithm using a novel selection operator]
- [Resolving the Exploitation-Exploration Dilemma in Evolutionary Algorithms]
- [Quality Diversity: A New Frontier for Evolutionary Computation]
- [Illuminating search spaces by mapping elites]
- [Mathematical discoveries from program search with large language models]
- [Promptbreeder: Self-Referential Self-Improvement Via Prompt Evolution]
- [EvoPrompt: Connecting LLMs with Evolutionary Algorithms Yields Powerful Prompt Optimizers]
- [AlphaEvolve: A coding agent for scientific and algorithmic discovery]

<!-- Knowledge base -->
[LLMs]: ai/lms.md#large-language-models
[Using evolutionary algorithms with LLMs]: ai/using%20evolutionary%20algorithms%20with%20llms.md

<!-- Files -->
<!-- Upstream -->
[Wikipedia / CMA-ES]: https://en.wikipedia.org/wiki/CMA-ES
[Wikipedia / Evolution strategy]: https://en.wikipedia.org/wiki/Evolution_strategy
[Wikipedia / Evolutionary algorithm]: https://en.wikipedia.org/wiki/Evolutionary_algorithm

<!-- Others -->
[Adaptation in Natural and Artificial Systems]: https://mitpress.mit.edu/9780262581110/adaptation-in-natural-and-artificial-systems/
[AlphaEvolve: A coding agent for scientific and algorithmic discovery]: https://arxiv.org/abs/2506.13131
[Dominated Novelty Search]: https://arxiv.org/abs/2502.00593
[Evolutionary Algorithms for Parameter Optimization - Thirty Years Later]: https://direct.mit.edu/evco/article/31/2/81/115462/Evolutionary-Algorithms-for-Parameter-Optimization
[EvoPrompt: Connecting LLMs with Evolutionary Algorithms Yields Powerful Prompt Optimizers]: https://arxiv.org/abs/2309.08532
[Illuminating search spaces by mapping elites]: https://arxiv.org/abs/1504.04909
[Mathematical discoveries from program search with large language models]: https://www.nature.com/articles/s41586-023-06924-6
[Novelty search]: https://www.cs.ucf.edu/~kstanley/lehman_alife08.pdf
[OpenEvolve: An Open Source Implementation of Google DeepMind's AlphaEvolve]: https://huggingface.co/blog/codelion/openevolve
[Promptbreeder: Self-Referential Self-Improvement Via Prompt Evolution]: https://arxiv.org/abs/2309.16797
[Quality Diversity from Novelty Search to MAP-Elites]: https://rl-vs.github.io/rlvs2021/class-material/evolutionary/light-virtual_school_qd.pdf
[Quality Diversity: A New Frontier for Evolutionary Computation]: https://www.frontiersin.org/journals/robotics-and-ai/articles/10.3389/frobt.2016.00040/full
[Resolving the Exploitation-Exploration Dilemma in Evolutionary Algorithms]: https://arxiv.org/abs/2501.02153
[Trade-off between exploration and exploitation with genetic algorithm using a novel selection operator]: https://link.springer.com/article/10.1007/s40747-019-0102-7
