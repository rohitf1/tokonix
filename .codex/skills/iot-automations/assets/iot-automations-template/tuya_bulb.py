#!/usr/bin/env python3
import hashlib
import hmac
import json
import os
import sys
import time
import urllib.error
import urllib.request
from typing import Optional

DEFAULT_BASE_URL = "https://openapi.tuyain.com"


def _now_ms() -> str:
    return str(int(time.time() * 1000))


def _hmac_sha256_upper(secret: str, message: str) -> str:
    return hmac.new(secret.encode("utf-8"), message.encode("utf-8"), hashlib.sha256).hexdigest().upper()


def _sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _request(method: str, base_url: str, path: str, body=None, access_token: Optional[str] = None):
    client_id = os.environ.get("TUYA_ACCESS_ID", "").strip()
    client_secret = os.environ.get("TUYA_ACCESS_SECRET", "").strip()
    if not client_id or not client_secret:
        raise RuntimeError("TUYA_ACCESS_ID and TUYA_ACCESS_SECRET must be set")

    t = _now_ms()
    nonce = os.environ.get("TUYA_NONCE", "").strip()
    sign_version = os.environ.get("TUYA_SIGN_VERSION", "new").strip().lower()

    body_bytes = b""
    if body is not None:
        body_bytes = json.dumps(body, separators=(",", ":")).encode("utf-8")

    if sign_version == "simple":
        if access_token:
            sign_str = f"{client_id}{access_token}{t}"
        else:
            sign_str = f"{client_id}{t}"
    else:
        content_sha256 = _sha256_hex(body_bytes)
        string_to_sign = f"{method}\n{content_sha256}\n\n{path}"
        if access_token:
            sign_str = f"{client_id}{access_token}{t}{nonce}{string_to_sign}"
        else:
            sign_str = f"{client_id}{t}{nonce}{string_to_sign}"
    sign = _hmac_sha256_upper(client_secret, sign_str)

    headers = {
        "client_id": client_id,
        "t": t,
        "sign_method": "HMAC-SHA256",
        "sign": sign,
        "Content-Type": "application/json",
    }
    if nonce:
        headers["nonce"] = nonce
    if access_token:
        headers["access_token"] = access_token

    url = base_url.rstrip("/") + path
    data = body_bytes if body is not None else None

    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            payload = resp.read().decode("utf-8")
            return json.loads(payload)
    except urllib.error.HTTPError as err:
        payload = err.read().decode("utf-8") if err.fp else ""
        raise RuntimeError(f"HTTP {err.code}: {payload}") from err


def get_access_token(base_url: str) -> str:
    resp = _request("GET", base_url, "/v1.0/token?grant_type=1")
    if not resp.get("success"):
        raise RuntimeError(f"Token error: {resp}")
    return resp["result"]["access_token"]


def get_device_status(base_url: str, access_token: str, device_id: str):
    resp = _request("GET", base_url, f"/v1.0/devices/{device_id}/status", access_token=access_token)
    if not resp.get("success"):
        raise RuntimeError(f"Status error: {resp}")
    return resp["result"]


def resolve_switch_code(status_list, explicit_code: Optional[str]):
    if explicit_code:
        return explicit_code
    for item in status_list:
        code = item.get("code", "")
        if isinstance(item.get("value"), bool) and ("switch" in code or "power" in code):
            return code
    for item in status_list:
        if isinstance(item.get("value"), bool):
            return item.get("code")
    return None


def send_switch_command(base_url: str, access_token: str, device_id: str, code: str, value: bool):
    body = {"commands": [{"code": code, "value": value}]}
    resp = _request("POST", base_url, f"/v1.0/devices/{device_id}/commands", body=body, access_token=access_token)
    if not resp.get("success"):
        raise RuntimeError(f"Command error: {resp}")
    return resp


def usage():
    print("Usage: tuya_bulb.py [status|on|off|toggle]")


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in {"status", "on", "off", "toggle"}:
        usage()
        return 2

    base_url = os.environ.get("TUYA_BASE_URL", DEFAULT_BASE_URL)
    device_id = os.environ.get("TUYA_DEVICE_ID", "").strip()
    if not device_id:
        raise RuntimeError("TUYA_DEVICE_ID must be set")

    access_token = get_access_token(base_url)

    if sys.argv[1] == "status":
        status = get_device_status(base_url, access_token, device_id)
        print(json.dumps(status, indent=2))
        return 0

    status = get_device_status(base_url, access_token, device_id)
    explicit_code = os.environ.get("TUYA_SWITCH_CODE", "").strip() or None
    code = resolve_switch_code(status, explicit_code)
    if not code:
        raise RuntimeError("Could not auto-detect switch code. Set TUYA_SWITCH_CODE and retry.")

    current = None
    for item in status:
        if item.get("code") == code:
            current = item.get("value")
            break

    if sys.argv[1] == "toggle":
        if current is None:
            raise RuntimeError("Switch status not found for auto-toggle. Use on/off instead.")
        target = not bool(current)
    else:
        target = sys.argv[1] == "on"

    resp = send_switch_command(base_url, access_token, device_id, code, target)
    print(json.dumps(resp, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
