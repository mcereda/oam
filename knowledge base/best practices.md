# OAM best practices

What really worked for me.

1. [Generic concepts](#generic-concepts)
1. [Teamwork](#teamwork)
1. [CI/CD specific](#cicd-specific)
   1. [Pipelining](#pipelining)
1. [Product engineering](#product-engineering)
1. [Sources](#sources)

## Generic concepts

- Always think critically and question all the things. Especially those that don't appear to make any sense.<br/>
  Don't just follow trends or advice from others. They _might_ know better, but you will be the one dealing with the
  issues in the end.
- Try to understand how something really works, may it be a technology, a tool or what else.<br/>
  Try at least once to do manually what an automation would do in your place. Look at the source code of tools. Read the
  _fabulous_ documentation.
- Stay curious. Experiment. Learn and break things (in a sane and safe way). Dive deeper into what interests you.
- Make the **informed** decision that most satisfies your **current** necessities.<br/>
  There is no _perfect_ nor _correct_ solution, just different sets of tradeoff. Besides, no one will ever have all the
  information at the start, as some of them only come with experience and looking back at decisions one has already made
  gives the distorted perspective that those decisions were clearer than they really were.
- Review every decision after some time. Check they are still relevant, or if there is some improvement you can
  implement.<br/>
  Things change constantly: new technologies are given birth often, and processes improve. Also, now you know better
  then before.
- Keep things simple (KISS approach) **with respect of your ultimate goal** and not only for the sake of
  simplicity.<br/>
  Always going for the simple solution makes things complicated on a higher level.<br/>
  Check out [KISS principle is not that simple].
- Beware of complex things that _should be simple_.<br/>
  E.g., google what the _[SAFe] delusion_ is.
- Focus on what matters, but also set time aside to work on the rest.<br/>
  Check [Understanding the pareto principle (the 80/20 rule)].
- Learn from your (and others') mistakes.<br/>
  Check out the [5 whys] approach.
- Put in place processes to avoid repeating mistakes.
- Automate when and where you can, yet mind [the automation paradox].
- Automation does **not** necessarily involve
  [abstracting away][we have used too many levels of abstractions and now the future looks bleak].
- Keep different parts **de**coupled where possible, the same way
  [_interfaces_ are used in programming][what does it mean to program to interfaces?].<br/>
  This allows for quick and (as much as possible) painless switch between technologies.
- The _one-size-fits-all_ approach is a big fat lie.<br/>
  You'll end up with stiff, hard to change results that satisfy nobody. This proved particularly true with regards to
  templates and pipelines.
- Choose tools based on **how helpful** they are to achieve your goals.<br/>
  Do **not** adapt your work to specific tools.
- Backup your data, especially when you are about to update something.<br/>
  [Murphy's law] is lurking. Consider [the 3-2-1 backup strategy].
- [Branch early, branch often].
- [Keep a changelog].
- [Keep changes short and sweet][the art of small pull requests].<br/>
  Nobody likes to dive deep into a 1200 lines, 356 files pull request ([PR fatigue][how to tackle pull request fatigue],
  everybody?).
- Consider keeping changes in _behaviour_ (logic) separated from changes to the structure.<br/>
  It allows for easier debugging by letting you deal with one great issue at a time.
- Make changes easy, avoid making easy changes.<br/>
  Easy changes will build up long term and become a pain to deal with.
- [Trunk-based development][trunk-based development: a comprehensive guide] and other branching strategies all
  work.<br/>
  Consider the [different pros and cons of each][git branching strategies vs. trunk-based development].
- Refactoring _can_ be an option.<br/>
  Just **don't default** to it nor use it mindlessly.
- Be aware of [corporate bullshit][from inboxing to thought showers: how business bullshit took over].
- _DevOps_, _GitOps_ and other similar terms are sets of practices, suggestions, or approaches.<br/>
  They are **not** roles or job titles.<br/>
  They are **not** to be taken literally.<br/>
  They **need** to be adapted to the workplace, not the other way around.
- [Amazon's leadership principles] are double-edge swords.<br/>
  Only Amazon was able to apply them as they are defined, and they still create a lot of discontent.
- Keep Goodhart's law in mind:
  > When a measure becomes a target, it ceases to be a good measure.

## Teamwork

- Respect what is already there, but strive to improve it.<br/>
  Current solutions are there for a reason. Learn about their ins and outs **and, most of all, the why**.<br/>
  Then try to make them better.
- Don't just dismiss your teammates' customs.<br/>
  E.g., use [EditorConfig] instead of your editor's specific setting files only.
- You, your teammates and other teams in your company _should be_ on the same boat and _should be_ shooting for the same
  goal.<br/>
  Act like it. You may as well collaborate instead of fighting.

## CI/CD specific

- Keep _integration_, _delivery_ and _deployment_ separated.<br/>
  They are different concepts, and as such should require different tasks.<br/>
  This also allows for checkpoints, and to fail fast with less to no unwanted consequence.

### Pipelining

- Differentiate what the concept of pipelines really is from the idea of pipelines in approaches like DevOps.<br/>
  Pipelines are sequences of actions. Pipelines in DevOps and alike end up being magic tools to take actions away from
  people.
- Keep in mind [the automation paradox].<br/>
  Pipelines tend to easily become complex systems just like Rube Goldberg machines.
- Keep tasks as simple, consistent and reproducible as possible.<br/>
  Avoid like the plague to put programs or scripts in pipelines: they should be _glue_, not replace applications.
- All tasks should be able to execute from one's own local machine.<br/>
  This allows to fail fast and avoid wasting time waiting for pipelines to run in a black box somewhere.
- Consider using local automation to guarantee basic quality **before** the code reaches the shared repository.<br/>
  Tools like [`pre-commit`][pre-commit] or [`lefthook`][lefthook] are a doozy for this.
- DevOps pipelines are meant to be used as **last mile** steps for specific goals.<br/>
  There **cannot** be a single pipeline for everything, the same way as the _one-size-fits-all_ concept never really
  works.

## Product engineering

Consider what follows for infrastructure and platform engineering as well.

- Focus on creating things users will want to use.<br/>
  Tools should solve issues and alleviate pain points, not create additional walls.
- Focus on small audiences first. Avoid trying appealing lots of users from the beginning.<br/>
  If you do not have a user base, the product has no reason to exist but your will to create it.
- Consider and fix users' pain points **before** adding new features.<br/>
  If users are not happy with your tool they'll try moving away from it, bringing the discussion back to the previous
  point in this list.
- Avoid creating mindless abstractions, like templates using variables for all their attributes.<br/>
  Prefer providing one or at most a few simplified solutions that use different
  [adapters or interfaces][what does it mean to program to interfaces?] in the background instead.<br/>
  E.g., check out how [Crossplane] works.

## Sources

Listed in order of addition:

- Personal experience
- [A case against "platform teams"] by Kislay Verma
- [Culture eats your structure for lunch] by Lawrence Serewicz
- [DevOps is bullshit] by Cory O'Daniel
- [Platform teams need a delightfully different approach, not one that sucks less] by Fawad Khaliq and Ali Khayam
- [We have used too many levels of abstractions and now the future looks bleak]
- [Why the fuck are we templating YAML?] by Lee Briggs
- [Trunk-based development: a comprehensive guide]
- [Git Branching Strategies vs. Trunk-Based Development]
- [Branch early, branch often]
- [Amazon's leadership principles]
- [Amazon's tenets: supercharging decision-making]
- [How to tackle Pull Request fatigue] by Dorian Smiley
- [The art of small Pull Requests] by David Wilson
- [From inboxing to thought showers: how business bullshit took over] by André Spicer
- [Simple sabotage for software] by Erik Bernhardsson
- [Hacking your manager - how to get platform engineering on their radar]
- [KISS principle is not that simple] by William Artero
- [What does it mean to program to interfaces?] by Attila Fejér
- [Understanding the pareto principle (the 80/20 rule)]
- [The 3-2-1 backup strategy] by Yev Pusin
- [5 whys]
- [Thinking about lockdowns] by CGP Grey
- [Why your platform monolith is probably a bad idea] by David Leitner
- [How to mind Goodhart's law and avoid unintended consequences]
- [The XY problem]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[crossplane]: https://www.crossplane.io/
[editorconfig]: editorconfig.md
[keep a changelog]: keep%20a%20changelog.md
[lefthook]: lefthook.md
[pre-commit]: pre-commit.md
[safe]: safe.placeholder
[the automation paradox]: the%20automation%20paradox.md

<!-- Others -->
[5 whys]: https://www.mindtools.com/a3mi00v/5-whys
[a case against "platform teams"]: https://kislayverma.com/organizations/a-case-against-platform-teams/
[amazon's leadership principles]: https://www.amazon.jobs/content/en/our-workplace/leadership-principles
[amazon's tenets: supercharging decision-making]: https://aws.amazon.com/blogs/enterprise-strategy/tenets-supercharging-decision-making/
[branch early, branch often]: https://medium.com/@huydotnet/branch-early-branch-often-daadaad9468e
[culture eats your structure for lunch]: https://thoughtmanagement.org/2013/07/10/culture-eats-your-structure-for-lunch/
[devops is bullshit]: https://blog.massdriver.cloud/posts/devops-is-bullshit/
[from inboxing to thought showers: how business bullshit took over]: https://www.theguardian.com/news/2017/nov/23/from-inboxing-to-thought-showers-how-business-bullshit-took-over
[git branching strategies vs. trunk-based development]: https://launchdarkly.com/blog/git-branching-strategies-vs-trunk-based-development/
[hacking your manager - how to get platform engineering on their radar]: https://www.youtube.com/watch?v=8xprsTXKr0w
[how to mind goodhart's law and avoid unintended consequences]: https://builtin.com/data-science/goodharts-law
[how to tackle pull request fatigue]: https://javascript.plainenglish.io/tackling-pr-fatigue-6865edc205ce
[kiss principle is not that simple]: https://artero.dev/posts/kiss-principle-is-not-that-simple/
[murphy's law]: https://en.wikipedia.org/wiki/Murphy%27s_law
[platform teams need a delightfully different approach, not one that sucks less]: https://www.chkk.io/blog/platform-teams-different-approach
[simple sabotage for software]: https://erikbern.com/2023/12/13/simple-sabotage-for-software.html
[the 3-2-1 backup strategy]: https://www.backblaze.com/blog/the-3-2-1-backup-strategy/
[the art of small pull requests]: https://essenceofcode.com/2019/10/29/the-art-of-small-pull-requests/
[the xy problem]: https://xyproblem.info/
[thinking about lockdowns]: https://www.youtube.com/watch?v=SVmEXdGqO-s
[trunk-based development: a comprehensive guide]: https://launchdarkly.com/blog/introduction-to-trunk-based-development/
[understanding the pareto principle (the 80/20 rule)]: https://betterexplained.com/articles/understanding-the-pareto-principle-the-8020-rule/
[we have used too many levels of abstractions and now the future looks bleak]: https://unixsheikh.com/articles/we-have-used-too-many-levels-of-abstractions-and-now-the-future-looks-bleak.html
[what does it mean to program to interfaces?]: https://www.baeldung.com/cs/program-to-interface
[why the fuck are we templating yaml?]: https://leebriggs.co.uk/blog/2019/02/07/why-are-we-templating-yaml
[why your platform monolith is probably a bad idea]: https://www.youtube.com/watch?v=3B0TbV-Ipmo
