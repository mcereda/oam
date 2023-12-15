# OAM best practices

Based on experience.

- Always think critically.
- The _one-size-fits-all_ approach is a big fat lie.<br/>
  This proved particularly valid with regards to templates and pipelines.
- Apply the KISS approach wherever possible, not to keep _all_ things simple but as an invite to keep things simple **with respect of your ultimate goal**.<br/>
  Be aware of simplicity for the sake of simplicity, specially if this makes things complicated on a higher level.
- Keep in mind things change constantly: new technologies are given birth often and processes might improve.<br/>
  Review every decision after some time. Check they are still relevant, or if there is some improvement you can implement.
- Focus on what matters, but also set time aside to check up the rest.<br/>
  Mind the Pareto principle (_80-20 rule_, roughly 80% of consequences come from 20% of causes).
- Automate when and where you can, yet mind [the automation paradox].
- Keep things **de**coupled where possible, the same way _interfaces_ are used in programming.<br/>
  This allows for quick and (as much as possible) painless switch between technologies.
- Choose tools based on **how helpful** they are to achieve your goals.<br/>
  Do **not** adapt your work to specific tools.
- Backup your data.<br/>
  Especially when you are about to update something. [Murphy's law] is lurking.
- [Branch early, branch often].
- [Keep changes short and sweet][the art of small pull requests].<br/>
  Nobody likes to dive deep into a 1200 lines, 356 files pull request ([PR fatigue][how to tackle pull request fatigue], everybody?).
- Make changes easy, avoid making easy changes.
- [Trunk-based development][trunk-based development: a comprehensive guide] and other branching strategies all work but [have different pros and cons][git branching strategies vs. trunk-based development].
- Refactoring _can_ be an option.<br/>
  But do **not** use it mindlessly.
- _DevOps_, _GitOps_ and other similar terms are sets of practices, suggestions, or approaches.<br/>
  They are **not** roles or job titles.<br/>
  They are **not** to be taken literally.<br/>
  They **need** to be adapted to the workplace, not the other way around.
- Be aware of [corporate bullshit][from inboxing to thought showers: how business bullshit took over].
- [Amazon's leadership principles] are double-edge swords and only Amazon can apply them as they are defined.
- Watch out for complex things that should be simple (i.e. the [SAFe] delusion).
- Keep _integration_, _delivery_ and _deployment_ separated.<br/>
  They are different concepts, and as such should require different tasks.<br/>
  This also allows for checkpoints, and to fail fast with less to no unwanted consequence.
- Keep pipelines' tasks as simple, consistent and reproducible as possible.<br/>
  Avoid like the plague to put programs or scripts in pipelines: they should be glue, not applications.
- Pipelines' tasks should be able to execute from one's own computer.
- Pipelines are meant to be used as **last mile** steps for specific goals.<br/>
  There **cannot** be a single pipeline for everything, the same way as _one-size-fits-all_ is a big, fat lie.

## Sources

- [A case against "platform teams"]
- [Culture eats your structure for lunch]
- [DevOps is bullshit]
- [Platform teams need a delightfully different approach, not one that sucks less]
- [We have used too many levels of abstractions and now the future looks bleak]
- [Why the fuck are we templating YAML?]
- [Trunk-based development: a comprehensive guide]
- [Git Branching Strategies vs. Trunk-Based Development]
- [Branch early, branch often]
- [Amazon's leadership principles]
- [Amazon's tenets: supercharging decision-making]
- [How to tackle Pull Request fatigue]
- [The art of small Pull Requests]
- [From inboxing to thought showers: how business bullshit took over]
- [Simple sabotage for software]
- [Hacking your manager - how to get platform engineering on their radar]

<!--
  References
  -->

<!-- Knowledge base -->
[safe]: safe.placeholder
[the automation paradox]: the%20automation%20paradox.placeholder

<!-- Others -->
[a case against "platform teams"]: https://kislayverma.com/organizations/a-case-against-platform-teams/
[amazon's leadership principles]: https://www.amazon.jobs/content/en/our-workplace/leadership-principles
[amazon's tenets: supercharging decision-making]: https://aws.amazon.com/blogs/enterprise-strategy/tenets-supercharging-decision-making/
[branch early, branch often]: https://medium.com/@huydotnet/branch-early-branch-often-daadaad9468e
[culture eats your structure for lunch]: https://thoughtmanagement.org/2013/07/10/culture-eats-your-structure-for-lunch/
[devops is bullshit]: https://blog.massdriver.cloud/posts/devops-is-bullshit/
[from inboxing to thought showers: how business bullshit took over]: https://www.theguardian.com/news/2017/nov/23/from-inboxing-to-thought-showers-how-business-bullshit-took-over
[git branching strategies vs. trunk-based development]: https://launchdarkly.com/blog/git-branching-strategies-vs-trunk-based-development/
[hacking your manager - how to get platform engineering on their radar]: https://www.youtube.com/watch?v=8xprsTXKr0w
[how to tackle pull request fatigue]: https://javascript.plainenglish.io/tackling-pr-fatigue-6865edc205ce
[murphy's law]: https://en.wikipedia.org/wiki/Murphy%27s_law
[platform teams need a delightfully different approach, not one that sucks less]: https://www.chkk.io/blog/platform-teams-different-approach
[simple sabotage for software]: https://erikbern.com/2023/12/13/simple-sabotage-for-software.html
[the art of small pull requests]: https://essenceofcode.com/2019/10/29/the-art-of-small-pull-requests/
[trunk-based development: a comprehensive guide]: https://launchdarkly.com/blog/introduction-to-trunk-based-development/
[we have used too many levels of abstractions and now the future looks bleak]: https://unixsheikh.com/articles/we-have-used-too-many-levels-of-abstractions-and-now-the-future-looks-bleak.html
[why the fuck are we templating yaml?]: https://leebriggs.co.uk/blog/2019/02/07/why-are-we-templating-yaml
