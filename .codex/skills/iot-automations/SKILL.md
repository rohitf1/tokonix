---
name: iot-automations
description: Control IoT devices (Tuya/Smart Life) via Tuya Cloud API with simple on/off scripts.
---

# IoT Automations

## Output rules (Tokonix)

- Keep spoken responses short, friendly, and natural.
- Do not speak commands, file paths, URLs, or code. Put exact details in Simple Notes and only summarize verbally.
- Use Simple Notes only when it helps (commands, configs, long text, structured data).

## Default stack (recommended)

- Python 3.10+ using the standard library only.
- Tuya Cloud API (Smart Life compatible).
- Credentials provided via environment variables (never hardcode secrets).

## Setup (one-time)

- Create a workspace:
  - `scripts/setup_iot_automations_workspace.sh $CODEX_HOME/skill-workspaces/iot-automations <slug>`
- Edit `env.sh` inside the workspace to add your Tuya credentials.

## Run (recommended)

- Use the launcher:
  - `scripts/run_iot_automation.sh $CODEX_HOME/skill-workspaces/iot-automations <slug> status`
  - `scripts/run_iot_automation.sh $CODEX_HOME/skill-workspaces/iot-automations <slug> on`
  - `scripts/run_iot_automation.sh $CODEX_HOME/skill-workspaces/iot-automations <slug> off`
  - `scripts/run_iot_automation.sh $CODEX_HOME/skill-workspaces/iot-automations <slug> toggle`

## Quick shortcuts (inside the workspace)

- `./status.sh`
- `./on.sh`
- `./off.sh`
- `./toggle.sh`

## Agent guidance

- If the user asks for on/off, act immediately using the standard scripts.
- Use `status` first to discover the switch code (usually `switch_led`).
- If auto-detection fails, set `TUYA_SWITCH_CODE` in `env.sh`.
- Keep device credentials in the workspace only (never commit secrets).
- For India users, `TUYA_BASE_URL` should be `https://openapi.tuyain.com`.

## Alternatives

- Home Assistant + Tuya integration.
- Tuya local LAN (no cloud) if the device supports it.
