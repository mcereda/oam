# OAM best practices

Based on experience.

- The _one-size-fits-all_ approach is a big fat lie.<br/>
  This proved particularly valid with regards to templates and pipelines.
- Apply the KISS approach wherever possible, not to keep _all_ things simple but as an invite to keep things simple **with respect of your ultimate goal**.<br/>
  Be aware of simplicity for the sake of simplicity, specially if this makes things complicated on a higher level.
- Keep in mind things change constantly: new technologies are given birth often and processes might improve.<br/>
  Review every decision after some time. Check they are still relevant, or if there is some improvement you can implement.
- Automate when and where you can, yet mind [the automation paradox].
- Keep things **de**coupled where possible, the same way _interfaces_ are used in programming.
  This allows for quick and (as much as possible) painless switch between technologies.
- Always think critically.
- Choose tools based on **how helpful** they are to achieve your goals.<br/>
  Do **not** adapt your work to specific tools.
- Backup your data.
  Especially when you are updating something.
- [Branch early, branch often].
- Keep changes short and sweet.
- Make changes easy, avoid making easy changes.
- [Trunk-based development][trunk-based development: a comprehensive guide] and other branching strategies all work but [have different pros and cons][git branching strategies vs. trunk-based development].
- Refactoring _can_ be an option.<br/>
  But do **not** use it mindlessly.
- _DevOps_, _GitOps_ and other corporate bullshit terms are sets of practices, suggestions, or approaches.<br/>
  They are **not** to be taken literally and **need** to be adapted to the workplace, not the other way around.
- [Amazon's leadership principles] are double-edge swords and only Amazon can apply them as they are defined.
- Watch out for complex things that should be simple (i.e. the [SAFe] delusion).
- Keep pipelines' tasks as simple, consistent and reproducible as possible.<br/>
  Avoid like the plague to put programs or scripts in pipelines: they should be glue, not applications.
- Pipelines' tasks should be able to execute from one's own computer.
- Pipelines are meant to be used as **last mile** steps for specific goals.
  There **cannot** be a single pipeline for everything, the same way as _one-size-fits-all_ is a big, fat lie.
- Keep _integration_, _delivery_ and _deployment_ separated.
  They are different concepts, and as such require different tasks.

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
[git branching strategies vs. trunk-based development]: https://launchdarkly.com/blog/git-branching-strategies-vs-trunk-based-development/
[platform teams need a delightfully different approach, not one that sucks less]: https://www.chkk.io/blog/platform-teams-different-approach
[trunk-based development: a comprehensive guide]: https://launchdarkly.com/blog/introduction-to-trunk-based-development/
[we have used too many levels of abstractions and now the future looks bleak]: https://unixsheikh.com/articles/we-have-used-too-many-levels-of-abstractions-and-now-the-future-looks-bleak.html
[why the fuck are we templating yaml?]: https://leebriggs.co.uk/blog/2019/02/07/why-are-we-templating-yaml
