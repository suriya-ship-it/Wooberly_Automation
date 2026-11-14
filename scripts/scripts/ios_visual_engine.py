import asyncio
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional
from pymobiledevice3.remote import native_tunnel
from pymobiledevice3.services.accessibilityaudit import AccessibilityAudit
from pymobiledevice3.services.dvt.instruments.dvt_provider import DvtProvider
from pymobiledevice3.services.dvt.instruments.screenshot import Screenshot

DEFAULT_UDID = os.getenv("IOS_UDID", "00008120-00066C6C2144A01E")

async def get_rsd(udid: str = DEFAULT_UDID):
    return await native_tunnel.establish_native_rsd(serial=udid)

async def take_screenshot(output_path: str, udid: str = DEFAULT_UDID) -> bool:
    rsd = await get_rsd(udid)
    out_file = Path(output_path)
    out_file.parent.mkdir(parents=True, exist_ok=True)
    async with DvtProvider(rsd) as dvt, Screenshot(dvt) as screenshot:
        data = await screenshot.get_screenshot()
        out_file.write_bytes(data)
        print(f"[VisualEngine] Screenshot saved: {output_path} ({len(data)} bytes)")
        return True

async def list_elements(udid: str = DEFAULT_UDID) -> List[Dict[str, Any]]:
    rsd = await get_rsd(udid)
    elements = []
    try:
        async with AccessibilityAudit(rsd) as service:
            try:
                async for el in service.iter_elements():
                    d = el.to_dict()
                    caption = d.get("caption") or d.get("spoken_description") or ""
                    elements.append({
                        "caption": caption.strip(),
                        "id": d.get("platform_identifier"),
                        "estimated_uid": d.get("estimated_uid")
                    })
            except (TimeoutError, asyncio.TimeoutError):
                pass
    finally:
        try:
            await rsd.close()
        except:
            pass
    return elements

async def tap_element(pattern: str, udid: str = DEFAULT_UDID) -> bool:
    rsd = await get_rsd(udid)
    regex = re.compile(pattern, re.IGNORECASE)
    found = False
    try:
        async with AccessibilityAudit(rsd) as service:
            try:
                async for el in service.iter_elements():
                    caption = el.caption or el.spoken_description or ""
                    if regex.search(caption):
                        print(f"[VisualEngine] Found matching element for pattern '{pattern}': '{caption}'")
                        await service.perform_press(el.element.identifier)
                        print(f"[VisualEngine] Successfully activated: '{caption}'")
                        found = True
                        break
            except (TimeoutError, asyncio.TimeoutError):
                pass
    finally:
        try:
            await rsd.close()
        except:
            pass
    if not found:
        print(f"[VisualEngine] No matching element found for pattern: '{pattern}'")
    return found

async def handle_permissions(udid: str = DEFAULT_UDID) -> Dict[str, Any]:
    """
    Scans for iOS permission dialogs and automatically taps the accept button.
    Priority order:
    1. 'Allow While Using App' (Location permission)
    2. 'Allow' (Push notifications, Bluetooth, tracking)
    3. 'OK' (Standard system prompts)
    """
    rsd = await get_rsd(udid)
    permission_patterns = [
        r"Allow While Using App",
        r"While Using the App",
        r"\bAllow\b",
        r"\bOK\b",
        r"\bContinue\b"
    ]
    
    try:
        async with AccessibilityAudit(rsd) as service:
            matching_elements = []
            try:
                async for el in service.iter_elements():
                    caption = el.caption or el.spoken_description or ""
                    matching_elements.append((el, caption))
            except (TimeoutError, asyncio.TimeoutError):
                pass

            for pattern in permission_patterns:
                regex = re.compile(pattern, re.IGNORECASE)
                for el, caption in matching_elements:
                    clean = caption.replace("’", "'").lower()
                    # Do not tap 'Don't Allow' or 'Not Now'
                    if "don't allow" in clean or "not now" in clean or "deny" in clean:
                        continue
                    if regex.search(caption):
                        print(f"[VisualEngine] Detected system permission / action prompt: '{caption}'")
                        await service.perform_press(el.element.identifier)
                        print(f"[VisualEngine] Permission prompt dismissed: '{caption}'")
                        return {"handled": True, "action": caption}
    finally:
        try:
            await rsd.close()
        except:
            pass

    return {"handled": False, "action": None}

async def hold_awake(duration_sec: int = 1800, udid: str = DEFAULT_UDID):
    from pymobiledevice3.services.power_assertion import PowerAssertionService
    rsd = await get_rsd(udid)
    try:
        pas = PowerAssertionService(rsd)
        async with pas.create_power_assertion("PreventUserIdleDisplaySleep", "WooberlyAutomation", float(duration_sec)):
            print(f"[VisualEngine] Power assertion active for {duration_sec}s (screen keep-awake enabled)")
            sys.stdout.flush()
            await asyncio.sleep(duration_sec)
    finally:
        try:
            await rsd.close()
        except:
            pass

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 ios_visual_engine.py <screenshot|list|tap|permissions|keep_awake> [args]")
        sys.exit(1)

    cmd = sys.argv[1]
    udid = os.getenv("IOS_UDID", DEFAULT_UDID)

    if cmd == "screenshot":
        if len(sys.argv) < 3:
            print("Usage: screenshot <output_path>")
            sys.exit(1)
        ok = asyncio.run(take_screenshot(sys.argv[2], udid))
        sys.exit(0 if ok else 1)

    elif cmd == "list":
        elements = asyncio.run(list_elements(udid))
        print(json.dumps(elements, indent=2))
        sys.exit(0)

    elif cmd == "tap":
        if len(sys.argv) < 3:
            print("Usage: tap <caption_regex>")
            sys.exit(1)
        ok = asyncio.run(tap_element(sys.argv[2], udid))
        sys.exit(0 if ok else 1)

    elif cmd == "permissions":
        res = asyncio.run(handle_permissions(udid))
        print(json.dumps(res))
        sys.exit(0 if res["handled"] else 1)

    elif cmd == "keep_awake":
        duration = int(sys.argv[2]) if len(sys.argv) > 2 else 1800
        asyncio.run(hold_awake(duration, udid))
        sys.exit(0)

    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == "__main__":
    main()
