# Contributing

Thanks for considering a contribution! This doc covers:
- How to file issues / ideas
- How to develop locally
- How to upstream-contribute (e.g. PR an agent to `msitarzewski/agency-agents`)

---

## Filing issues

Good issues include:

- **OS + version** (Ubuntu 22.04 / macOS 14 / Windows 11 + WSL2)
- **Tool versions**: `node -v`, `python --version`, `wechatsync --version`, Chrome version
- **Exact command run** + full output (sanitize tokens!)
- What you expected vs. what happened

Bad issues: "it doesn't work" with no context.

## Local development

```bash
git clone https://github.com/lz-googlefycy/agency-blog-publisher.git
cd agency-blog-publisher

# Install deps + tools
bash scripts/install.sh

# Make changes, test, then:
bash scripts/install.sh --dry-run    # if your change is in install.sh
publish status                        # if your change is in publish.sh

# Run shellcheck before committing
shellcheck scripts/*.sh
```

## What we want PRs for

Priorities:

| Area | Example contributions |
|---|---|
| 📚 Docs | Improve clarity, fix typos, add examples |
| 🛠️ install.sh | Better OS support (Arch, Alpine, Fedora) |
| 🔧 publish.sh | New subcommands, better error messages |
| 🤖 New skills | OpenCode skills for specific use cases (e.g. "publish-from-notion") |
| 📦 New platform adapters | If a platform isn't covered, document the gap and propose a fallback |
| 🧪 CI | GitHub Actions for shellcheck / markdown lint |

## Coding conventions

- **Bash**: pass shellcheck. Use `set -euo pipefail`. Quote variables.
- **Markdown**: keep lines ≤ 100 chars. Use ATX headers (`#`). One sentence per line for diff-friendliness.
- **Commit messages**: imperative mood, ≤ 72 chars subject. Body explains "why".

## Upstream contribution: agent → agency-agents

`agents/marketing-multi-platform-publisher.md` is designed to be PR'd to the upstream [agency-agents](https://github.com/msitarzewski/agency-agents) repo. To do that:

```bash
# 1. Fork msitarzewski/agency-agents, clone your fork
git clone https://github.com/<YOUR_USERNAME>/agency-agents.git
cd agency-agents

# 2. Branch
git checkout -b feat/multi-platform-publisher

# 3. Copy from this repo (assumes both repos checked out side-by-side)
cp ../agency-blog-publisher/agents/marketing-multi-platform-publisher.md \
   marketing/marketing-multi-platform-publisher.md

# 4. Adapt to upstream conventions:
#    - Strip any "default environment" hardcoded paths
#    - Keep tool references generic (Wechatsync / biliup / xiaohongshu-mcp)
#    - Match upstream agent template (see CONTRIBUTING.md in agency-agents)

# 5. Validate
bash scripts/lint-agents.sh   # if upstream has it

# 6. PR
git add . && git commit -m "feat: add Multi-Platform Publisher agent for Chinese content distribution"
git push origin feat/multi-platform-publisher
gh pr create --title "Add Multi-Platform Publisher agent" \
             --body "Orchestrates one-click publishing to Chinese content platforms..."
```

The upstream maintainers may ask for revisions — be patient and responsive.

## Questions?

- Open a GitHub Discussion for design questions
- Open an Issue for bugs
- @-mention the maintainer in PR for review

Thanks!
