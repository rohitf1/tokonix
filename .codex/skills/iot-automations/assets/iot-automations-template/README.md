# IoT Automations Workspace

This workspace controls Tuya/Smart Life devices via Tuya Cloud.

## 1) Set credentials
Edit `env.sh` and fill in:
- `TUYA_ACCESS_ID`
- `TUYA_ACCESS_SECRET`
- `TUYA_DEVICE_ID`

For India data center, keep:
- `TUYA_BASE_URL=https://openapi.tuyain.com`

## 2) Run
```bash
source ./env.sh
python3 tuya_bulb.py status
python3 tuya_bulb.py on
python3 tuya_bulb.py off
python3 tuya_bulb.py toggle
```

If auto-detection fails, set `TUYA_SWITCH_CODE` in `env.sh` (often `switch_led`).

## Quick shortcuts

From the workspace directory:
```bash
./status.sh
./on.sh
./off.sh
./toggle.sh
```
