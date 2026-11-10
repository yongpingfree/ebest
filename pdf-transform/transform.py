#!/usr/bin/env python3
"""Password-protect a PDF and add a JavaScript expiry (default 24 hours).

Usage:
    python3 protect_pdf.py input.pdf "my password" [-o output.pdf] [--hours 24]
                           [--owner-password "owner secret"]

- The PDF is encrypted with AES-256. It can only be opened with the supplied
  password (the "user" password).
- The owner password is optional; if omitted, a random one is generated and
  printed once. It must differ from the user password. The user password is
  granted print-only permissions (no copy / modify / assemble / annotate).
- An open-action JavaScript records the expiry time. After it, the viewer shows
  a message in an endless loop (it cannot be dismissed), so the content can
  no longer be viewed.
- Owner exemption: when the file is opened with the OWNER password the script
  returns immediately: no message, no loop, no timer.
- One-way output: the output carries a protection marker. This script refuses
  to process a file that is encrypted or carries the marker, and it has no
  unlock / re-protect mode. The JavaScript also blocks the viewer if the file
  is no longer encrypted (i.e. someone stripped the password with another tool).

Limitations (inherent to PDF, not to this script):
- The JavaScript is only honoured by Adobe Acrobat / Reader. Browsers, Preview,
  and many other viewers ignore PDF JavaScript, so expiry is NOT enforced there.
- The check uses the viewer machine's clock. Anyone who knows the user password
  can decrypt the file with a third-party tool (qpdf, mutool...) or print it to
  a new PDF; permission flags are advisory. This is a soft control, not DRM.
  For hard expiry/no-download, serve the file from an access-controlled service.

Requires: pip install pypdf cryptography
"""
from __future__ import annotations

import argparse
import secrets
import string
import sys
import time
from pathlib import Path

try:
    import cryptography  # noqa: F401  (pypdf needs it for AES-256)
except ImportError:
    sys.exit("Missing dependency 'cryptography'. Run: pip install -r requirements.txt")

from pypdf import PdfReader, PdfWriter
from pypdf.constants import UserAccessPermissions


MARKER = "/EBestProtected"


def build_js(expiry_ms: int) -> str:
    """Open-action JS: once expired, show the message in an endless loop.

    The loop never exits, so the viewer cannot dismiss it and see the content.
    If a viewer suppresses app.alert (returns immediately), the loop busy-spins
    and freezes the viewer instead. A timer re-checks every 30 s so a document
    that was opened before expiry is also blocked when the deadline passes.

    Owner exemption: the user password is granted print-only permissions, so
    text extraction (getPageNthWord) throws NotAllowedError for a user-password
    session but succeeds when the file was opened with the owner password. In
    that case the script returns immediately: no message, no loop, no timer.
    Any failure of the probe is treated as "not owner", so the block fails safe.

    Tamper check: if the document is not encrypted (securityHandler is null) the
    password has been stripped, so it is treated as expired immediately and the
    owner exemption does not apply (an unencrypted copy would pass the probe).
    """
    loop_full = (
        "while(true){"
        "app.alert('This document has expired and can no longer be viewed.'"
        f"+'\\nCurrent time: '+new Date().toString()"
        f"+'\\nExpiry time: '+new Date({expiry_ms}).toString()"
        f"+' (expiry_ms={expiry_ms})'"
        "+'\\nViewer: '+app.viewerType+' '+app.viewerVersion+' / '+app.platform,1);"
        "}"
    )
    loop = (
        "while(true){"
        "app.alert('This document has expired and can no longer be viewed.'"
        "+'',1);"
        "}"
    ) 
    owner_probe = (
        "var isOwner=false;"
        "try{this.getPageNthWord(0,0,false);isOwner=true;}catch(e){}"
    )
    # Only Acrobat/Reader reliably implement securityHandler, so the tamper check
    # applies there only; every other viewer (browsers) gets the timestamp check alone.
    # Browsers' PDF viewers (PDFium) also report viewerType 'Reader' but have an empty
    # app.platform; real Acrobat always reports WIN / MAC / UNIX.
    acrobat = (
        "((app.viewerType=='Reader'||app.viewerType=='Exchange-Pro'||app.viewerType=='Exchange')"
        "&&(app.platform=='WIN'||app.platform=='MAC'||app.platform=='UNIX'))"
    )
    tampered = f"({acrobat}&&this.securityHandler==null)"
    check = f"if({tampered}||new Date().getTime()>{expiry_ms}){{{loop}}}"
    # Owner skips everything, but never when the file has been decrypted.
    return (
        owner_probe
        + f"if(!isOwner||{tampered}){{"
        + check
        + 'app.setInterval("' + check.replace('"', "'").replace("\\", "\\\\") + '",30000);'
        + "}"
    )


def _add_open_js(writer: PdfWriter, js: str) -> None:
    """Attach an open-action JavaScript (add_js was removed in pypdf 7)."""
    try:
        from pypdf.actions import JavaScript
    except ImportError:          # old pypdf without the actions module
        writer.add_js(js)
        return
    writer.add_open_action(JavaScript(js))


def protect(src: Path, dst: Path, password: str, hours: float,
            owner_password: str | None = None) -> tuple[str, int]:
    reader = PdfReader(str(src))
    if reader.is_encrypted:
        raise SystemExit("Input PDF is already encrypted; refusing to process it.")
    if MARKER in (reader.metadata or {}):
        raise SystemExit("Input PDF was already produced by this tool; refusing to process it again.")

    writer = PdfWriter(clone_from=reader)
    writer.add_metadata({MARKER: "1"})

    expiry_s = int(time.time() + hours * 3600)
    _add_open_js(writer, build_js(expiry_s * 1000))
    writer.add_metadata({"/ExpiresAt": time.strftime("%Y-%m-%dT%H:%M:%S%z", time.localtime(expiry_s))})

    if owner_password is None:
        alphabet = string.ascii_letters + string.digits
        owner_password = "".join(secrets.choice(alphabet) for _ in range(24))

    # Allow viewing and printing; block copy/modify/annotate.
    perms = UserAccessPermissions.PRINT | UserAccessPermissions.PRINT_TO_REPRESENTATION
    writer.encrypt(
        user_password=password,
        owner_password=owner_password,
        permissions_flag=perms,
        algorithm="AES-256",
    )

    with open(dst, "wb") as f:
        writer.write(f)
    return owner_password, expiry_s


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("pdf", type=Path, help="input PDF")
    ap.add_argument("password", help="password required to open the output PDF")
    ap.add_argument("-o", "--output", type=Path, help="output path (default: <name>_protected.pdf)")
    ap.add_argument("--hours", type=float, default=None, help="hours until expiry (default 24)")
    ap.add_argument("--owner-password", help="owner password (default: random, printed once)")
    args = ap.parse_args()

    if not args.pdf.is_file():
        sys.exit(f"File not found: {args.pdf}")
    if not args.password:
        sys.exit("Password must not be empty.")
    if args.hours is None:
        args.hours = 24
    if args.owner_password is not None:
        if not args.owner_password:
            sys.exit("Owner password must not be empty.")
        if args.owner_password == args.password:
            sys.exit("Owner password must differ from the user password.")
    out = args.output or args.pdf.with_name(args.pdf.stem + "_protected.pdf")
    if out.resolve() == args.pdf.resolve():
        sys.exit("Output must differ from input.")

    owner_pw, expiry = protect(args.pdf, out, args.password, args.hours, args.owner_password)
    print(f"Written:        {out}")
    print(f"Expires (JS):   {time.strftime('%Y-%m-%d %H:%M:%S %Z', time.localtime(expiry))}")
    if args.owner_password is None:
        print(f"Owner password: {owner_pw}  (generated)")
    else:
        print("Owner password: as supplied")
    print("Note: expiry is enforced only by Adobe Acrobat/Reader (see script docstring).")


if __name__ == "__main__":
    main()
