# Model Context Protocol

Open protocol enabling seamless integration between AI applications and external data sources and tools by providing
a standardized way to enable LLMs to access key information and perform tasks.

1. [TL;DR](#tldr)
1. [MCP servers of interest](#mcp-servers-of-interest)
1. [Troubleshooting](#troubleshooting)
   1. [Cloudflare WAF blocks Linear comments with code blocks](#cloudflare-waf-blocks-linear-comments-with-code-blocks)
   1. [Google Drive `create_file` only auto-converts plain text](#google-drive-create_file-only-auto-converts-plain-text)
   1. [Docker-based MCP host header validation differs from listen address](#docker-based-mcp-host-header-validation-differs-from-listen-address)
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
> This is currently a [confirmed issue only in Claude Code][claude code / mcp servers in sub-agents]. Refer to it for
> details and mitigations.

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

## Troubleshooting

### Cloudflare WAF blocks Linear comments with code blocks

Linear's official MCP routes through Cloudflare-protected endpoints. Cloudflare's WAF inspects payloads and blocks
comments containing fenced code blocks (specifically triple backticks) when their content matches security-related
patterns ike SSL/TLS configuration, HAProxy directives, certificate paths, `curl` flags.<br/>
The error returned is a Cloudflare HTML 403 page titled _Sorry, you have been blocked_.

> [!tip]
> Use prose descriptions instead. Inline backticks are fine — only triple-backtick fenced blocks trigger the WAF.

### Google Drive `create_file` only auto-converts plain text

The Google Drive MCP `create_file` tool auto-converts `text/plain` to Google Docs and `text/csv` to Google Sheets.
Other source MIME types (including `text/html`) upload as-is, and stay in their original format.<br/>
Rich-formatted Docs _can_ be converted (though results' quality may vary) by uploading HTML first, then converting the
uploaded document through Drive's UI (right-click → _Open with → Google Docs_). The resulting Doc gets a **new** file
ID, distinct from the source one.

### Docker-based MCP host header validation differs from listen address

When running an MCP server in Docker with HTTP/streamable-http transport, the listen address (`0.0.0.0` for port
forwarding to work) and the `Host` header whitelist (matching what the client connects with, e.g. `127.0.0.1`) might be
distinct, with many servers exposing them as separate environment variables.<br/>
With `awslabs/aws-api-mcp-server`, set `AWS_API_MCP_HOST=0.0.0.0` for the bind and `AWS_API_MCP_ALLOWED_HOSTS=127.0.0.1`
(comma-separated, supports `*` wildcard) for the whitelist. Both variables must be set, or requests will be rejected
with a generic JSON-RPC `-32602` error and the real reason hidden in container logs.

> [!tip]
> Always use `127.0.0.1` rather than `localhost` in MCP client URLs. `localhost` may resolve to `::1` first (especially
> in macOS), or fail to fall back to IPv4 on systems where the server only binds the IPv4 stack.

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
[Claude Code / MCP servers in sub-agents]: claude/claude%20code.md#mcp-servers-in-sub-agents
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
