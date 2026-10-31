#!/bin/sh
# Check that WPDMA descriptor code never emits an unaligned 64-bit store.
# Descriptor memory is ioremap_nocache()/Device; only 32-bit field stores
# are legal at offsets 4 and 12 inside a 16-byte TXD/RXD.
set -eu
VMLINUX="$1"
OBJDUMP="${OBJDUMP:-aarch64-linux-gnu-objdump}"
fail=0
for sym in halWpdmaWriteCmd halWpdmaFillTxRing halWpdmaWriteData \
           halWpdmaWriteMsdu halWpdmaAllocRxRing kalDevPortWrite; do
    dis="$("$OBJDUMP" -d --disassemble="$sym" "$VMLINUX" 2>/dev/null || true)"
    [ -n "$dis" ] || continue
    bad="$(printf '%s\n' "$dis" | grep -E 'stur[[:space:]]+x[0-9]+, \[x[0-9]+, #(4|12)\]|str[[:space:]]+x[0-9]+, \[x[0-9]+, #(4|12)\]' || true)"
    if [ -n "$bad" ]; then
        echo "FAIL: unaligned 64-bit descriptor store in $sym"
        printf '%s\n' "$bad"
        fail=1
    else
        echo "OK: $sym uses only legal descriptor stores"
    fi
done
exit "$fail"
