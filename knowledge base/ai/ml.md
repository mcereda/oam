# Machine learning

Branch of [AI] focusing on developing models and algorithms that can learn patterns from data without being explicitly
programmed for every task, and subsequently make accurate inferences about new data.

It is a pattern recognition ability that enables models to make decisions or predictions without explicit, hard-coded
instructions.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

All machine learning is AI, but not all AI is machine learning.

Rules-based models become increasingly brittle the more data is added to them.<br/>
They require accurate, universal criteria to define the results they need to achieve. This is not scalable.

ML models operate by a logic that is learned through experience, and not explicitly programmed into them.<br/>
They train by analyzing data and predicting the next result; prediction errors are calculated, and the algorithm is
adjusted to reduce the possibility of errors.<br/>
The training process is repeated until the model is accurate.

ML works through mathematical logic. Relevant characteristics (A.K.A. _features_) of each data point **must** be
expressed numerically, so that the data can be fed into the mathematical algorithm that will _learn_ to map a given
input to the desired output.

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

  Subset of unsupervised learning.<br/>
  Models train using data that does not have any labels or answers provided. Instead of needing people to label the
  data, the models themselves find patterns and create their own labels from the data automatically.<br/>
  Especially useful when there is a lot of data, but only a small part of it is labelled or labelling the data would
  take a lot of time and effort.

_Deep learning_ has emerged as the state-of-the-art AI model architecture across nearly every domain.<br/>
It relies on distributed _networks_ of mathematical operations providing the ability to learn intricate nuances of very
complex data.<br/>
It requires very large amounts of data and computational resources.

## Further readings

### Sources

- geeksforgeeks.com's [Machine Learning Tutorial][geeksforgeeks / machine learning tutorial]
- IBM's [What is machine learning?][ibm / what is machine learning?]
- Oracle's [What is machine learning?][oracle / what is machine learning?]
- [Machine learning, explained]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[AI]: README.md

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[geeksforgeeks / Machine Learning Tutorial]: https://www.geeksforgeeks.org/machine-learning/
[IBM / What is machine learning?]: https://www.ibm.com/think/topics/machine-learning
[Oracle / What is machine learning?]: https://www.oracle.com/artificial-intelligence/machine-learning/what-is-machine-learning/
[Machine learning, explained]: https://mitsloan.mit.edu/ideas-made-to-matter/machine-learning-explained
