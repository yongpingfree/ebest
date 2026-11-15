#!/usr/bin/env python3
"""Password-protect a PDF or Excel file and add an expiry (default 24 hours).

The file type is chosen by the input suffix:
    .pdf            -> AES-256 encrypted PDF with a JavaScript expiry (below)
    .xlsx / .xls    -> password-protected macro-enabled workbook (.xlsm) with a
                       VBA expiry (see "Excel" at the end of this docstring)

Usage:
    python3 transform.py input.pdf "my password" [-o output.pdf] [--hours 24]
                         [--owner-password "owner secret"]
    python3 transform.py input.xlsx "my password" -o output.xlsm [--hours 24]

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

Excel (.xlsx / .xls):
- The workbook is converted to a macro-enabled workbook (.xlsm; the output name
  must end in .xlsm because Excel refuses macros inside a .xlsx) holding a
  Workbook_Open macro with the expiry time. After expiry it shows a message and
  closes the workbook without saving; a 30 s timer re-checks while it is open.
- The package is encrypted with the standard Office "Agile" encryption
  (AES-256, SHA-512) using the password; Excel asks for it on open.
- The owner password is accepted for CLI compatibility but has no Excel meaning.
- .xls input is converted to .xlsx first with LibreOffice (soffice) if installed.
- Limitations: the expiry only works when the user enables macros, uses the
  viewer machine's clock (wall time of the server's timezone), and is not
  enforced by non-Excel viewers. Soft control, not DRM.

Requires: pip install pypdf cryptography
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import hmac
import io
import os
import re
import secrets
import shutil
import string
import struct
import subprocess
import sys
import tempfile
import time
import uuid
import zipfile
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


# ============================================================================
# Excel support: VBA expiry project + Office Agile encryption
# ============================================================================

# ---- MS-OVBA compression (MS-OVBA 2.4.1) -----------------------------------

def _ovba_compress(data: bytes) -> bytes:
    out = bytearray(b"\x01")
    pos = 0
    while True:
        chunk = data[pos:pos + 4096]
        pos += 4096
        tokens = bytearray()
        i = 0
        while i < len(chunk):
            flag_at = len(tokens)
            tokens.append(0)
            flags = 0
            for bit in range(8):
                if i >= len(chunk):
                    break
                bit_count = max((i - 1).bit_length(), 4) if i > 0 else 4
                max_len = (0xFFFF >> bit_count) + 3
                best_len = best_off = 0
                for off in range(1, i + 1):
                    n = 0
                    while (n < max_len and i + n < len(chunk)
                           and chunk[i + n - off] == chunk[i + n]):
                        n += 1
                    if n > best_len:
                        best_len, best_off = n, off
                if best_len >= 3:
                    tok = ((best_off - 1) << (16 - bit_count)) | (best_len - 3)
                    tokens += struct.pack("<H", tok)
                    flags |= 1 << bit
                    i += best_len
                else:
                    tokens.append(chunk[i])
                    i += 1
            tokens[flag_at] = flags
        if len(tokens) > 4096:   # not smaller: store raw, padded to 4096
            out += struct.pack("<H", 0x3FFF) + chunk.ljust(4096, b"\x00")
        else:
            out += struct.pack("<H", ((len(tokens) + 2 - 3) & 0xFFF) | 0xB000) + tokens
        if pos >= len(data):
            break
    return bytes(out)


def _ovba_decompress(blob: bytes) -> bytes:
    """Inverse of _ovba_compress (used by the self-test)."""
    assert blob[0] == 1
    out = bytearray()
    p = 1
    while p < len(blob):
        hdr = struct.unpack_from("<H", blob, p)[0]
        size = (hdr & 0xFFF) + 3
        end = p + size
        p += 2
        start = len(out)
        if hdr & 0x8000:
            while p < end:
                flags = blob[p]
                p += 1
                for bit in range(8):
                    if p >= end:
                        break
                    if flags >> bit & 1:
                        tok = struct.unpack_from("<H", blob, p)[0]
                        p += 2
                        bit_count = max((len(out) - start - 1).bit_length(), 4) if len(out) > start else 4
                        off = (tok >> (16 - bit_count)) + 1
                        ln = (tok & (0xFFFF >> bit_count)) + 3
                        for _ in range(ln):
                            out.append(out[-off])
                    else:
                        out.append(blob[p])
                        p += 1
        else:
            out += blob[p:p + 4096]
            p += 4096
    return bytes(out)


# ---- Compound File Binary writer (MS-CFB, version 3) ------------------------

_FREE, _END, _FATSECT, _DIFSECT = 0xFFFFFFFF, 0xFFFFFFFE, 0xFFFFFFFD, 0xFFFFFFFC


def _cfb_key(name: str):
    return (len(name), name.upper())


class _CfbNode:
    def __init__(self, name, data=None):
        self.name = name
        self.data = data            # bytes for streams, None for storages
        self.children = []
        self.start = _END
        self.id = 0


def _cfb_write(root: _CfbNode) -> bytes:
    """Serialise a tree of _CfbNode (root = storage) into a CFB file."""
    nodes = [root]

    def walk(n):
        for c in sorted(n.children, key=lambda c: _cfb_key(c.name)):
            nodes.append(c)
            if c.data is None:
                walk(c)
    walk(root)
    for i, n in enumerate(nodes):
        n.id = i

    # --- mini stream (streams < 4096 bytes) -------------------------------
    ministream = bytearray()
    minifat = []
    for n in nodes[1:]:
        if n.data is not None and 0 < len(n.data) < 4096:
            n.start = len(ministream) // 64
            cnt = -(-len(n.data) // 64)
            minifat += list(range(n.start + 1, n.start + cnt)) + [_END]
            ministream += n.data.ljust(cnt * 64, b"\x00")

    def sectors(nbytes):
        return -(-nbytes // 512)

    n_dir = sectors(len(nodes) * 128)
    n_minifat = sectors(len(minifat) * 4)
    n_mini = sectors(len(ministream))
    big = [n for n in nodes[1:] if n.data is not None and len(n.data) >= 4096]
    n_big = sum(sectors(len(n.data)) for n in big)
    n_data = n_dir + n_minifat + n_mini + n_big

    n_fat = n_difat = 0
    while True:
        need_fat = -(-(n_data + n_fat + n_difat) // 128)
        need_difat = -(-(need_fat - 109) // 127) if need_fat > 109 else 0
        if need_fat == n_fat and need_difat == n_difat:
            break
        n_fat, n_difat = need_fat, need_difat

    fat = []
    def alloc(count):
        first = len(fat)
        for k in range(count):
            fat.append(len(fat) + 1 if k < count - 1 else _END)
        return first if count else _END

    dir_start = alloc(n_dir)
    minifat_start = alloc(n_minifat)
    root.start = alloc(n_mini)
    for n in big:
        n.start = alloc(sectors(len(n.data)))
    fat_start = len(fat)
    fat += [_FATSECT] * n_fat
    difat_start = len(fat) if n_difat else _END
    fat += [_DIFSECT] * n_difat
    fat += [_FREE] * (n_fat * 128 - len(fat))

    # --- directory ---------------------------------------------------------
    def siblings(parent):
        kids = sorted(parent.children, key=lambda c: _cfb_key(c.name))
        for a, b in zip(kids, kids[1:]):
            a.right = b.id
        return kids

    for n in nodes:
        n.left = n.right = _FREE
        n.child = _FREE
    for n in nodes:
        if n.data is None and n.children:
            kids = siblings(n)
            n.child = kids[0].id
    dirbuf = bytearray()
    for n in nodes:
        nm = n.name.encode("utf-16-le")
        typ = 5 if n is root else (1 if n.data is None else 2)
        if n is root:
            size, start = len(ministream), (root.start if n_mini else _END)
        elif n.data is None:
            size, start = 0, 0
        else:
            size, start = len(n.data), (n.start if n.data else _END)
        dirbuf += nm.ljust(64, b"\x00") + struct.pack(
            "<HBBIII16sIQQIII", len(nm) + 2, typ, 1, n.left, n.right, n.child,
            b"\x00" * 16, 0, 0, 0, start, size, 0)
    dirbuf = dirbuf.ljust(n_dir * 512, b"\x00")
    # unused trailing entries must be marked free (type 0, links = FREE)
    for k in range(len(nodes), n_dir * 4):
        o = k * 128
        dirbuf[o + 68:o + 76] = struct.pack("<II", _FREE, _FREE)
        dirbuf[o + 76:o + 80] = struct.pack("<I", _FREE)

    minifat_buf = struct.pack(f"<{len(minifat)}I", *minifat).ljust(n_minifat * 512, b"\xff")
    fat_buf = struct.pack(f"<{len(fat)}I", *fat)

    # --- header + DIFAT ----------------------------------------------------
    fat_ids = list(range(fat_start, fat_start + n_fat))
    header_difat = (fat_ids[:109] + [_FREE] * 109)[:109]
    header = (b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1" + b"\x00" * 16
              + struct.pack("<HHHHH6sIIIIIIIII", 0x3E, 3, 0xFFFE, 9, 6, b"\x00" * 6,
                            0, n_fat, dir_start, 0, 4096, minifat_start if n_minifat else _END,
                            n_minifat, difat_start, n_difat)
              + struct.pack("<109I", *header_difat))
    difat_buf = bytearray()
    rest = fat_ids[109:]
    for k in range(n_difat):
        part = rest[k * 127:(k + 1) * 127]
        nxt = (difat_start + k + 1) if k < n_difat - 1 else _END
        difat_buf += struct.pack("<127I", *(part + [_FREE] * (127 - len(part)))) + struct.pack("<I", nxt)

    body = bytearray(dirbuf) + minifat_buf + bytes(ministream).ljust(n_mini * 512, b"\x00")
    for n in big:
        body += n.data.ljust(sectors(len(n.data)) * 512, b"\x00")
    body += fat_buf + bytes(difat_buf)
    return bytes(header) + bytes(body)


# ---- VBA project (MS-OVBA / MS-OVBA 2.3) ------------------------------------

def _rec(rid: int, payload: bytes) -> bytes:
    return struct.pack("<HI", rid, len(payload)) + payload


def _vba_source(expiry_s: int) -> str:
    t = time.localtime(expiry_s)
    when = f"DateSerial({t.tm_year}, {t.tm_mon}, {t.tm_mday}) + TimeSerial({t.tm_hour}, {t.tm_min}, {t.tm_sec})"
    lines = [
        'Attribute VB_Name = "ThisWorkbook"',
        'Attribute VB_Base = "0{00020819-0000-0000-C000-000000000046}"',
        "Attribute VB_GlobalNameSpace = False",
        "Attribute VB_Creatable = False",
        "Attribute VB_PredeclaredId = True",
        "Attribute VB_Exposed = True",
        "Attribute VB_TemplateDerived = False",
        "Attribute VB_Customizable = True",
        "Option Explicit",
        "",
        "Public Sub EbestCheckExpiry()",
        f"    If Now > {when} Then",
        "        MsgBox \"This document has expired and can no longer be viewed.\", vbCritical, \"eBest\"",
        "        ThisWorkbook.Close SaveChanges:=False",
        "    Else",
        "        Application.OnTime Now + TimeSerial(0, 0, 30), \"ThisWorkbook.EbestCheckExpiry\"",
        "    End If",
        "End Sub",
        "",
        "Private Sub Workbook_Open()",
        "    EbestCheckExpiry",
        "End Sub",
        "",
    ]
    return "\r\n".join(lines)


def _build_vba_project(expiry_s: int) -> bytes:
    name = b"VBAProject"
    mod = b"ThisWorkbook"
    u = lambda b: b.decode("ascii").encode("utf-16-le")
    stdole = b"*\\G{00020430-0000-0000-C000-000000000046}#2.0#0#C:\\Windows\\System32\\stdole2.tlb#OLE Automation"

    d = b""
    d += _rec(0x0001, struct.pack("<I", 1))                 # SYSKIND: Win32
    d += _rec(0x0002, struct.pack("<I", 0x409))             # LCID
    d += _rec(0x0014, struct.pack("<I", 0x409))             # LCIDINVOKE
    d += _rec(0x0003, struct.pack("<H", 1252))              # CODEPAGE
    d += _rec(0x0004, name)                                 # NAME
    d += _rec(0x0005, b"") + _rec(0x0040, b"")              # DOCSTRING
    d += _rec(0x0006, b"") + _rec(0x003D, b"")              # HELPFILE
    d += _rec(0x0007, struct.pack("<I", 0))                 # HELPCONTEXT
    d += _rec(0x0008, struct.pack("<I", 0))                 # LIBFLAGS
    d += struct.pack("<HIIH", 0x0009, 4, 1, 0)              # VERSION (major, minor)
    d += _rec(0x000C, b"") + _rec(0x003C, b"")              # CONSTANTS
    # reference: stdole (registered)
    libid = struct.pack("<I", len(stdole)) + stdole + struct.pack("<IH", 0, 0)
    d += _rec(0x000D, libid)
    d += _rec(0x000F, struct.pack("<H", 1))                 # MODULES count
    d += _rec(0x0013, struct.pack("<H", 0xFFFF))            # COOKIE
    d += _rec(0x0019, mod)                                  # MODULENAME
    d += _rec(0x0047, u(mod))                               # MODULENAMEUNICODE
    d += _rec(0x001A, mod) + _rec(0x0032, u(mod))           # MODULESTREAMNAME
    d += _rec(0x001C, b"") + _rec(0x0048, b"")              # MODULEDOCSTRING
    d += _rec(0x0031, struct.pack("<I", 0))                 # MODULEOFFSET (no perf cache)
    d += _rec(0x001E, struct.pack("<I", 0))                 # MODULEHELPCONTEXT
    d += _rec(0x002C, struct.pack("<H", 0xFFFF))            # MODULECOOKIE
    d += _rec(0x0022, b"")                                  # MODULETYPE: document
    d += _rec(0x002B, b"")                                  # module terminator
    d += _rec(0x0010, b"")                                  # dir terminator

    project = (
        'ID="{%s}"\r\n' % str(uuid.uuid4()).upper()
        + "Document=ThisWorkbook/&H00000000\r\n"
        + 'Name="VBAProject"\r\n'
        + 'HelpContextID="0"\r\n'
        + 'VersionCompatible32="393222000"\r\n'
        + "\r\n[Host Extender Info]\r\n"
        + "&H00000001={3832D640-CF90-11CF-8E43-00A0C911005A};VBE;&H00000000\r\n"
        + "\r\n[Workspace]\r\n"
        + "ThisWorkbook=0, 0, 0, 0, C\r\n"
    ).encode("ascii")
    projectwm = mod + b"\x00" + u(mod) + b"\x00\x00" + b"\x00\x00"

    vba = _CfbNode("VBA")
    vba.children = [
        _CfbNode("dir", _ovba_compress(d)),
        _CfbNode("_VBA_PROJECT", b"\xcc\x61\xff\xff\x00\x00\x00"),
        _CfbNode("ThisWorkbook", _ovba_compress(_vba_source(expiry_s).encode("cp1252"))),
    ]
    root = _CfbNode("Root Entry")
    root.children = [vba, _CfbNode("PROJECT", project), _CfbNode("PROJECTwm", projectwm)]
    return _cfb_write(root)


# ---- Make the .xlsx macro-enabled -------------------------------------------

def _make_macro_workbook(src_xlsx: Path, vba_bin: bytes) -> bytes:
    out = io.BytesIO()
    with zipfile.ZipFile(src_xlsx) as zin, zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zout:
        names = zin.namelist()
        if "xl/workbook.xml" not in names:
            raise SystemExit("Not a valid .xlsx workbook (xl/workbook.xml missing).")
        if "xl/vbaProject.bin" in names:
            raise SystemExit("Input workbook already contains macros; refusing to process it.")
        for info in zin.infolist():
            data = zin.read(info.filename)
            fn = info.filename
            if fn == "[Content_Types].xml":
                t = data.decode("utf-8")
                t = t.replace("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml",
                              "application/vnd.ms-excel.sheet.macroEnabled.main+xml")
                if 'Extension="bin"' not in t:
                    t = re.sub(r"(<Types[^>]*>)", r'\1<Default Extension="bin" ContentType="application/vnd.ms-office.vbaProject"/>', t, count=1)
                data = t.encode("utf-8")
            elif fn == "xl/_rels/workbook.xml.rels":
                t = data.decode("utf-8")
                rel = ('<Relationship Id="rIdEbestVba" Type="http://schemas.microsoft.com/office/2006/'
                       'relationships/vbaProject" Target="vbaProject.bin"/>')
                t = t.replace("</Relationships>", rel + "</Relationships>")
                data = t.encode("utf-8")
            elif fn == "xl/workbook.xml":
                t = data.decode("utf-8")
                if "<workbookPr" in t:
                    if "codeName=" in t.split("<workbookPr", 1)[1].split(">", 1)[0]:
                        t = re.sub(r'(<workbookPr[^>]*?)codeName="[^"]*"', r'\1codeName="ThisWorkbook"', t, count=1)
                    else:
                        t = t.replace("<workbookPr", '<workbookPr codeName="ThisWorkbook"', 1)
                else:
                    m = re.search(r"<fileVersion[^>]*/>|<fileSharing[^>]*/>", t)
                    tag = '<workbookPr codeName="ThisWorkbook"/>'
                    if m:
                        t = t[:m.end()] + tag + t[m.end():]
                    else:
                        t = re.sub(r"(<workbook\b[^>]*[^/]>)", r"\1" + tag, t, count=1)
                data = t.encode("utf-8")
            elif re.match(r"xl/(worksheets|chartsheets|dialogsheets)/[^/]+\.xml$", fn):
                # sheet code modules are not part of the new project
                data = re.sub(rb'(<sheetPr\b[^>]*?)\s+codeName="[^"]*"', rb"\1", data, count=1)
            zout.writestr(info, data)
        zout.writestr("xl/vbaProject.bin", vba_bin)
    return out.getvalue()


# ---- Office "Agile" encryption (MS-OFFCRYPTO 2.3.4.10-2.3.4.13) --------------

_KEY_BITS = 256
_SPIN = 100000


def _aes_cbc(key: bytes, iv: bytes, data: bytes, decrypt: bool = False) -> bytes:
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    c = Cipher(algorithms.AES(key), modes.CBC(iv))
    op = c.decryptor() if decrypt else c.encryptor()
    return op.update(data) + op.finalize()


def _pad(b: bytes, n: int, fill: bytes = b"\x36") -> bytes:
    return b[:n] if len(b) >= n else b + fill * (n - len(b))


def _derive(password: str, salt: bytes, block_key: bytes) -> bytes:
    h = hashlib.sha512(salt + password.encode("utf-16-le")).digest()
    for i in range(_SPIN):
        h = hashlib.sha512(struct.pack("<I", i) + h).digest()
    return _pad(hashlib.sha512(h + block_key).digest(), _KEY_BITS // 8)


def _lp(s: str) -> bytes:
    """UNICODE-LP-P4: length, UTF-16LE text, padded to 4 bytes."""
    b = s.encode("utf-16-le")
    return struct.pack("<I", len(b)) + b + b"\x00" * (-len(b) % 4)


def _encrypt_package(package: bytes, password: str) -> bytes:
    b64 = lambda b: base64.b64encode(b).decode()
    key_salt = secrets.token_bytes(16)
    pw_salt = secrets.token_bytes(16)
    inter_key = secrets.token_bytes(_KEY_BITS // 8)

    # encrypted package: 8-byte size + AES-CBC per 4096-byte segment
    enc = bytearray(struct.pack("<Q", len(package)))
    for i in range(0, len(package), 4096):
        seg = package[i:i + 4096]
        iv = hashlib.sha512(key_salt + struct.pack("<I", i // 4096)).digest()[:16]
        enc += _aes_cbc(inter_key, iv, seg.ljust(-(-len(seg) // 16) * 16, b"\x00"))

    # password key encryptor
    verifier = secrets.token_bytes(16)
    enc_ver_in = _aes_cbc(_derive(password, pw_salt, bytes.fromhex("fea7d2763b4b9e79")), pw_salt, verifier)
    enc_ver_val = _aes_cbc(_derive(password, pw_salt, bytes.fromhex("d7aa0f6d3061344e")), pw_salt,
                           hashlib.sha512(verifier).digest())
    enc_key = _aes_cbc(_derive(password, pw_salt, bytes.fromhex("146e0be7abacd0d6")), pw_salt, inter_key)

    # data integrity (HMAC-SHA512 over the whole EncryptedPackage stream)
    hmac_key = secrets.token_bytes(64)
    hmac_val = hmac.new(hmac_key, bytes(enc), hashlib.sha512).digest()
    iv1 = hashlib.sha512(key_salt + bytes.fromhex("5fb2ad010cb9e1f6")).digest()[:16]
    iv2 = hashlib.sha512(key_salt + bytes.fromhex("a0677f02b22c8433")).digest()[:16]
    enc_hmac_key = _aes_cbc(inter_key, iv1, hmac_key)
    enc_hmac_val = _aes_cbc(inter_key, iv2, hmac_val)

    xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n'
        '<encryption xmlns="http://schemas.microsoft.com/office/2006/encryption" '
        'xmlns:p="http://schemas.microsoft.com/office/2006/keyEncryptor/password" '
        'xmlns:c="http://schemas.microsoft.com/office/2006/keyEncryptor/certificate">'
        f'<keyData saltSize="16" blockSize="16" keyBits="{_KEY_BITS}" hashSize="64" cipherAlgorithm="AES" '
        f'cipherChaining="ChainingModeCBC" hashAlgorithm="SHA512" saltValue="{b64(key_salt)}"/>'
        f'<dataIntegrity encryptedHmacKey="{b64(enc_hmac_key)}" encryptedHmacValue="{b64(enc_hmac_val)}"/>'
        '<keyEncryptors><keyEncryptor uri="http://schemas.microsoft.com/office/2006/keyEncryptor/password">'
        f'<p:encryptedKey spinCount="{_SPIN}" saltSize="16" blockSize="16" keyBits="{_KEY_BITS}" hashSize="64" '
        'cipherAlgorithm="AES" cipherChaining="ChainingModeCBC" hashAlgorithm="SHA512" '
        f'saltValue="{b64(pw_salt)}" encryptedVerifierHashInput="{b64(enc_ver_in)}" '
        f'encryptedVerifierHashValue="{b64(enc_ver_val)}" encryptedKeyValue="{b64(enc_key)}"/>'
        "</keyEncryptor></keyEncryptors></encryption>"
    )
    enc_info = struct.pack("<HHI", 4, 4, 0x40) + xml.encode("utf-8")

    # \x06DataSpaces (fixed structure, MS-OFFCRYPTO 2.3.4.x)
    ver = (lambda v: struct.pack("<HH", *v))((1, 0))
    version = _lp("Microsoft.Container.DataSpaces") + ver * 3
    ref = struct.pack("<I", 0) + _lp("EncryptedPackage") + _lp("StrongEncryptionDataSpace")
    entry = struct.pack("<II", 8 + len(ref), 1) + ref
    data_space_map = struct.pack("<II", 8, 1) + entry
    ds_info = struct.pack("<II", 8, 1) + _lp("StrongEncryptionTransform")
    transform_hdr = struct.pack("<II", 0, 1) + _lp("{FF9A3F03-56EF-4613-BDD5-5A41C1D07246}")
    transform_hdr = struct.pack("<I", len(transform_hdr)) + transform_hdr[4:]
    # TransformInfoHeader (length covers up to the end of TransformID), name, versions,
    # then EncryptionTransformInfo: empty name, block size 0, cipher mode 0, reserved 4
    primary = (transform_hdr + _lp("Microsoft.Container.EncryptionTransform") + ver * 3
               + _lp("") + struct.pack("<III", 0, 0, 4))

    dspaces = _CfbNode("\x06DataSpaces")
    dspaces.children = [
        _CfbNode("Version", version),
        _CfbNode("DataSpaceMap", data_space_map),
    ]
    dsi = _CfbNode("DataSpaceInfo")
    dsi.children = [_CfbNode("StrongEncryptionDataSpace", ds_info)]
    ti = _CfbNode("TransformInfo")
    st = _CfbNode("StrongEncryptionTransform")
    st.children = [_CfbNode("\x06Primary", primary)]
    ti.children = [st]
    dspaces.children += [dsi, ti]

    root = _CfbNode("Root Entry")
    root.children = [_CfbNode("EncryptionInfo", enc_info), _CfbNode("EncryptedPackage", bytes(enc)), dspaces]
    return _cfb_write(root)


def _soffice_to_xlsx(src: Path, workdir: Path) -> Path:
    exe = shutil.which("soffice") or shutil.which("libreoffice")
    if not exe:
        raise SystemExit("Cannot process .xls: LibreOffice (soffice) is not installed. Save the file as .xlsx and upload again.")
    r = subprocess.run([exe, "--headless", "--convert-to", "xlsx", "--outdir", str(workdir), str(src)],
                       capture_output=True, text=True, timeout=300)
    out = workdir / (src.stem + ".xlsx")
    if r.returncode != 0 or not out.is_file():
        raise SystemExit(f"LibreOffice could not convert the .xls file: {r.stderr.strip() or r.stdout.strip()}")
    return out


def protect_excel(src: Path, dst: Path, password: str, hours: float) -> int:
    if dst.suffix.lower() != ".xlsm":
        raise SystemExit("Excel output must end with .xlsm (macros cannot live in a .xlsx).")
    with open(src, "rb") as f:
        if f.read(8) == b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1" and src.suffix.lower() != ".xls":
            raise SystemExit("Input workbook is already encrypted; refusing to process it.")
    with tempfile.TemporaryDirectory() as tmp:
        work = src
        if src.suffix.lower() == ".xls":
            work = _soffice_to_xlsx(src, Path(tmp))
        if not zipfile.is_zipfile(work):
            raise SystemExit("Input is not a valid .xlsx workbook.")
        expiry_s = int(time.time() + hours * 3600)
        pkg = _make_macro_workbook(work, _build_vba_project(expiry_s))
    with open(dst, "wb") as f:
        f.write(_encrypt_package(pkg, password))
    return expiry_s


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("pdf", type=Path, help="input file (.pdf, .xlsx or .xls)")
    ap.add_argument("password", help="password required to open the output file")
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
    suffix = args.pdf.suffix.lower()
    if suffix not in (".pdf", ".xlsx", ".xls"):
        sys.exit(f"Unsupported file type '{suffix}'. Supported: .pdf, .xlsx, .xls")
    is_excel = suffix != ".pdf"
    default_ext = ".xlsm" if is_excel else ".pdf"
    out = args.output or args.pdf.with_name(args.pdf.stem + "_protected" + default_ext)
    if out.resolve() == args.pdf.resolve():
        sys.exit("Output must differ from input.")

    if is_excel:
        expiry = protect_excel(args.pdf, out, args.password, args.hours)
        print(f"Written:        {out}")
        print(f"Expires (VBA):  {time.strftime('%Y-%m-%d %H:%M:%S %Z', time.localtime(expiry))}")
        print("Note: Excel expiry needs macros enabled (see script docstring).")
        return

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
