#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/latex-repo-check.XXXXXX")"
trap 'rm -rf "$BUILD_ROOT"' EXIT

for tool in latexmk lualatex pdftotext pdffonts pdftoppm; do
    command -v "$tool" >/dev/null || {
        echo "FAIL: required tool not found: $tool" >&2
        exit 1
    }
done

# --fonts shells out to e_style/test/fonts/check.py at the very END of this
# script. Its declared deps (check.py:37) are lualatex, pdftoppm and Pillow; the
# first two are in the loop above, Pillow is not and cannot be. check.py does
# report a missing Pillow properly rather than crashing, but it reports it after
# the whole suite has run, and that is knowable at second zero. The python3 first
# on PATH is frequently not the one carrying Pillow, which is why AGENTS.md
# documents the PATH=/opt/homebrew/bin:$PATH form.
if [[ "${1:-}" == "--fonts" ]]; then
    command -v python3 >/dev/null || {
        echo "FAIL: --fonts needs python3, which is not on PATH" >&2
        exit 1
    }
    python3 -c 'from PIL import Image' 2>/dev/null || {
        echo "FAIL: --fonts needs Pillow, and $(command -v python3) cannot import PIL" >&2
        echo "      try: PATH=/opt/homebrew/bin:\$PATH $0 --fonts" >&2
        exit 1
    }
fi

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

# An audit pin phrased as "this pattern must NOT appear" passes when the file
# cannot be read at all: commands in an `if' condition are exempt from set -e,
# so a renamed or moved file makes grep exit 2, the condition false, and the
# check silently succeed -- precisely during the refactor the pin exists to
# catch. (Positive pins, `if ! grep', fail correctly; the asymmetry is only in
# the negative ones.) So assert the population before testing it.
#
# pin_file sets PINNED rather than echoing the path, and that is load-bearing:
# an `exit 1' inside $(...) leaves only the subshell, so the FAIL message would
# print, the substitution would expand to the empty string, grep would error on
# "" and the pin would pass anyway -- the same silent pass, one layer down.
# Measured: that form reaches the end of the script with exit 0.
PINNED=""
pin_file() {
    [[ -f "$1" ]] || {
        echo "FAIL: audit pin references a file that does not exist: ${1#$ROOT/}" >&2
        echo "      (a pin whose file has moved passes silently -- fix the path)" >&2
        exit 1
    }
    PINNED="$1"
}

# A "single source" pin that counts matching FILES answers a weaker question than
# its own comment does. `found N files, want 1' stays satisfied when the
# definition is moved wholesale into some other file: the count is still 1, the
# named owner in the comment is now wrong, and nothing fails. Name the owner and
# compare against it instead of counting.
#
# The search command is passed as arguments rather than a string, so the patterns
# below keep their backslashes without a second layer of shell quoting.
sole_owner() {
    local owner="$1" what="$2"; shift 2
    pin_file "$ROOT/$owner"
    local found
    found="$( "$@" || true )"
    found="$(printf '%s\n' "$found" | sed -n "s#^$ROOT/##p" | sort -u)"
    if [[ "$found" != "$owner" ]]; then
        echo "FAIL: $what" >&2
        echo "      expected exactly one source, and it must be $owner" >&2
        echo "      found: ${found:-(nothing)}" >&2
        exit 1
    fi
}

# The same problem in a smaller register: the anchor/ToC/beamer assertions below
# carried no diagnosis of their own and relied on set -e, so a regression exited
# 1 printing nothing. Give them the FAIL line every other check here has.
assert_in() {
    local needle="$1" file="$2" what="$3"
    grep -Fq "$needle" "$file" || {
        echo "FAIL: $what (expected '$needle' in ${file#$BUILD_ROOT/})" >&2
        exit 1
    }
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
assert_in '{section*.1}' "$ANCHOR_AUX" 'numberless anchor 1 lost its hyperref destination'
assert_in '{section*.2}' "$ANCHOR_AUX" 'numberless anchor 2 lost its hyperref destination'

TOC_LOG="$BUILD_ROOT/toc-state/toc_state.log"
assert_in 'E-TOC-BEFORE=1' "$TOC_LOG" 'ToC state probe did not report BEFORE=1'
assert_in 'E-TOC-AFTER=1' "$TOC_LOG" 'ToC state leaked: probe did not report AFTER=1'

# The delaunay cover ornament. sample_beamer.tex above runs the theme with the
# option OFF, so without this document myespresso-delaunay.lua and the frame-keyed
# seed are executed zero times by this suite. The document pins randomseed and
# turns on meshdebug so the theme announces the seed it computed.
compile "$BUILD_ROOT/delaunay" "$SMOKE/beamer_delaunay.tex"
DELAUNAY_LOG="$BUILD_ROOT/delaunay/beamer_delaunay.log"

# The module's own three invariants, over four point counts.
assert_in 'E-DELAUNAY-OK=4/4' "$DELAUNAY_LOG" \
    'delaunay invariants failed (Euler / hull coverage / empty circumcircle)'

# Two numbers, because either alone is passed by a real bug the other catches.
# Measured against two mutations of the seed key:
#   per-typesetting counter -> overlay=3, distinct=5   (overlay check catches it)
#   \value{framenumber}     -> overlay=1, distinct=2   (ONLY distinctness catches it)
# The second shipped. One assertion would not have found it.
DELAUNAY_SEEDS="$(grep -h 'E-MESH-SEED=' "$DELAUNAY_LOG" | sed 's/.*=//')"
delaunay_overlay=$(printf '%s\n' "$DELAUNAY_SEEDS" | head -3 | sort -u | wc -l | tr -d ' ')
delaunay_distinct=$(printf '%s\n' "$DELAUNAY_SEEDS" | sort -u | wc -l | tr -d ' ')
if [[ "$delaunay_overlay" != "1" ]]; then
    echo "FAIL: cover mesh changes between overlays of one frame -- the seed is keyed" >&2
    echo "      on something that advances per typesetting (got $delaunay_overlay distinct seeds across 3 overlays)" >&2
    exit 1
fi
if [[ "$delaunay_distinct" != "3" ]]; then
    echo "FAIL: the three covers do not each get their own mesh (expected 3 distinct" >&2
    echo "      seeds, got $delaunay_distinct) -- seed key collides across adjacent covers" >&2
    exit 1
fi

# The overlay half again, from the rendered page rather than the seed. Pages 1-3
# are three overlays of ONE frame whose only visual difference is the mesh, so
# byte-identical renders are a clean isolation -- and this tests the DRAWING,
# so unlike the seed check it also catches a correct seed reaching a broken
# emit_tikz. It does not replace the seed check: distinct covers differ in their
# furniture too, so the same comparison cannot settle distinctness, which is why
# both are here.
( cd "$BUILD_ROOT/delaunay" && pdftoppm -f 1 -l 3 -r 100 -png beamer_delaunay.pdf ov )
delaunay_ov1="$(find "$BUILD_ROOT/delaunay" -name 'ov-1.png' -o -name 'ov-01.png' | head -1)"
delaunay_ov2="$(find "$BUILD_ROOT/delaunay" -name 'ov-2.png' -o -name 'ov-02.png' | head -1)"
delaunay_ov3="$(find "$BUILD_ROOT/delaunay" -name 'ov-3.png' -o -name 'ov-03.png' | head -1)"
if [[ ! -s "$delaunay_ov1" || ! -s "$delaunay_ov2" || ! -s "$delaunay_ov3" ]]; then
    echo "FAIL: could not render the three overlay pages of the delaunay cover" >&2
    exit 1
fi
# Guard against the null being vacuous: a blank crop compares equal to a blank
# crop. A rendered cover carries a mesh and is far larger than a solid page.
delaunay_ovsize=$(wc -c < "$delaunay_ov1" | tr -d ' ')
if [[ "$delaunay_ovsize" -lt 5000 ]]; then
    echo "FAIL: the rendered delaunay cover is $delaunay_ovsize bytes -- effectively blank," >&2
    echo "      so comparing overlays would pass by drawing nothing at all" >&2
    exit 1
fi
if ! cmp -s "$delaunay_ov1" "$delaunay_ov2" || ! cmp -s "$delaunay_ov2" "$delaunay_ov3"; then
    echo "FAIL: the cover mesh is redrawn between overlays of one frame -- the three" >&2
    echo "      overlay pages do not render identically" >&2
    exit 1
fi

BEAMER_TEXT="$BUILD_ROOT/beamer/second-separator.txt"
pdftotext -f 3 -l 3 -layout "$BUILD_ROOT/beamer/sample_beamer.pdf" "$BEAMER_TEXT"
assert_in 'Second' "$BEAMER_TEXT" 'second \sepframe did not render its title on page 3'
if grep -Fq 'Custom First' "$BEAMER_TEXT"; then
    echo "FAIL: sepframe option state leaked into the next call" >&2
    exit 1
fi

# --- sty_components naming convention ---
# Two prefixes marking package versus fragment, documented in AGENTS.md. The
# extension, the \ProvidesPackage line and the load mechanism move together:
#   e_<topic>.sty      package  -- \ProvidesPackage, \RequirePackage{e_visual}
#   c<NNN>_<topic>.tex fragment -- no \ProvidesPackage, \input{sty_components/...}
# The distinction is load-bearing (\input is ordered textual inclusion,
# \RequirePackage is idempotent and takes options), so a file on the wrong side
# of it reads as though there is no rule at all -- which is the actual cost of
# the three that already sit there.
#
# Those three are listed so that a FOURTH cannot appear silently. c112 and c113
# are grandfathered PUBLIC names: e_class_prologue.tex tells users to write
# \usepackage{c113_cjk_engine}, so renaming them breaks documents this repository
# cannot see. Shrinking this list is the goal; growing it needs a reason.
naming_allowed="c112_langfamily.sty c113_cjk_engine.sty e_class_prologue.tex"

# An allow-list silently goes stale when an entry is renamed away, and then it is
# excusing a file that no longer exists while the real one goes unchecked.
for naming_ex in $naming_allowed; do
    pin_file "$ROOT/e_style/sty_components/$naming_ex"
done

naming_bad=""
for naming_f in "$ROOT"/e_style/sty_components/*; do
    naming_b="$(basename "$naming_f")"
    case " $naming_allowed " in *" $naming_b "*) continue ;; esac
    naming_stem="${naming_b%.*}"
    naming_ext="${naming_b##*.}"
    naming_pp=$(grep -c 'ProvidesPackage' "$naming_f" || true)
    case "$naming_stem" in
        c[0-9][0-9][0-9]_*)
            [[ "$naming_ext" == "tex" && "$naming_pp" -eq 0 ]] ||
                naming_bad="$naming_bad $naming_b(fragment name, but .$naming_ext/ProvidesPackage=$naming_pp)" ;;
        e_*)
            [[ "$naming_ext" == "sty" && "$naming_pp" -ge 1 ]] ||
                naming_bad="$naming_bad $naming_b(package name, but .$naming_ext/ProvidesPackage=$naming_pp)" ;;
        *)
            naming_bad="$naming_bad $naming_b(neither e_* nor c<NNN>_*)" ;;
    esac
done
if [[ -n "$naming_bad" ]]; then
    echo "FAIL: sty_components naming convention broken by:$naming_bad" >&2
    echo "      e_<topic>.sty = package (\\ProvidesPackage, \\RequirePackage);" >&2
    echo "      c<NNN>_<topic>.tex = fragment (no \\ProvidesPackage, \\input). See AGENTS.md." >&2
    exit 1
fi

# --- Static single-source / tier invariants (audit pins) ---
# toccolorpart is owned solely by c120_color.tex. The old dark-blue
# \providecolor in c130_toc.tex was a second source that silently diverged
# by load order; regressing it must fail here.
sole_owner 'e_style/sty_components/c120_color.tex' \
    'toccolorpart must have exactly one color source' \
    grep -rlE '\\(colorlet|definecolor|providecolor)\{toccolorpart\}' "$ROOT/e_style"

# The 12pt heading-size policy belongs in the e_heading_scale feature, not in
# the e_document_layout component (a component must not apply presentation
# \titleformat nor read class-option state).
pin_file "$ROOT/e_style/sty_components/e_document_layout.sty"
if grep -Eq '\\titleformat' "$PINNED"; then
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
sole_owner 'e_style/sty_features/e_title_fenced_core.sty' \
    'fenced fence-box geometry must live in one file' \
    grep -rlF 'hrule height 1.5pt' "$ROOT/e_style/sty_features"

# luatexja reserves \zh/\zw as length primitives; e_cjk must not (re)define \zh
# (doing so silently breaks luatexja-ruby). Inline script switches use the
# collision-safe \text<tag> convention.
pin_file "$ROOT/e_style/sty_components/e_cjk.sty"
if grep -Eq '\\def\\zh([^a-zA-Z]|$)|\\newcommand\{?\\zh\}' "$PINNED"; then
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
# grep returning 1 on "no match" must not abort under set -e/pipefail, so the
# counting greps below are guarded with '|| true' (a zero count is a valid,
# non-error result these pins test for).
cv_default_dups=$({ grep -c '2b2b2b' "$ROOT/MyCV/cv_espresso_deedy_common.sty" || true; })
if [[ "$cv_default_dups" != "1" ]]; then
    echo "FAIL: CV default primary color 2b2b2b must appear once (single-source), found $cv_default_dups" >&2
    exit 1
fi

# The class-option prologue (12pt switch + cjk/nocjk) is single-sourced in
# sty_components/e_class_prologue.tex; no .cls may re-declare the switch.
switch_in_cls=$({ grep -lF 'newif\if@e@twelvept' "$ROOT"/e_style/classes/*.cls 2>/dev/null || true; } | wc -l | tr -d ' ')
if [[ "$switch_in_cls" != "0" ]]; then
    echo "FAIL: \\if@e@twelvept must live only in e_class_prologue.tex, found in $switch_in_cls .cls" >&2
    exit 1
fi
# [nocjk] must warn (it cannot disable the always-on CJK routing), not be silent.
if ! grep -Fq 'has no effect' "$ROOT/e_style/sty_components/e_class_prologue.tex"; then
    echo "FAIL: [nocjk] must emit a warning (not a silent no-op)" >&2
    exit 1
fi

# The per-author email fetch is single-sourced in e_frontbackmatter_core (the
# \__efm_author_email:nn accessor); the simple/formal renderers must call it,
# not re-inline \seq_item into the email seq.
sole_owner 'e_style/sty_features/e_frontbackmatter_core.sty' \
    'the per-author email fetch must live in one file' \
    grep -rlF 'seq_item:Nn \g__efm_emails_seq' "$ROOT/e_style/sty_features"

# ToC number columns grow for over-wide numbers via \e@settocnumeff instead of
# clipping into fixed-width makeboxes that collide with the title (M14).
if ! grep -Fq 'makebox[\e@tocnumeff]' "$ROOT/e_style/sty_components/c130_toc.tex"; then
    echo "FAIL: c130_toc must route numbered ToC entries through \\e@tocnumeff (M14 overflow fix)" >&2
    exit 1
fi

# c140_envs must not set a document-global \tcbset: it was meant as the callout's
# style but \tcbset makes it global, leaking colback/breakable into every
# tcolorbox (incl. the beamer theme boxes). The callout carries its own keys (M15).
pin_file "$ROOT/e_style/sty_components/c140_envs.tex"
if grep -Eq '^\\tcbset\{' "$PINNED"; then
    echo "FAIL: c140_envs must not set a document-global \\tcbset (fold keys into the callout)" >&2
    exit 1
fi

# --- Acceptance tests for the 2026-07-13 audit (LTX-2026-01..04) ---

# LTX-2026-01: both CV classes must render on the zero-config default path (no
# \cvsetup, no \setcv*font). The named colors primary/headings/subheadings/date
# were previously created only inside \cvsetup / the legacy setters, so the
# default path aborted with xcolor "Undefined color `date'". compile() runs
# latexmk -halt-on-error (a fatal recurrence fails the build); the grep also
# catches a non-fatal-mode recurrence.
for cvzc in cv_zeroconfig_1col cv_zeroconfig_2col; do
    compile "$BUILD_ROOT/$cvzc" "$SMOKE/$cvzc.tex"
    if grep -Fq 'Undefined color' "$BUILD_ROOT/$cvzc/$cvzc.log"; then
        echo "FAIL: CV zero-config path ($cvzc) hit an undefined color (LTX-2026-01 regression)" >&2
        exit 1
    fi
done

# LTX-2026-02: the sans CJK helpers must reach the Gothic jfont (\gtfamily, not
# \sffamily alone), and the sans jfont must carry the same opt-in rare-glyph
# AltFont ladder as the main jfont. Assert no tofu, that the render uses Source
# Han Sans / Harano Aji Gothic, and that it did NOT fall back to the serif.
compile "$BUILD_ROOT/cjk-sans" "$SMOKE/cjk_sans.tex"
if grep -Fq 'Missing character' "$BUILD_ROOT/cjk-sans/cjk_sans.log"; then
    echo "FAIL: cjk_sans emitted 'Missing character' -- sans rare-glyph ladder gap (LTX-2026-02)" >&2
    exit 1
fi
CJK_SANS_FONTS="$(pdffonts "$BUILD_ROOT/cjk-sans/cjk_sans.pdf")"
if ! grep -Eq 'SourceHanSans|HaranoAjiGothic' <<<"$CJK_SANS_FONTS"; then
    echo "FAIL: cjk_sans did not use the Gothic jfont -- \\textzhsans/\\textjasans not reaching \\gtfamily (LTX-2026-02)" >&2
    exit 1
fi
if grep -Eq 'SourceHanSerif|HaranoAjiMincho' <<<"$CJK_SANS_FONTS"; then
    echo "FAIL: cjk_sans fell back to the mincho serif jfont -- sans helper used \\sffamily only (LTX-2026-02)" >&2
    exit 1
fi

# LTX-2026-03: an unnumbered subsection ToC entry must left-align with its
# numbered peer's number (same ancestor-column left skip), not be outdented by a
# chapter-number column. latexmk resolves the ToC across passes; compare bboxes:
# the unnumbered subsection TITLE x must match the numbered subsection NUMBER x
# (both sit at leftskip = chapter+section columns) within 2pt.
compile "$BUILD_ROOT/toc-hier" "$SMOKE/toc_hierarchy.tex"
TOC_HIER_BBOX="$(pdftotext -bbox "$BUILD_ROOT/toc-hier/toc_hierarchy.pdf" - 2>/dev/null)"
toc_num_x="$(printf '%s\n' "$TOC_HIER_BBOX" | grep -m1 '>1.1.1<' | sed -E 's/.*xMin="([0-9.]+)".*/\1/')"
toc_unn_x="$(printf '%s\n' "$TOC_HIER_BBOX" | grep -m1 '>UnnumberedSubsecMARK<' | sed -E 's/.*xMin="([0-9.]+)".*/\1/')"
if [[ -z "$toc_num_x" || -z "$toc_unn_x" ]]; then
    echo "FAIL: toc_hierarchy probe could not locate the numbered number or unnumbered title in the ToC" >&2
    exit 1
fi
if ! awk -v a="$toc_num_x" -v b="$toc_unn_x" 'BEGIN{d=a-b; if(d<0)d=-d; exit !(d<2.0)}'; then
    echo "FAIL: unnumbered subsection ToC entry not aligned with its numbered peer (num_x=$toc_num_x unn_x=$toc_unn_x, LTX-2026-03)" >&2
    exit 1
fi

# --- Static pins for the same findings (source-level regression guards) ---

# LTX-2026-02: sans helpers switch \gtfamily; both \setsansjfont branches carry
# the AltFont ladder.
if ! grep -Eq '\\newcommand\{\\textzhsans\}.*\\gtfamily' "$ROOT/e_style/sty_components/e_cjk.sty" ||
   ! grep -Eq '\\newcommand\{\\textjasans\}.*\\gtfamily' "$ROOT/e_style/sty_components/e_cjk.sty"; then
    echo "FAIL: \\textzhsans/\\textjasans must select \\gtfamily, not \\sffamily alone (LTX-2026-02)" >&2
    exit 1
fi
sans_altfont="$(grep -c 'setsansjfont.*AltFont=' "$ROOT/e_style/sty_components/e_cjk.sty" || true)"
if [[ "$sans_altfont" -lt 2 ]]; then
    echo "FAIL: both \\setsansjfont branches must carry AltFont={\\e@cjkalt} (LTX-2026-02), found $sans_altfont" >&2
    exit 1
fi

# LTX-2026-03: both subsection ToC branches (numbered + unnumbered peer) use the
# chapter+section ancestor left skip. Exactly two lines carry this exact skip;
# the subsubsection branch appends +\tocsubsectionnumwidth and does not match.
toc_subsec_skip="$(grep -Ec 'leftskip\\dimexpr\\tocchapternumwidth\+\\tocsectionnumwidth\\relax' "$ROOT/e_style/sty_components/c130_toc.tex" || true)"
if [[ "$toc_subsec_skip" -lt 2 ]]; then
    echo "FAIL: both subsection ToC branches must use chapter+section leftskip (LTX-2026-03), found $toc_subsec_skip" >&2
    exit 1
fi

# LTX-2026-04: the langfamily coverage comment must state the real contract
# (opt-in ladder, no implicit fallback), not the false "extensions A-F" coverage
# claim that contradicted e_cjk. Match the distinctive false phrase as a fixed
# string -- the corrected comment legitimately uses "no implicit safety net",
# so a bare "implicit safety net" match would flag its own fix.
pin_file "$ROOT/e_style/sty_components/c112_langfamily.sty"
if grep -Fq 'extensions A-F' "$PINNED"; then
    echo "FAIL: c112_langfamily comment still claims implicit A-F fallback (LTX-2026-04)" >&2
    exit 1
fi
if ! grep -Fq 'eEnableCJKExtensionFonts' "$ROOT/e_style/sty_components/c112_langfamily.sty"; then
    echo "FAIL: c112_langfamily comment must document the opt-in rare-glyph ladder (LTX-2026-04)" >&2
    exit 1
fi

if [[ "${1:-}" == "--fonts" ]]; then
    (cd "$ROOT/e_style/test/fonts" && python3 check.py)
fi

echo "PASS: repository smoke checks"
