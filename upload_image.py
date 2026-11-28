#!/usr/bin/env python3
"""Upload a local image to the eBest S3 bucket, the same way OMS does.

Usage:
    python3 upload_image.py /path/to/photo.jpg --bucket <bucket>
    S3_BUCKET=<bucket> python3 upload_image.py photo.jpg

The object key is  images/<random uuid>-<file name>  and the object is uploaded
with ACL public-read and the file's content type. The CDN URL is printed on
stdout (nothing else is printed there, so it can be captured in a script).

AWS credentials are NOT handled here. boto3 reads them from the usual places
(AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY environment variables, or the
profile created by `aws configure`).

Requires: pip install boto3
"""
from __future__ import annotations

import argparse
import mimetypes
import os
import sys
import uuid
from pathlib import Path

DEFAULT_REGION = "ap-southeast-2"
DEFAULT_CDN_HOST = "cdn.minimall.donkibuy.com"


def build_key(filename: str) -> str:
    return f"images/{filename}"
    # return f"images/{uuid.uuid4()}-{filename}"


def upload_image(s3, local_path: Path, bucket: str, cdn_host: str) -> tuple[str, str]:
    """Upload one image; returns (key, public_url)."""
    content_type = mimetypes.guess_type(local_path.name)[0]
    if not content_type or not content_type.startswith("image/"):
        raise ValueError(f"Not an image file (detected type: {content_type or 'unknown'}): {local_path}")

    key = build_key(local_path.name)
    s3.upload_file(str(local_path), bucket, key,
                   ExtraArgs={"ACL": "public-read", "ContentType": content_type})
    return key, f"https://{cdn_host}/{key}"


def main() -> int:
    ap = argparse.ArgumentParser(description="Upload a local image to S3 as images/<uuid>-<file>.")
    ap.add_argument("path", type=Path, help="local image file")
    ap.add_argument("--bucket", default=os.environ.get("S3_BUCKET"),
                    help="S3 bucket name (or set S3_BUCKET)")
    ap.add_argument("--region", default=os.environ.get("AWS_DEFAULT_REGION", DEFAULT_REGION),
                    help=f"AWS region (default {DEFAULT_REGION})")
    ap.add_argument("--cdn-host", default=os.environ.get("CDN_HOST", DEFAULT_CDN_HOST),
                    help=f"CDN host for the public URL (default {DEFAULT_CDN_HOST})")
    args = ap.parse_args()

    if not args.bucket:
        ap.error("bucket is required: use --bucket or set S3_BUCKET")
    if not args.path.is_file():
        print(f"File not found: {args.path}", file=sys.stderr)
        return 1

    try:
        import boto3
    except ImportError:
        print("Missing dependency 'boto3'. Run: python3 -m pip install boto3", file=sys.stderr)
        return 1
    from boto3.exceptions import S3UploadFailedError
    from botocore.exceptions import BotoCoreError, ClientError, NoCredentialsError

    try:
        key, url = upload_image(boto3.client("s3", region_name=args.region),
                                args.path, args.bucket, args.cdn_host)
    except ValueError as e:
        print(str(e), file=sys.stderr)
        return 1
    except NoCredentialsError:
        print("No AWS credentials found. Set AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY or run 'aws configure'.",
              file=sys.stderr)
        return 1
    except (ClientError, S3UploadFailedError, BotoCoreError) as e:
        print(f"Upload failed: {e}", file=sys.stderr)
        return 1

    print(f"Uploaded s3://{args.bucket}/{key}", file=sys.stderr)
    print(url)
    return 0


if __name__ == "__main__":
    sys.exit(main())
