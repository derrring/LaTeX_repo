#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/latex-repo-check.XXXXXX")"
trap 'rm -rf "$BUILD_ROOT"' EXIT

for tool in latexmk lualatex pdftotext; do
    command -v "$tool" >/dev/null || {
        echo "FAIL: required tool not found: $tool" >&2
        exit 1
    }
done

export TEXINPUTS="$ROOT//:${TEXINPUTS:-}"

run_latexmk() {
    local work="$1"
    local source="$2"
    if ! (
        cd "$work"
        latexmk -lualatex -interaction=nonstopmode -halt-on-error "$source" >build.out 2>&1
    ); then
        echo "FAIL: $source did not compile" >&2
        tail -40 "$work/${source%.tex}.log" >&2 || tail -40 "$work/build.out" >&2
        exit 1
    fi
}

compile() {
    local work="$1"
    local source="$2"
    mkdir -p "$work"
    cp "$source" "$work/"
    run_latexmk "$work" "$(basename "$source")"
}

STANDARD="$BUILD_ROOT/standard"
mkdir -p "$STANDARD"
cp "$ROOT"/examples/sample_*.tex "$ROOT/examples/color_appendix.tex" "$STANDARD/"
for source in sample_article.tex sample_noteShort.tex sample_noteLong.tex sample_thesis.tex; do
    run_latexmk "$STANDARD" "$source"
done

if grep -Fq 'No \author given' "$STANDARD/sample_noteLong.log" ||
   grep -Fq 'No \author given' "$STANDARD/sample_thesis.log"; then
    echo "FAIL: formal-class maketitle lost author metadata" >&2
    exit 1
fi

CV="$BUILD_ROOT/cv"
mkdir -p "$CV"
cp "$ROOT"/examples/cv/*.tex "$CV/"
for source in cv_eg-1col.tex cv_eg-2col.tex; do
    run_latexmk "$CV" "$source"
done

SMOKE="$ROOT/e_style/test/smoke"
compile "$BUILD_ROOT/empty" "$SMOKE/empty_article.tex"
compile "$BUILD_ROOT/code" "$SMOKE/code_optin.tex"
compile "$BUILD_ROOT/anchors" "$SMOKE/numberless_anchor.tex"
compile "$BUILD_ROOT/toc-state" "$SMOKE/toc_state.tex"
compile "$BUILD_ROOT/beamer" "$SMOKE/sample_beamer.tex"

ANCHOR_AUX="$BUILD_ROOT/anchors/numberless_anchor.aux"
grep -Fq '{section*.1}' "$ANCHOR_AUX"
grep -Fq '{section*.2}' "$ANCHOR_AUX"

TOC_LOG="$BUILD_ROOT/toc-state/toc_state.log"
grep -Fq 'E-TOC-BEFORE=1' "$TOC_LOG"
grep -Fq 'E-TOC-AFTER=1' "$TOC_LOG"

BEAMER_TEXT="$BUILD_ROOT/beamer/second-separator.txt"
pdftotext -f 3 -l 3 -layout "$BUILD_ROOT/beamer/sample_beamer.pdf" "$BEAMER_TEXT"
grep -Fq 'Second' "$BEAMER_TEXT"
if grep -Fq 'Custom First' "$BEAMER_TEXT"; then
    echo "FAIL: sepframe option state leaked into the next call" >&2
    exit 1
fi

# --- Static single-source / tier invariants (audit pins) ---
# toccolorpart is owned solely by c120_color.tex. The old dark-blue
# \providecolor in c130_toc.tex was a second source that silently diverged
# by load order; regressing it must fail here.
tcp_sources=$(grep -rlE '\\(colorlet|definecolor|providecolor)\{toccolorpart\}' "$ROOT/e_style" | wc -l | tr -d ' ')
if [[ "$tcp_sources" != "1" ]]; then
    echo "FAIL: toccolorpart must have exactly one color source, found $tcp_sources" >&2
    exit 1
fi

# The 12pt heading-size policy belongs in the e_heading_scale feature, not in
# the e_document_layout component (a component must not apply presentation
# \titleformat nor read class-option state).
if grep -Eq '\\titleformat' "$ROOT/e_style/sty_components/e_document_layout.sty"; then
    echo "FAIL: e_document_layout (component) must not \\titleformat; heading policy belongs in e_heading_scale (feature)" >&2
    exit 1
fi
if ! grep -Fq 'if@e@twelvept' "$ROOT/e_style/sty_features/e_heading_scale.sty"; then
    echo "FAIL: e_heading_scale feature is missing the 12pt heading policy" >&2
    exit 1
fi

# The Japanese main/sans font has a single owner (e_cjk's guarded Source Han
# stack). c113_cjk_engine must defer to it via \@ifpackageloaded{e_cjk} rather
# than re-issuing a bare \setmainjfont that drops the extension-glyph fallback.
if ! grep -Fq '@ifpackageloaded{e_cjk}' "$ROOT/e_style/sty_components/c113_cjk_engine.sty"; then
    echo "FAIL: c113_cjk_engine must defer main/sans jfont to e_cjk (\\@ifpackageloaded{e_cjk} guard missing)" >&2
    exit 1
fi

# The fenced-title fence geometry (rules + gaps) is single-sourced in
# e_title_fenced_core.sty; the section and chapter styles must call it rather
# than re-inline their own vbox.
fence_sources=$(grep -rlF 'hrule height 1.5pt' "$ROOT/e_style/sty_features" | wc -l | tr -d ' ')
if [[ "$fence_sources" != "1" ]]; then
    echo "FAIL: fenced fence-box geometry must live only in e_title_fenced_core.sty, found in $fence_sources files" >&2
    exit 1
fi

# luatexja reserves \zh/\zw as length primitives; e_cjk must not (re)define \zh
# (doing so silently breaks luatexja-ruby). Inline script switches use the
# collision-safe \text<tag> convention.
if grep -Eq '\\def\\zh([^a-zA-Z]|$)|\\newcommand\{?\\zh\}' "$ROOT/e_style/sty_components/e_cjk.sty"; then
    echo "FAIL: e_cjk must not (re)define \\zh -- it is a luatexja length primitive (breaks ruby)" >&2
    exit 1
fi
if ! grep -Fq 'text#1' "$ROOT/e_style/sty_components/c112_langfamily.sty"; then
    echo "FAIL: \\newlangfamily must create \\text<tag> (collision-safe), not bare \\<tag>" >&2
    exit 1
fi

# The CJK rare-glyph extension ladder (HanaMinB/Jigmo/Unifont) is opt-in via
# \eEnableCJKExtensionFonts, not loaded eagerly on every document (eager loading
# adds ~10-15s/compile). e_cjk must keep the opt-in mechanism.
if ! grep -Fq 'newcommand{\eEnableCJKExtensionFonts}' "$ROOT/e_style/sty_components/e_cjk.sty"; then
    echo "FAIL: e_cjk must keep \\eEnableCJKExtensionFonts (extension ladder must stay opt-in, not eager)" >&2
    exit 1
fi

# e_math_env_deco declares its capability deps rather than relying on class load
# order (it consumes tcolorbox/colors via e_visual and the wrapped envs via
# e_theorems).
if ! grep -Fq 'RequirePackage{e_theorems}' "$ROOT/e_style/sty_features/e_math_env_deco.sty"; then
    echo "FAIL: e_math_env_deco must \\RequirePackage its deps (e_visual, e_theorems)" >&2
    exit 1
fi

# The CV default palette is single-sourced in \__cv_theme_default:; the primary
# hex must not be restated (init vs theme=default silent drift).
cv_default_dups=$(grep -c '2b2b2b' "$ROOT/MyCV/cv_espresso_deedy_common.sty")
if [[ "$cv_default_dups" != "1" ]]; then
    echo "FAIL: CV default primary color 2b2b2b must appear once (single-source), found $cv_default_dups" >&2
    exit 1
fi

if [[ "${1:-}" == "--fonts" ]]; then
    (cd "$ROOT/e_style/test/fonts" && python3 check.py)
fi

echo "PASS: repository smoke checks"
