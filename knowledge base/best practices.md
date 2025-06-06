# OAM best practices

What really worked for me personally, or in my experience.

1. [Generic concepts](#generic-concepts)
1. [Teamwork](#teamwork)
1. [CI/CD specific](#cicd-specific)
   1. [Pipelining](#pipelining)
1. [Product engineering](#product-engineering)
1. [Management](#management)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Generic concepts

- Always think critically and question all the things. Especially those that don't appear to make any sense.<br/>
  Don't just follow trends or advice from others. They _might_ know better, but you will be the one dealing with the
  issues in the end.
- Try to understand how something really works, may it be a technology, a tool or what else.<br/>
  Try at least once to do manually what an automation would do in your place. Look at the source code of tools. Read the
  _fabulous_ documentation. Check if they hide error messages behind successful responses.
- Stay curious. Experiment. Learn and break things (in a sane and safe way). Dive deeper into what interests you.
- Make the **informed** decision that most satisfies your **current** necessities.<br/>
  There is no _perfect_ nor _correct_ solution, just different sets of tradeoff. Besides, no one will ever have all the
  information at the start, as some of them only come with experience and looking back at decisions one has already made
  gives the distorted perspective that those decisions were clearer than they really were.
- Review every decision after some time. Check they are still relevant, or if there is some improvement you can
  implement.<br/>
  Things change constantly: new technologies are given birth often, and processes improve. Also, now you know better
  then before.
- Gain the hard skills required to solve complex problems, but only deploy complex solutions when they are actually,
  _really_, needed.
- Focus on the **real** problem at hand.<br/>
  Beware the [the XY problem].
- When making a **business** decision, it's generally good to pick the simplest, fastest, and cheapest option.<br/>
  When making a **career** decision, it pays to be an expert in hard things.
- Do not make things more complicated than they **need** to be.
  Also read [Death by a thousand microservices].
- Keep things simple (KISS approach) **with respect of your ultimate goal** and not only for the sake of
  simplicity.<br/>
  Always going for the simple solution makes things complicated on a higher level.<br/>
  Check out [KISS principle is not that simple].
- Modularize stuff when it makes sense, not just to
  [avoid repetitions][don't repeat yourself(dry) in software development].
- Create abstractions that **do** hide away the complexity behind them.<br/>
  Avoid creating wrappers that would map features 1-to-1 with their
  [_not-abstracted-anymore_ target object][we have used too many levels of abstractions and now the future looks bleak],
  and just use the original processes and tools when in need of control.
- Beware of complex things that _should be simple_.<br/>
  E.g., check what the _[SAFe] delusion_ is.
- Focus on what matters, but also set time aside to work on the rest.<br/>
  Check [Understanding the pareto principle (the 80/20 rule)].
- Learn from your (and others') mistakes.<br/>
  Check out the [5 whys] approach.
- Put in place processes to avoid repeating mistakes.
- Automate when and where you can, yet mind [the automation paradox] and
  [abstractions][we have used too many levels of abstractions and now the future looks bleak].
- Keep different parts **de**coupled where possible, the same way
  [_interfaces_ are used in programming][what does it mean to program to interfaces?].<br/>
  Allows for quick and (as much as possible) painless switch between technologies.
- The _one-size-fits-all_ approach is a big fat lie.<br/>
  One'll end up with stiff, hard to change results that satisfy nobody. This proved particularly true with regards to
  _templates_ and _pipelines_.<br/>
  Stop designing systems that _should work for everybody at all times_. Prefer safe defaults instead.
- Choose tools based on **how helpful** they are **to you** to achieve your goals.<br/>
  Do **not** adapt your work to specific tools.
- Keep track of tools' EOL and keep them updated accordingly.
  Trackers like [endoflife.date] could help in this.
- Backup your data, especially when you are about to make changes to something managing or storing it.<br/>
  [Murphy's law] is lurking. Consider [the 3-2-1 backup strategy].
- [Branch early, branch often].
- [Keep a changelog].
- [Keep changes short and sweet][the art of small pull requests].<br/>
  Nobody likes to dive deep into a 1200+ lines, 356+ files pull request
  ([PR fatigue][how to tackle pull request fatigue], right?).
- Consider keeping changes in _behaviour_ (logic) separated from changes to the _structure_.<br/>
  It allows for easier debugging by letting you deal with one great issue at a time.
- Make changes easy, avoid making _easy changes_.<br/>
  Easy changes will only build up with time and become a pain to deal with long term.
- [Trunk-based development][trunk-based development: a comprehensive guide] and other branching strategies **all**
  work.<br/>
  Consider the [different pros and cons of each][git branching strategies vs. trunk-based development].
- Refactoring _can_ be an option.<br/>
  Just **don't default** to it nor use it mindlessly.
- Be aware of [corporate bullshit][from inboxing to thought showers: how business bullshit took over].
- _DevOps_, _GitOps_ and other similar terms are sets of practices, suggestions, or approaches.<br/>
  They should **not** roles or job titles.<br/>
  They should **not** to be taken literally.<br/>
  They **need** to be adapted to the workplace, not the other way around.
- [Amazon's leadership principles] are generally good practices, but also double-edge swords.<br/>
  They still create a lot of discontent even inside Amazon when used _against_ anybody.
- Keep Goodhart's law in mind:
  > When a measure becomes a target, it ceases to be a good measure.
- Always have a plan B.
- When managing permissions, consider [break glass][break glass explained: why you need it for privileged accounts]
  procedures and/or tools.

## Teamwork

- Respect what is already there, but strive to improve it.<br/>
  Current solutions are there for a reason. Learn about their ins and outs **and, most of all, the why**. Only _then_,
  it makes any sense to try to make them better.
- Don't just dismiss your teammates' customs.<br/>
  E.g., use [EditorConfig] instead of your editor's specific setting files only.
- One and one's contributors (e.g. one's teammates and other teams in one's company) _should be_ on the same boat and
  _should be_ shooting for the same goals.<br/>
  Act like it. You may as well collaborate instead of fighting each other.
- Prefer using standardized execution environments to avoid the _it works on my machine_ conundrum.<br/>
  This helps to ensure everybody does things the same way, (hopefully) reaching the same results.<br/>
  E.g., run commands in [`nix`][nix] or containers, use virtual environments specific to repositories, configure
  standard actions in tools like [`task`][task] or [GNU `make`][make].

## CI/CD specific

- Keep _integration_, _delivery_ and _deployment_ **separated**.<br/>
  They are different concepts, and as such should require different tasks.<br/>
  This also allows for checkpoints, and to fail fast with less to no unwanted consequence.
- Consider adopting the [_main must be green_ principle][keeping green].

### Pipelining

- Differentiate what the **concept** of pipelines really is from the **idea** of pipelines in approaches like
  DevOps.<br/>
  Pipelines in general should be nothing more than _sequences of actions_. Pipelines in DevOps (and alike) end up most
  of the times being _magic tools that take actions away from people_.
- Keep in mind [the automation paradox].<br/>
  Pipelines tend to become complex systems just like Rube Goldberg machines.
- Keep tasks as simple, consistent and reproducible as possible.<br/>
  Avoid like the plague relying on programs or scripts written directly in pipelines: pipeline should act as the _glue_
  connecting tasks, not replace full fledged applications.
- Most, if not all, pipeline tasks should be able to execute from one's own local machine.<br/>
  This allows to fail fast and avoid wasting time waiting for pipelines to run in a black box somewhere.
- Pipelines are a good central place from which make changes to critical resources.<br/>
  Developers should **not** have the access privileges to make such changes _by default_, but selected people **shall**
  have ways to obtain those permissions for emergencies
  ([break glass][break glass explained: why you need it for privileged accounts]).
- DevOps pipelines should be meant to be used as **last mile** steps for **specific** goals.<br/>
  There **cannot** be a single pipeline for everything, the same way as the _one-size-fits-all_ concept never really
  works.
- Try and strike a balance between what **needs** to be done centrally (e.g. from a repository's `origin` remote) and
  what can be done locally from one's machine **before** the code reaches repositories' remotes.<br/>.
  Tools like [`pre-commit`][pre-commit] or [`lefthook`][lefthook] are a doozy for this, but can disrupt the development
  experience and encourage the use of the `--no-verify` switch. Actions that need to be enforced (e.g. automatic
  formatting) are usually worth done only when changes reach the central remote anyways.

## Product engineering

Consider what follows for _infrastructure_ and _platform engineering_ as well.

- Focus on creating things users will **want** to use.<br/>
  Tools should solve issues and alleviate pain points, not create additional walls.
- Focus on **small** audiences first. Avoid trying appealing lots of users from the very beginning.<br/>
  If one does not have a user base, one's product has no reason to exist but one's will to create it.
- Consider and fix users' pain points **before** adding new features.<br/>
  If users are not happy with one's tool they'll try moving away from it, bringing the discussion back to the previous
  point in this list.
- Avoid creating _effectively useless_ abstractions, like templates that use variables for _all_ their attributes.<br/>
  Prefer providing one, or at most a few, simplified solution that use different
  [adapters or interfaces][what does it mean to program to interfaces?] in the background instead.<br/>
  E.g., check out how [Crossplane], [Radius] and [KRO] work.
- Offer **clear** error messages and **immediate** access to them.<br/>
  Consider leveraging different, more specific status codes for different _global_ results. E.g.:

  - Return `5` instead of `1` in UNIX to point out an executable could not find a required file.
  - Return [422 Unprocessable Content] instead of [200 OK] if a request was syntactically correct, but the data it
    contained was wrong.
  - Return [207 Multi-Status] instead of [200 OK] if an API fulfilled a request successfully, but something in the more
    global process did not quite _fully_ go as expected.

## Management

- Beware the [action fallacy][the "action fallacy" tells us that the most effective leaders are unseen].

## Further readings

- [Standard Exit Status Codes in Linux]
- [200 OK], [207 Multi-Status], [422 Unprocessable Content]

### Sources

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
- [Don't repeat yourself(DRY) in Software Development]
- [Wisdom From Linus - Prime Reacts]
- [Are We Celebrating the Wrong Leaders? - Martin Gutmann]
- [The "action fallacy" tells us that the most effective leaders are unseen]
- [Death by a thousand microservices]
- [Maybe you do need Kubernetes]
- [The 10 Commandments of Navigating Code Reviews]
- [Less Is More: The Minimum Effective Dose]
- [AWS re:Invent 2023 - Platform engineering with Amazon EKS (CON311)]
- [Break Glass Explained: Why You Need It for Privileged Accounts]
- [Keeping green]
- [Why committing straight to main/master must be allowed]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[crossplane]: kubernetes/crossplane.placeholder
[editorconfig]: editorconfig.md
[keep a changelog]: keep%20a%20changelog.md
[kro]: kubernetes/kro.md
[lefthook]: lefthook.md
[make]: gnu%20userland/make.md
[nix]: nix.md
[pre-commit]: pre-commit.md
[radius]: cloud%20computing/radius.md
[safe]: safe.md
[task]: task.md
[the automation paradox]: the%20automation%20paradox.md

<!-- Others -->
[200 ok]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/200
[207 multi-status]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/207
[422 unprocessable content]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/422
[5 whys]: https://www.mindtools.com/a3mi00v/5-whys
[a case against "platform teams"]: https://kislayverma.com/organizations/a-case-against-platform-teams/
[amazon's leadership principles]: https://www.amazon.jobs/content/en/our-workplace/leadership-principles
[amazon's tenets: supercharging decision-making]: https://aws.amazon.com/blogs/enterprise-strategy/tenets-supercharging-decision-making/
[are we celebrating the wrong leaders? - martin gutmann]: https://www.youtube.com/watch?v=b0Z9IpTVfUg
[aws re:invent 2023 - platform engineering with amazon eks (con311)]: https://www.youtube.com/watch?v=eLxBnGoBltc
[branch early, branch often]: https://medium.com/@huydotnet/branch-early-branch-often-daadaad9468e
[break glass explained: why you need it for privileged accounts]: https://www.strongdm.com/blog/break-glass
[culture eats your structure for lunch]: https://thoughtmanagement.org/2013/07/10/culture-eats-your-structure-for-lunch/
[death by a thousand microservices]: https://renegadeotter.com/2023/09/10/death-by-a-thousand-microservices.html
[devops is bullshit]: https://blog.massdriver.cloud/posts/devops-is-bullshit/
[don't repeat yourself(dry) in software development]: https://www.geeksforgeeks.org/dont-repeat-yourselfdry-in-software-development/
[endoflife.date]: https://endoflife.date/
[from inboxing to thought showers: how business bullshit took over]: https://www.theguardian.com/news/2017/nov/23/from-inboxing-to-thought-showers-how-business-bullshit-took-over
[git branching strategies vs. trunk-based development]: https://launchdarkly.com/blog/git-branching-strategies-vs-trunk-based-development/
[hacking your manager - how to get platform engineering on their radar]: https://www.youtube.com/watch?v=8xprsTXKr0w
[how to mind goodhart's law and avoid unintended consequences]: https://builtin.com/data-science/goodharts-law
[how to tackle pull request fatigue]: https://javascript.plainenglish.io/tackling-pr-fatigue-6865edc205ce
[keeping green]: https://fullstackopen.com/en/part11/keeping_green
[kiss principle is not that simple]: https://artero.dev/posts/kiss-principle-is-not-that-simple/
[less is more: the minimum effective dose]: https://medium.com/the-mission/less-is-more-the-minimum-effective-dose-e6d56625931e
[maybe you do need kubernetes]: https://blog.boot.dev/education/maybe-you-do-need-kubernetes/
[murphy's law]: https://en.wikipedia.org/wiki/Murphy%27s_law
[platform teams need a delightfully different approach, not one that sucks less]: https://www.chkk.io/blog/platform-teams-different-approach
[simple sabotage for software]: https://erikbern.com/2023/12/13/simple-sabotage-for-software.html
[standard exit status codes in linux]: https://www.baeldung.com/linux/status-codes
[the "action fallacy" tells us that the most effective leaders are unseen]: https://bigthink.com/business/action-fallacy-most-effective-leaders-unseen/
[the 10 commandments of navigating code reviews]: https://angiejones.tech/ten-commandments-code-reviews/
[the 3-2-1 backup strategy]: https://www.backblaze.com/blog/the-3-2-1-backup-strategy/
[the art of small pull requests]: https://essenceofcode.com/2019/10/29/the-art-of-small-pull-requests/
[the xy problem]: https://xyproblem.info/
[thinking about lockdowns]: https://www.youtube.com/watch?v=SVmEXdGqO-s
[trunk-based development: a comprehensive guide]: https://launchdarkly.com/blog/introduction-to-trunk-based-development/
[understanding the pareto principle (the 80/20 rule)]: https://betterexplained.com/articles/understanding-the-pareto-principle-the-8020-rule/
[we have used too many levels of abstractions and now the future looks bleak]: https://unixsheikh.com/articles/we-have-used-too-many-levels-of-abstractions-and-now-the-future-looks-bleak.html
[what does it mean to program to interfaces?]: https://www.baeldung.com/cs/program-to-interface
[why committing straight to main/master must be allowed]: https://dev.to/jonlauridsen/committing-straight-to-mainmaster-must-be-allowed-138e
[why the fuck are we templating yaml?]: https://leebriggs.co.uk/blog/2019/02/07/why-are-we-templating-yaml
[why your platform monolith is probably a bad idea]: https://www.youtube.com/watch?v=3B0TbV-Ipmo
[wisdom from linus - prime reacts]: https://www.youtube.com/watch?v=EvzB_Q1gSds
