#!/usr/bin/env ash
# https://wiki.debian.org/ManipulatingISOs#remaster

set -e

# env from dockerfile:
# i = isos
# o = out
# t = temp

# find newest debian iso in data
iso=$(find "$i" -type f -maxdepth 1 -iname 'debian*.iso' | xargs -r ls -t1 | head -1)
[ -n "$iso" ] || { echo "no debian*.iso found in $i"; exit 1; }
iso=$(basename "$iso")
export iso

# extract iso
echo "extracting $iso"
bsdtar -C "$t" -xf "$i/$iso"

# make readable and copy preseed.cfg
echo "copy preseed.cfg"
chmod +w -R "$t"
cp "/preseed.cfg" "$t/"
cd "$t/isolinux/"

# append to isolinux txt
echo "configure preseeded autoinstall"
sed -i \
  -e 's/^\(\s*append\) \(.*\)$/\1 auto=true priority=high file=\/cdrom\/preseed.cfg \2/' \
  txt.cfg
sed -i \
  -e 's/^default .*/default install/' \
  -e 's/^timeout .*/timeout 20/' \
  isolinux.cfg
sed -i \
  -e 's/include gtk.cfg//' \
  menu.cfg

# dropping to shell for custom changes
echo "you can make custom changes now"
cd "$t"
ash

# make readonly and create hybrid iso
echo "recreate hybrid iso"
chmod -w -R "$t"
xorriso -as mkisofs \
  -o "$o/${iso%%.iso}-preseed.iso" \
  -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  "$t/"
rm -rf "$t"
