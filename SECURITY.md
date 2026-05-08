# Security & Risk Disclosure

## Threat model

This project orchestrates **publishing** to Chinese content platforms by reusing your browser's logged-in cookies through the Wechatsync Chrome extension. It is **not** an official API integration — none of the target platforms (知乎, 小红书, CSDN, B站, etc.) provide a public publishing API for individual creators.

## What lives where

| Asset | Location | Sensitivity |
|---|---|---|
| Wechatsync MCP token | `~/.bashrc` (env var `WECHATSYNC_TOKEN`) and Chrome extension storage | **High** — anyone with this token + access to your localhost can drive your browser sessions |
| Platform cookies | Chrome's own cookie jar | **High** — full account access |
| Biliup cookies | `~/cookies.json` (or wherever you `biliup login` from) | **High** — B 站 account access |
| Xiaohongshu cookies | `~/.mcp/rednote/cookies.json` (xhs-mcp default) | **High** |

## Hard rules

1. **Never commit any of the above to a public repo.** This repo's `.gitignore` is configured to block them, but verify before each commit.
2. **Never share your Wechatsync token in screenshots, chat logs, or issue reports.** Sanitize before posting.
3. **Use a dedicated machine or browser profile** for content automation if you can — keeps your daily browser cookies isolated.
4. **Rotate tokens** when in doubt. In the Wechatsync extension popup, toggle MCP off/on to regenerate.
5. **Run `chmod 600` on cookie files**:
   ```bash
   chmod 600 ~/cookies.json ~/.mcp/rednote/cookies.json 2>/dev/null
   ```

## Platform compliance & legal

- This tool calls **official Web endpoints** from your browser session. It does not crack passwords, bypass captchas, or impersonate.
- That said, all the SDKs we depend on (Wechatsync, xiaohongshu-mcp, biliup, bilibili-api) are **reverse-engineered**. They work today, may not work tomorrow.
- **B 站 律师函事件 (2026-01)**: `SocialSisterYi/bilibili-API-collect` (an API documentation aggregator) was archived after receiving a lawyer's letter from Bilibili. The SDKs themselves remain operational, but:
  - **Do not** publicly redistribute API endpoint documentation derived from these SDKs
  - **Do not** use these tools for commercial mass-publishing services
  - **Do not** spam — respect rate limits and platform terms
- Each platform's ToS may forbid automated posting. **Risk is yours.**

## Rate limits (recommended self-imposed)

| Platform | Per-day cap | Inter-post jitter |
|---|---|---|
| 知乎 / CSDN | ≤ 5 | 30-180s random |
| 掘金 / 公众号 | ≤ 10 | 30-180s |
| 小红书 | ≤ 50 | 5+ min |
| B站专栏 | ≤ 5 | 30-180s |

## Image / content originality

- Some platforms (xhs especially) detect duplicate image MD5 across posts → flagged as 搬运
- For multi-platform posting, **vary images** per platform (crop / brightness tweak)
- Mark `is_original` accurately; lying about authorship can lead to bans

## Reporting a vulnerability

If you find a security issue in this repo's scripts or docs (e.g. accidentally committed secrets, command injection, supply-chain risk), please:

1. **Do not** open a public GitHub issue
2. Email or DM the maintainer with details
3. Allow 7 days for response before public disclosure

## Account loss

You acknowledge that automated posting carries account-suspension risk. The maintainers of this repo are not liable for:
- Account bans / restrictions
- Cookie / credential leaks (mitigate by following hard rules above)
- Content takedowns by platforms
- Any commercial damage from publishing failures

Use at your own risk.

## License

Apache-2.0. See [LICENSE](LICENSE).
