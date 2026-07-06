#!/usr/bin/env python3
"""Render-regression check for the e_style font stack (c111_fonts.tex).

WHY. Three CJK/multilingual mechanisms in c111 fail in the "compiles clean,
renders WRONG" mode, invisible to any compile-time assertion:
  - the \\em reverse-patch string-matches a luatexja internal -> CJK \\emph can
    silently revert to gothic;
  - the ssub matrix relies on an UNDOCUMENTED luatexja side effect to make the
    AltFont rare-char fallback reach emph/bold/sc;
  - AltFont ranges + Renderer=Harfbuzz are experimental (AltFont broke silently
    across a TeX Live update once).
Only rasterizing the output and diffing it catches this class.

WHAT. Compiles fixture.tex (which \\inputs the REAL c111_fonts.tex), then makes
TWO assertions:
  1. tofu guard  -- zero "Missing character" lines in the log. Size-independent,
     so it catches any rare glyph that fell through the AltFont chain, however
     small.
  2. shape guard -- a pixel diff of the raster against a committed golden, with
     a tolerance tuned to catch a glyph-FAMILY swap (mincho->gothic emph) or a
     reshaped Devanagari cluster -- the regressions that render a *valid* glyph
     in the *wrong* shape and therefore emit no "Missing character".

FAIL-LOUD CONTRACT. Every external step (lualatex, pdftoppm) has its exit code
checked; the fixture PDF is deleted before each run so a stale render can never
be diffed; a missing golden, missing binary, or size change each produce a
distinct "FAIL: ..." line, never a false PASS and never a bare traceback.

Run  `python3 check.py`         after every tlmgr update / TeX Live year bump.
Run  `python3 check.py --bless` to regenerate the golden AFTER eyeballing the
     render (bless refuses to launder a tofu'd render).

Golden = the FULL-FONT path (system Source Han + HanaMin/Jigmo/Unifont). On a
CTAN-only machine the rare ranges tofu -> this test is *expected* to FAIL there;
that portable/degraded path is a separate contract, by construction not golden.

Deps: lualatex, pdftoppm (poppler), Pillow, numpy.
"""
import os
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
FIX = "fixture"
GOLDEN = HERE / "golden" / f"{FIX}.png"
DPI = "150"

# Tolerance derivation (not magic numbers):
#   golden is 945x532 = 502,740 px. The headline shape-swap we must catch is CJK
#   \emph reverting mincho->gothic (the \em-patch's whole purpose): ~3 emph CJK
#   glyphs, whose stroke-shape difference perturbs ~500 px, i.e. ~0.1% of the
#   page. TOL_FRAC is set to ~half that so the swap trips it with 2x margin.
#   Same-machine re-render is bit-identical (frac 0.00000), so the only source
#   of a sub-threshold nonzero diff is a font/poppler update changing anti-
#   aliasing -- a benign case that legitimately warrants a human re-bless.
#   Bias: a false FAIL costs one human glance; a false PASS hides a regression.
#   Blind spot (documented, not hidden): a single sub-threshold glyph reshape
#   can pass the pixel guard; tofu of that glyph is still caught by the miss
#   guard. Add a targeted probe to the fixture if a specific one-glyph shape
#   regression must be caught.
TOL_PIXEL = 32       # per-channel |delta| at/below which a pixel counts as unchanged (absorbs AA)
TOL_FRAC = 0.0005    # fail if > this fraction of pixels change beyond TOL_PIXEL


class Fail(Exception):
    """A checked failure -> clean 'FAIL: <msg>' + exit 1 (never a traceback)."""


def sh(cmd, env=None):
    try:
        return subprocess.run(cmd, cwd=HERE, capture_output=True, text=True, env=env)
    except FileNotFoundError:
        raise Fail(f"required tool not found on PATH: {cmd[0]!r}")


def texinputs_env():
    # Make \input{c111_fonts.tex} resolve from the repo itself, so the test does
    # not depend on e_style being symlinked into a TEXMF tree (self-contained on
    # a fresh clone). Prepend the sibling sty_components/ to TEXINPUTS.
    env = dict(os.environ)
    styd = (HERE / ".." / ".." / "sty_components").resolve()
    env["TEXINPUTS"] = f"{styd}{os.pathsep}" + env.get("TEXINPUTS", "")
    return env


def compile_fixture():
    """Compile fixture.tex; return the 'Missing character' count. Raise Fail on
    any compile problem -- crucially, never leave a stale PDF to be diffed."""
    pdf = HERE / f"{FIX}.pdf"
    pdf.unlink(missing_ok=True)          # a prior run's PDF must never be reused
    p = sh(["lualatex", "-interaction=nonstopmode", "-halt-on-error", f"{FIX}.tex"],
           env=texinputs_env())
    logf = HERE / f"{FIX}.log"
    log = logf.read_text(errors="ignore") if logf.exists() else ""
    if p.returncode != 0 or not pdf.exists():
        tail = "\n".join((log or p.stdout or "").splitlines()[-15:])
        raise Fail(f"fixture did not compile (lualatex rc={p.returncode}, "
                   f"pdf={'present' if pdf.exists() else 'MISSING'}).\n--- log tail ---\n{tail}")
    if "Could not revert" in log:
        raise Fail("luatexja \\em reverse-patch no longer applies "
                   "-> CJK \\emph would render gothic. (A luatexja internal changed.)")
    return log.count("Missing character")


def rasterize(out_stem):
    out = HERE / f"{out_stem}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.unlink(missing_ok=True)
    p = sh(["pdftoppm", "-png", "-r", DPI, "-singlefile", f"{FIX}.pdf", out_stem])
    if p.returncode != 0 or not out.exists():
        raise Fail(f"pdftoppm failed (rc={p.returncode}): {(p.stderr or '').strip()[:200]}")
    return out


def main():
    bless = "--bless" in sys.argv
    try:
        miss = compile_fixture()
        if miss:
            raise Fail(f"{miss} 'Missing character' line(s) in the log -- a rare glyph tofu'd "
                       f"(a fallback font or AltFont range regressed"
                       + (", refusing to bless a broken render)." if bless else ")."))
        if bless:
            out = rasterize(f"golden/{FIX}")
            print(f"blessed: {out} regenerated ({out.stat().st_size} B). "
                  f"Eyeball it before committing.")
            return 0
        if not GOLDEN.exists():
            raise Fail(f"golden image missing: {GOLDEN}. "
                       f"After confirming the render is correct by eye, run: python3 check.py --bless")
        cur = rasterize(f"{FIX}_cur")
        a = np.asarray(Image.open(GOLDEN).convert("RGB"), dtype=np.int16)
        b = np.asarray(Image.open(cur).convert("RGB"), dtype=np.int16)
        if a.shape != b.shape:
            raise Fail(f"image size changed: golden {a.shape[:2]} vs current {b.shape[:2]} "
                       f"(a layout/line-break/glyph-width regression).")
        frac = float((np.abs(a - b).max(axis=2) > TOL_PIXEL).mean())
        print(f"tofu (missing-char) count : {miss}")
        print(f"pixel-diff fraction       : {frac:.5f}  (threshold {TOL_FRAC})")
        if frac > TOL_FRAC:
            raise Fail(f"render drifted beyond tolerance. Compare {cur.name} against "
                       f"{GOLDEN.name}: if a real regression, fix it; if benign anti-aliasing "
                       f"from a renderer update, re-bless (python3 check.py --bless).")
        print("PASS")
        return 0
    except Fail as e:
        print(f"FAIL: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
