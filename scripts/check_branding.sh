#!/bin/bash
#
# check_branding.sh — NVSpinLab branding guard.
#
# The application is completely unbranded: it must never ship vendor
# product names, URLs, social handles, brochure imagery, or any raster
# image resource other than the generated application icon.
#
# Usage (invoked from the NVSpinLab build phases, see project.yml):
#
#   check_branding.sh source                — scan the shipped source tree
#   check_branding.sh bundle <bundle-path>  — scan a built .app bundle
#
# The guard fails (exit code 1) if shipped sources or artifacts contain:
#   - prohibited vendor terms
#   - extracted brochure filenames
#   - any PDF document
#   - bytes matching the exact reference document hash
#   - any raster image resource other than the generated application icon
#
# The supplied reference material is internal-only and is never copied
# into the application bundle.

set -u

MODE="${1:-}"
shift || true

SRCROOT="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Prohibited vendor terms. Case-insensitive matching covers QZabre/QZABRE,
# qzabre.com and the @QZabreAG handle through the "qzabre" stem.
FORBIDDEN_TEXT_REGEX='qzabre|quantum[[:space:]]*edukit'

# Names under which extracted brochure pages might be copied into the
# bundle (see .brochure-preview/).
BROCHURE_NAME_REGEX='page-[0-9]+\.(png|jpe?g)'

# Raster formats prohibited in shipped resources. The generated
# application icon ships as AppIcon.icns and is therefore allowed.
RASTER_NAME_REGEX='\.(png|jpe?g|gif|tiff?|webp|bmp)$'

fail_with() {
    {
        echo ""
        echo "================================================================="
        echo " NVSpinLab branding guard: FAILED"
        echo "================================================================="
        printf '%s\n' "$1"
        echo "================================================================="
    } >&2
    echo "NVSpinLab branding guard: FAILED (see log above)" >&2
    exit 1
}

usage_fail() {
    fail_with "Usage: check_branding.sh {source|bundle} [path-to-app-bundle]"
}

case "$MODE" in
    source)
        if [ $# -gt 0 ]; then usage_fail; fi
        ROOT="${SRCROOT}/NVSpinLab"
        ;;
    bundle)
        if [ $# -lt 1 ]; then usage_fail; fi
        ROOT="$1"
        if [ ! -d "$ROOT" ]; then
            fail_with "Bundle path not found: ${ROOT}"
        fi
        ;;
    *)
        usage_fail
        ;;
esac

# ---------------------------------------------------------------------
# 1. Prohibited vendor terms in file contents.
# ------------------------------------------------------------------
TEXT_HITS=$(grep -rnEi "$FORBIDDEN_TEXT_REGEX" "$ROOT" 2>/dev/null || true)
if [ -n "$TEXT_HITS" ]; then
    fail_with "Prohibited vendor branding found in ${ROOT}:

${TEXT_HITS}

NVSpinLab must be completely unbranded. Remove all references to the
vendor, its product name, URL, or social handle from the shipped tree."
fi

# ---------------------------------------------------------------------
# 2. Extracted brochure page images, by filename.
# ---------------------------------------------------------------------
BROCHURE_HITS=$(find -E "$ROOT" -type f \
    -regex ".*${BROCHURE_NAME_REGEX}" 2>/dev/null || true)
if [ -n "$BROCHURE_HITS" ]; then
    fail_with "Brochure imagery is prohibited in the shipped tree (these files
exist in ${ROOT} and must be removed):

${BROCHURE_HITS}"
fi

# ---------------------------------------------------------------------
# 3. Any PDF document.
# ---------------------------------------------------------------------
PDF_HITS=$(find "$ROOT" -type f -name "*.pdf" 2>/dev/null || true)
if [ -n "$PDF_HITS" ]; then
    fail_with "PDF documents are prohibited in the shipped tree (these files
exist in ${ROOT} and must be removed):

${PDF_HITS}"
fi

# ---------------------------------------------------------------------
# 4. Raster image resources other than the generated application icon.
# ---------------------------------------------------------------------
RASTER_HITS=$(find -E "$ROOT" -type f \
    -regex ".*${RASTER_NAME_REGEX}" 2>/dev/null || true)
if [ -n "$RASTER_HITS" ]; then
    fail_with "Raster image resources are prohibited in the shipped tree.
Only the generated application icon (AppIcon.icns) may ship. Remove
these files from ${ROOT}:

${RASTER_HITS}"
fi

# ---------------------------------------------------------------------
# 5. Exact reference-document hash (bundle mode, defense in depth).
#    Hash every candidate reference document found in the repository
#    and fail if any shipped file reproduces one byte for byte, even
#    under a different name. No hashed reference found -> no-op.
# ---------------------------------------------------------------------
if [ "$MODE" = "bundle" ]; then
    TMP_REFS=$(mktemp -t nvbranding.XXXXXX) || fail_with "Temporary file creation failed."
    TMP_HITS=$(mktemp -t nvbranding.XXXXXX) || fail_with "Temporary file creation failed."
    trap 'rm -f "$TMP_REFS" "$TMP_HITS"' EXIT

    # Candidate reference documents: the brochure PDF (if present in the
    # repository) and the extracted brochure page images.
    REF_FILES=$(find "$SRCROOT" -maxdepth 3 -type f \
        \( -name "*.pdf" -o -path "*/.brochure-preview/*" \) \
        -not -path "*/build*" -not -path "*/.git/*" 2>/dev/null)
    if [ -n "$REF_FILES" ]; then
        printf '%s\n' "$REF_FILES" | while IFS= read -r ref; do
            /usr/bin/shasum -a 256 "$ref" 2>/dev/null | cut -d' ' -f1 >> "$TMP_REFS"
        done
        # Fail if any shipped file reproduces a reference document's bytes,
        # even under a different name.
        printf '%s\n' "$(find "$ROOT" -type f 2>/dev/null)" | while IFS= read -r f; do
            [ -n "$f" ] || continue
            h=$(/usr/bin/shasum -a 256 "$f" 2>/dev/null | cut -d' ' -f1)
            if grep -Fxq "$h" "$TMP_REFS" 2>/dev/null; then
                printf '%s\n' "$f" >> "$TMP_HITS"
            fi
        done
        if [ -s "$TMP_HITS" ]; then
            fail_with "The shipped bundle contains files that byte-match a
reference document or extracted brochure page:

$(cat "$TMP_HITS" )"
        fi
    fi
fi

echo "NVSpinLab branding guard: OK (mode=${MODE}, root=${ROOT})"
exit 0
