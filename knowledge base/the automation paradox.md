# The automation paradox

The point of automation is to reduce the manual workload.<br/>
Its goals include also maintaining the consistency and reliability of infrastructure and processes.

The issue:

- For every automation one puts in place, a _system_ is created.<br/>
  Said system is either the automation itself or the set of tools used to create it.
- Any system needs proper configuration and maintenance.
- No matter how, one always ends up relying on systems to maintain other systems.<br/>
  Re-read the first point in this list to remember why.
- Complex systems trend toward being _brittle_ and _expensive_.<br/>
  This point is especially true when using imperative runbooks.<br/>
  Google [_Software crisis_][software crisis] for more info.
- The need to manage complexity gave birth to a whole cottage industry.<br/>
  This includes tools and specific job titles (i.e. _DevOps_, _SRE_).
- The tools used to implement one's system need to be consistent and reliable.<br/>
  Should they not be, their issues defeat the whole purpose of the automation.

Possible solutions:

- Move from imperative to declarative (desired state) where one can.<br/>
  Check out [the _GitOps_ approach][gitops].
- Apply the KISS approach where possible.<br/>
  Make it so that is simple to maintain, not necessarily simple for the sake of simplicity.<br/>
  Check out [KISS principle is not that simple].
- Focus on the tools that most allow one to simplify the automation.<br/>
  Dependent on the final goals.
- Limit abstractions.<br/>
  Check out [We have used too many levels of abstractions and now the future looks bleak] and [Why the fuck are we templating yaml?].

## Sources

- Personal experience
- [Automating your source of truth - GitOps and Terraform]
- [Software crisis]
- [We have used too many levels of abstractions and now the future looks bleak]
- [Why the fuck are we templating yaml?] by Lee Briggs
- [KISS principle is not that simple] by William Artero

<!--
  References
  -->

<!-- Knowledge base -->
[gitops]: gitops.md

<!-- Others -->
[automating your source of truth - gitops and terraform]: https://www.youtube.com/watch?v=-K8R1OVXPy0
[kiss principle is not that simple]: https://artero.dev/posts/kiss-principle-is-not-that-simple/
[software crisis]: https://www.geeksforgeeks.org/software-engineering-software-crisis/
[we have used too many levels of abstractions and now the future looks bleak]: https://unixsheikh.com/articles/we-have-used-too-many-levels-of-abstractions-and-now-the-future-looks-bleak.html
[why the fuck are we templating yaml?]: https://leebriggs.co.uk/blog/2019/02/07/why-are-we-templating-yaml.html
