# Machine learning

Branch of [AI] focusing on developing models and algorithms that can learn patterns from data without being explicitly
programmed for every task, and subsequently make accurate inferences about new data.

Models acquire a pattern recognition ability that enables them to make decisions or predictions without explicit,
hard-coded instructions.

1. [TL;DR](#tldr)
1. [Approaches](#approaches)
   1. [Deep learning](#deep-learning)
1. [Architectures](#architectures)
   1. [Mixture of Experts](#mixture-of-experts)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

All machine learning is AI, but not all AI is machine learning.

Rules-based models become increasingly brittle the more data is added to them.<br/>
They require accurate, universal criteria to define the results they need to achieve. This is not scalable.

Data quality matters more than quantity.<br/>
Microsoft proved this with Phi-3, training the model on _textbook-quality_ data (both from the Internet and synthetic)
and getting a 3.8B model that competes with larger models.

ML models operate by a logic that is learned through experience, and **not** _explicitly_ programmed into them.<br/>
They train by analyzing data and predicting the next result; prediction errors are calculated, and the algorithm is
adjusted to reduce the possibility of errors.<br/>
The training process is repeated until the model is accurate _enough_.

ML works through _mathematical_ logic. Relevant characteristics (A.K.A. _features_) of each data point **must** be
expressed numerically, so that the data can be fed into the mathematical algorithm that will _learn_ to map a given
input to the desired output.

While traditional software is _deterministic_, AI is _probabilistic_ (A.K.A. _**non**-deterministic_).<br/>
AI is mostly _context and prompt dependent_, _unpredictable_, and gives _different_ results for the same input.
Reliably testing such results is much harder and requires _broad evaluation_ that is often automated using AI. This
easily becomes a doom loop.

ML is mainly divided into the following types:

- _Supervised_ learning.

  Models learn from _labelled_ data. Every input has a corresponding _correct_ output.<br/>
  Models make predictions, compare those with the true outputs, and adjust themselves to reduce errors and improve
  accuracy over time.<br/>
  The goal is to train to make accurate predictions on new, unseen data.

- _Unsupervised_ learning.

  Models work **without** labelled data.<br/>
  They learn patterns on their own by grouping similar data points or finding hidden structures without human
  intervention.<br/>
  Helps identify hidden patterns in data. Useful for grouping, compression and anomaly detection.<br/>
  Used for tasks like clustering, dimensionality reduction and Association Rule Learning.

- _Reinforcement_ learning.

  Teaches agents to make decisions through trial and error to maximize cumulative rewards.<br/>
  Allows machines to learn by interacting with an environment and receiving feedback based on their actions. This
  feedback comes in the form of rewards or penalties.<br/>
  Agents use the feedback to optimize their decision-making over time.

- _Semi-supervised_ learning.

  Hybrid machine learning approach using both supervised and unsupervised learning.<br/>
  Uses a small amount of labelled data, combined with a large amount of unlabelled data to train models.<br/>
  The goal is to learn a function that accurately predicts outputs based on inputs, like with supervised learning, but
  with much less labelled data.<br/>
  Particularly valuable when acquiring labelled data is expensive or time-consuming, yet unlabelled data is plentiful
  and easy to collect.

- _Self-supervised_ learning.

  Considered by some a subset of unsupervised learning.<br/>
  Models train using data that does not have any labels or answers provided. Instead of needing people to label the
  data, the models themselves find patterns and create their own labels from the data automatically.<br/>
  Especially useful when there is a lot of data, but only a small part of it is labelled or labelling the data would
  take a lot of time and effort.

_Deep learning_ has emerged as the state-of-the-art approach for AI models across nearly every domain.<br/>
It relies on distributed _networks_ of mathematical operations providing the ability to learn intricate nuances of very
complex data.<br/>
It requires very large amounts of data and computational resources.

## Approaches

### Deep learning

Approach in which multiple layers of nodes (a _deep_ neural network) can extract meaning, relationships, and other
complex patterns from large volumes of raw (unstructured and unlabeled) data and make their own predictions about what
the data represents.<br/>
They were initially created with the idea of closely simulating the human brain.

Deep neural networks include:

- An _input_ layer.
- 2 or more _hidden_ layers.
- An _output_ layer.

The multiple layers allow the network to learn increasingly abstract representations of the input data.<br/>
This was key to making **unsupervised** learning practical at scale.

Deep learning encompasses a range of neural network architectures, including multi-layer perceptrons (MLPs),
convolutional neural networks (CNNs), recurrent neural networks (RNNs), graph networks, transformers, autoencoders, and
diffusion models.<br/>
Results are usually applied to domains like computer vision, natural language processing, and robotics.

CNNs were historically the go-to for image and video recognition, including medical imaging, but vision transformers
(ViT) and hybrid architectures have surpassed them in many benchmarks.<br/>
LSTMs and RNNs were dominant for sequence prediction, language translation, and speech recognition before transformers
largely displaced them.<br/>
Generative adversarial networks (GANs) pioneered realistic image generation and AI-driven art. Diffusion models (Stable
Diffusion, DALL-E, Midjourney) have since replaced them.

The models' _attention mechanism_ allows them to assign weights to different parts of the input when producing each part
of the output, rather than treating all input equally.<br/>
It is the key innovation behind transformers, and what gave them advantage over prior architectures.

_Transfer learning_ reuses a model trained on one task as the starting point for a different but related task.<br/>
Instead of training a model from scratch, one takes a pre-trained base model and adapts it to new data.<br/>
This saves them resources and training data while often achieving better results.<br/>
It is the foundation behind [fine-tuning][fine-tuning LMs].

## Architectures

### Mixture of Experts

Divides a single model into multiple, specialized sub-networks (_experts_) along with a learned routing mechanism
(_gate_ or _router_) that dynamically selects which experts to activate for any given input.<br/>
Inference only leverages _a small subset_ of experts at any time. Newer, fine-grained architectures activate more.

It allows to build models with a very large **total** number of parameters, but only activate a fraction of them per
input.<br/>
This makes them more efficient to pre-train and run.

A small router network:

1. Takes the input.
1. Produces a probability distribution over the available experts.
1. Selects the top-k experts.

Training MoE models requires balancing to prevent the router from always routing to the same few experts, and possibly
ensuring experts get roughly equal use instead.<br/>
All expert weights still need to be stored and loaded in memory.

MoE is used across many domains, including vision models, multimodal models, and speech recognition and recommendation
systems.

## Further readings

- [Mixtral of Experts]
- [What is AI Technical Debt? Key Risks for Machine Learning Projects | IBM Technology]

### Sources

- geeksforgeeks.com's [Machine Learning Tutorial][geeksforgeeks / machine learning tutorial]
- IBM's [What is machine learning?][ibm / what is machine learning?]
- Oracle's [What is machine learning?][oracle / what is machine learning?]
- [Machine learning, explained]
- IBM's [What is mixture of experts?][ibm / what is mixture of experts?]
- [Adaptive Mixtures of Local Experts]
- [IBM / What is artificial intelligence (AI)?]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[AI]: README.md
[Fine-tuning LMs]: lms.md#fine-tuning

<!-- Files -->
[Adaptive Mixtures of Local Experts]: study%20material/JacobsJordanNowlanHinton_NeuralComputation_1991.pdf

<!-- Upstream -->
<!-- Others -->
[geeksforgeeks / Machine Learning Tutorial]: https://www.geeksforgeeks.org/machine-learning/
[IBM / What is artificial intelligence (AI)?]: https://www.ibm.com/think/topics/artificial-intelligence
[IBM / What is machine learning?]: https://www.ibm.com/think/topics/machine-learning
[IBM / What is mixture of experts?]: https://www.ibm.com/think/topics/mixture-of-experts
[Machine learning, explained]: https://mitsloan.mit.edu/ideas-made-to-matter/machine-learning-explained
[Mixtral of Experts]: https://arxiv.org/abs/2401.04088
[Oracle / What is machine learning?]: https://www.oracle.com/artificial-intelligence/machine-learning/what-is-machine-learning/
[What is AI Technical Debt? Key Risks for Machine Learning Projects | IBM Technology]: https://www.youtube.com/watch?v=DgXV8QSlI4U
