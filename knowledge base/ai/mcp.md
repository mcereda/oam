# Model Context Protocol

Open protocol enabling seamless integration between AI applications and external data sources and tools by providing
a standardized way to enable LLMs to access key information and perform tasks.

1. [TL;DR](#tldr)
1. [MCP servers of interest](#mcp-servers-of-interest)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

MCP consists of:

- The _data_ layer, defining the JSON-RPC based protocol for client-server communication.<br/>
  It includes lifecycle management and core primitives, e.g. tools, resources, prompts and notifications.
- The _transport_ layer, defining the communication mechanisms and channels that enable data exchange between clients
  and servers.<br/>
  It includes transport-specific connection establishment, message framing, and authorization.

MCP _hosts_ are AI applications users can interact with, and that coordinate and manage one or more MCP clients.<br/>
MCP _clients_ are components that connect to a single MCP server to gather context from it for the host to use.<br/>
MCP _servers_ are applications providing data to one or more MCP clients to use for context.

MCP hosts create one MCP client for each MCP server they use.<br/>
Each client maintains a dedicated connection with its corresponding server.

Servers provide functionality through _tools_, _resources_, and _prompts_.<br/>
_Tools_ are functions that an LLM can **actively** call to take actions, i.e. writing to databases, calling external
APIs, modifying files, or triggering other logic. The LLM decides when to use them based on user requests.<br/>
_Resources_ are **passive** data sources providing **read-only** access to information for context, such as files,
database schemas, or API documentation.<br/>
_Prompts_ are pre-built instruction templates telling the model reading them how to work with specific tools and
resources.

Clients _can_ provide features to servers, aside from making use of the context they provide.<br/>
Client features allow server authors to build richer interactions through _elicitation_, _roots_, and _sampling_.
_Elicitation_ enables servers to request specific information from users.<br/>
_Roots_ define filesystem boundaries for server operations, allowing clients to specify which folders servers should
focus on.<br/>
_Sampling_ allows servers to request LLM completions through the client. This is what enables an agentic workflow.

MCP uses string-based version identifiers that follow the `YYYY-MM-DD` format.<br/>
Versions indicate the **last** date that backwards incompatible changes were made in the protocol.

Version negotiation happens during initialization.<br/>
Clients and servers _may_ support multiple protocol versions simultaneously, but they _**must**_ agree on a single
version to use for the session.<br/>
The protocol provides error handling if version negotiation fails, which allows clients to gracefully terminate
connections when they cannot find a version compatible with the server.

> [!warning]
> When agent harnesses spawn sub-agents, they may inherit all configured MCP servers by default, broadening the attack
> surface, and wasting context window and computing resources.<br/>
> Refer to [MCP servers and sub-agents][agents / mcp servers and sub-agents] for details and mitigations.

## MCP servers of interest

| MCP server                                        | Summary                                                  |
| ------------------------------------------------- | -------------------------------------------------------- |
| [AWS API][aws api mcp server]                     | Interact with all AWS services and resources via AWS CLI |
| [AWS Cost Explorer][aws cost explorer mcp server] | Analyze AWS costs and usage data                         |
| [Grafana MCP Server]                              | Interact with [Grafana] dashboards and services          |

> [!caution]
> Verify MCP servers and the tools they offer before using them.<br/>
> Using MCP servers without verifying tools and descriptions could lead to vulnerability to tool- and prompt- poisoning,
> shadowing, or injection.

## Further readings

- [Website]
- [Codebase]
- [Blog]

### Sources

- [Documentation]
- [Transports specification]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Agents / MCP servers and sub-agents]: agents.md#mcp-servers-and-sub-agents
[Grafana]: ../grafana.md

<!-- Files -->
<!-- Upstream -->
[Blog]: https://blog.modelcontextprotocol.io/
[Codebase]: https://github.com/modelcontextprotocol
[Documentation]: https://modelcontextprotocol.io/docs/
[Website]: https://modelcontextprotocol.io

<!-- Others -->
[AWS API MCP Server]: https://github.com/awslabs/mcp/tree/main/src/aws-api-mcp-server
[AWS Cost Explorer MCP Server]: https://github.com/awslabs/mcp/tree/main/src/cost-explorer-mcp-server
[Grafana MCP Server]: https://github.com/grafana/mcp-grafana
[Transports specification]: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports
