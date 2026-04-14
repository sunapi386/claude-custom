# claude-custom

A tiny wrapper around the [Claude Code](https://github.com/anthropics/claude-code) CLI that lets you save and switch between **Anthropic-compatible endpoints** — so you can point `claude` at Z.ai (GLM), a self-hosted gateway, a corporate proxy, or any other API that speaks the Anthropic Messages protocol.

Interactive menu picks a saved profile or creates a new one, sets the right env vars, and execs `claude`.

## Why

`claude` already supports custom endpoints via these env vars:

```sh
ANTHROPIC_BASE_URL
ANTHROPIC_AUTH_TOKEN
ANTHROPIC_MODEL
ANTHROPIC_SMALL_FAST_MODEL
```

…but juggling them across several providers (Anthropic direct, Z.ai/GLM, a lab gateway, etc.) is painful. This script keeps each combo as a named profile on disk.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/sunapi386/claude-custom/main/claude-custom \
  -o ~/.local/bin/claude-custom
chmod +x ~/.local/bin/claude-custom
```

Make sure `~/.local/bin` is on your `PATH`, and that `claude` itself is installed.

## Usage

### First run — create a profile

A profile bundles **one endpoint + one API key + a list of models** the provider exposes. You pick a default; the rest are still available at launch time.

```sh
$ claude-custom
no profiles yet — let's create one
profile name (e.g. zai): zai
endpoint / ANTHROPIC_BASE_URL [https://api.z.ai/api/anthropic]:
api key / ANTHROPIC_AUTH_TOKEN: ********
models (comma-separated) [glm-4.6]: glm-4.6, glm-4.5, glm-4.6-air
default model [glm-4.6]:
small/fast model [glm-4.6]:
saved profile → ~/.config/claude-custom/profiles/zai.env
```

### Pick a saved profile (and a model)

If a profile has more than one model, you'll get a second picker. The `*` marks the profile's default — hit enter to accept it, or pick another by number.

```sh
$ claude-custom

claude-custom — pick a profile
   1) zai           [glm-4.6,glm-4.5,glm-4.6-air]    https://api.z.ai/api/anthropic
   2) anthropic     [claude-sonnet-4-6,claude-opus-4-6]  https://api.anthropic.com
   3) [new profile]
   4) [delete profile]

choice: 1

pick a model
   1)* glm-4.6
   2)  glm-4.5
   3)  glm-4.6-air

choice [default: glm-4.6]: 2
→ https://api.z.ai/api/anthropic  model=glm-4.5
```

### Non-interactive — pass profile (and optionally model) directly

```sh
claude-custom zai                          # uses default model (or prompts if >1 + no choice)
claude-custom zai --model glm-4.5          # explicit model from the profile's list
claude-custom zai --model glm-4.5 "go"     # extra args forwarded to claude
```

### Manage profiles

```sh
claude-custom --list          # list profile names
claude-custom --new           # create a new profile, don't launch
claude-custom --show zai      # print profile (api key masked)
claude-custom --delete zai    # delete a profile
claude-custom --help
```

## Profile storage

Profiles are plain shell-sourceable files at:

```
$XDG_CONFIG_HOME/claude-custom/profiles/<name>.env
# defaults to ~/.config/claude-custom/profiles/
```

Example `zai.env`:

```sh
BASE_URL=https://api.z.ai/api/anthropic
AUTH_TOKEN=sk-...
MODELS=glm-4.6,glm-4.5,glm-4.6-air
DEFAULT_MODEL=glm-4.6
SMALL_FAST_MODEL=glm-4.6
```

The config dir and files are created with `0700` / `0600` permissions so your keys aren't world-readable. Legacy single-model profiles using `MODEL=...` are still supported.

## Example providers

| Provider    | `BASE_URL`                              | Example models                       |
|-------------|-----------------------------------------|--------------------------------------|
| Anthropic   | `https://api.anthropic.com`             | `claude-sonnet-4-6,claude-opus-4-6`  |
| Z.ai (GLM)  | `https://api.z.ai/api/anthropic`        | `glm-4.6,glm-4.5,glm-4.6-air`        |
| BigModel    | `https://open.bigmodel.cn/api/anthropic`| `glm-4.6,glm-4.5`                    |

Providers that only expose an **OpenAI-format** API (OpenRouter, SiliconFlow, most aggregators) won't work directly — you'd need a translation proxy like [`claude-code-router`](https://github.com/musistudio/claude-code-router) in front of them, and then point `claude-custom` at the proxy's Anthropic-compatible URL.

## License

MIT
