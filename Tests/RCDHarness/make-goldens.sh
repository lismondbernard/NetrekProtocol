#!/bin/sh
#
# make-goldens.sh
#
# Rebuilds Tests/NetrekWireTests/CowDistressGoldens.swift from the COW
# client's own RCD code. Needs git and a C compiler (tested with gcc on
# Ubuntu 24.04). Run it from anywhere:
#
#   sh Tests/RCDHarness/make-goldens.sh
#
# It clones https://github.com/quozl/netrek-client-cow at COW_COMMIT into a
# temporary directory (or uses COW_DIR if you set it), copies the four
# tables the code needs out of COW's data.c, compiles harness.c together
# with COW's distress.c and senddist.c, and writes the Swift file. Nothing
# from COW is kept in this repository.

set -eu

COW_URL=https://github.com/quozl/netrek-client-cow
COW_COMMIT=f680bd3a1a2b040e8af1a27ec921c059c04f8007

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
out="$repo/Tests/NetrekWireTests/CowDistressGoldens.swift"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

if [ -n "${COW_DIR:-}" ]; then
    cow=$COW_DIR
else
    cow="$work/cow"
    git clone --quiet "$COW_URL" "$cow"
    git -C "$cow" checkout --quiet "$COW_COMMIT"
fi

# The default RCD macros and the name tables, exactly as COW has them.
{
    sed -n '/^struct dmacro_list dist_defaults\[\] =/,/^};/p' "$cow/data.c"
    sed -n '/^char   \*classes\[\] =/,/;/p' "$cow/data.c"
    sed -n '/^char    teamlet\[\] =/,/;/p' "$cow/data.c"
    sed -n '/^char   \*teamshort\[16\] =/,/;/p' "$cow/data.c"
} > "$work/cowdata.inc"

grep -q 'dist_defaults' "$work/cowdata.inc"
grep -q 'teamshort' "$work/cowdata.inc"

${CC:-cc} -std=gnu99 -w -I"$here" -I"$work" -I"$cow" \
    -o "$work/rcd-goldens" "$here/harness.c"

{
    cat <<'EOF'
//
//  CowDistressGoldens.swift
//  NetrekWireTests
//
//  Golden RCD data made by the COW client's own code, at
//  https://github.com/quozl/netrek-client-cow commit
//  f680bd3a1a2b040e8af1a27ec921c059c04f8007, through
//  Tests/RCDHarness/make-goldens.sh. See that script and harness.c for how.
//
//  "message" is the 80 byte CP_MESSAGE body COW sends, without its trailing
//  zero bytes. "relayed" is the SP_MESSAGE body the vanilla server sends on
//  to RC_DISTRESS clients. "expanded" is the line COW shows for it with its
//  default macros. "plainText" is what COW sends instead, as an ordinary
//  team message (group "plainGroup"), when the server lacks RC_DISTRESS.
//
//  COW notices. The lines in this file are made by the COW client's code
//  from its default RCD texts, which carry these notices (copyright.h and
//  copyright2.h at COW commit f680bd3):
//
//  /* Copyright (c) 1986   Chris Guthrie
//   *
//   * Permission to use, copy, modify, and distribute this software and its
//   * documentation for any purpose and without fee is hereby granted, provided
//   * that the above copyright notice appear in all copies and that both that
//   * copyright notice and this permission notice appear in supporting
//   * documentation.  No representations are made about the suitability of this
//   * software for any purpose.  It is provided "as is" without express or
//   * implied warranty.
//   *
//   * ----------------------------------------------------------- Copyright 1989
//   * Kevin P. Smith Scott Silvey
//   *
//   * ditto.
//   *
//   * ----------------------------------------------------------- Copyright 1993
//   *
//   * As above.  Use at your own risk.
//   *
//   * COW (BRM) authors (including but not limitted to: Kevin Powell Nick Trown
//   * Jeff Nelson Kurt Siegl)
//   * ----------------------------------------------------------- Copyright 1994
//   *
//   * As above.
//   *
//   * Hockey Lines added to COW by Nathan Doss Michael Kantner */
//
//  /*
//     Copyright 1989               Kevin P. Smith
//     Scott Silvey
//
//     Permission to use, copy, modify, and distribute this
//     software and its documentation for any purpose and without
//     fee is hereby granted, provided that the above copyright
//     notice appear in all copies.
//   */
//

EOF
    "$work/rcd-goldens"
} > "$out"

echo "wrote $out"
