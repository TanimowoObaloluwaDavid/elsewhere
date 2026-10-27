"""Turn the Playwright interaction clip into the README GIF.

Run tool/shots/demo.mjs first. The clip is intentionally trimmed to skip the
web boot screen; the palette is generated from the clip itself so the warm
paper and ink stay clean at a small size.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "docs" / "video" / "demo.webm"
OUTPUT = ROOT / "docs" / "demo.gif"

FILTER = (
    "setpts=PTS/1.4,"
    "fps=10,"
    "scale=300:-1:flags=lanczos,"
    "split[a][b];"
    "[a]palettegen=max_colors=192:stats_mode=diff[p];"
    "[b][p]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle"
)


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit("Run tool/shots/demo.mjs first to create docs/video/demo.webm")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    subprocess.run(
        [
            ffmpeg,
            "-y",
            "-ss",
            "6.0",
            "-t",
            "16.4",
            "-i",
            str(SOURCE),
            "-vf",
            FILTER,
            "-loop",
            "0",
            str(OUTPUT),
        ],
        check=True,
    )
    print(f"{OUTPUT.name}  {OUTPUT.stat().st_size / 1024 / 1024:.1f} MB")


if __name__ == "__main__":
    main()
