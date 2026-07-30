# Resolve external context

Step 0 for `flow-review`, `flow-test`, `audit-security`, `audit-perf`, `audit-debt`, `audit-a11y`, `flow-debug`, and `flow-explore`: if `$ARGUMENTS` contains a URL with little or no inline description, resolve it before anything else.

Identify which connected service the URL belongs to from its domain. Use ToolSearch to find a matching fetch/read tool for that service (e.g. a URL under `app.clickup.com` points at the ClickUp tools, `notion.so` at the Notion tools, `github.com` at `gh` via Bash or the GitHub tools), and call it to pull the content. Extract the relevant scope and requirements from what comes back. Treat the resolved text as the effective `$ARGUMENTS` for the rest of the procedure - never hand a bare link to a sub-agent.
