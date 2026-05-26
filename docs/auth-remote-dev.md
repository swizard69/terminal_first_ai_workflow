# Auth on remote dev (laptop → dev-server)

CLI agents (`claude`, `codex`) on a **remote dev machine** listen on `localhost:<port>`.
After OAuth, the browser on your **laptop** redirects to **local** `localhost` — the callback never reaches the remote host.

Fix: **SSH port forward** before running login.

---

## Diagram

```text
laptop browser  →  http://localhost:1455/auth/callback
                         ↓ SSH -L
dev-server      ←  127.0.0.1:1455  ←  codex login / claude
```

---

## Codex (ChatGPT OAuth)

**Terminal 1 — laptop:**

```bash
ssh -L 1455:127.0.0.1:1455 user@dev-server
# VPN/Tailscale: ssh -L 1455:127.0.0.1:1455 user@100.x.x.x
```

Keep this window open — the tunnel lives while SSH is connected.

**Terminal 2 — inside SSH on dev-server:**

```bash
codex login
# or retry if session expired:
codex logout && codex login
```

Open the URL from the terminal **on the laptop**. Redirect to `localhost:1455` goes through the tunnel.

Check:

```bash
codex login status
# Logged in using ChatGPT
```

### Codex without tunnel

```bash
codex login --device-auth
```

Or API key:

```bash
printenv OPENAI_API_KEY | codex login --with-api-key
```

---

## Claude Code (Anthropic OAuth)

Port may differ — check `claude` output during login.

**Laptop:**

```bash
ssh -L 1455:127.0.0.1:1455 user@dev-server
```

**dev-server:**

```bash
claude
claude auth status
```

### Claude without tunnel

```bash
export ANTHROPIC_API_KEY='sk-ant-...'
claude auth status
```

---

## Multiple ports

```bash
ssh -L 1455:127.0.0.1:1455 -L 3456:127.0.0.1:3456 user@dev-server
```

---

## ~/.ssh/config (optional)

```text
Host dev-server
  HostName dev.example.com
  User your-user
  LocalForward 1455 127.0.0.1:1455
  ServerAliveInterval 60
```

Then:

```bash
ssh dev-server
codex login   # on remote
```

Remove `LocalForward` when auth is done if port 1455 on the laptop stays busy.

---

## glab (GitLab) — no tunnel needed

`glab auth login` uses a PAT against the API, not a browser callback on localhost.

```bash
glab auth login --hostname gitlab.com
# or self-hosted:
glab auth login --hostname gitlab.example.com
```

---

## Checklist

| CLI | Tunnel | Alternative |
|-----|--------|-------------|
| **codex** | `ssh -L 1455:127.0.0.1:1455 …` | `--device-auth`, API key |
| **claude** | `-L <port>:127.0.0.1:<port>` | `ANTHROPIC_API_KEY` |
| **glab** | not needed | PAT in GitLab UI |

---

## Common errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| Browser `localhost:1455` connection refused | no tunnel | SSH with `-L` **before** login |
| Login on laptop, CLI still waiting | OAuth on laptop, CLI on remote | tunnel + login again |
| `Address already in use` on laptop | old SSH with LocalForward | `lsof -i :1455`, close session |
| Codex ok, Claude fails | different port | check redirect URL in browser |

See also: [tmux-cheatsheet.md](tmux-cheatsheet.md)
