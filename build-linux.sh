#!/bin/sh

# This script assembles the MikeOS bootloader, kernel and programs
# with NASM, and then creates floppy and CD images (on Linux)

# Only the root user can mount the floppy disk image as a virtual
# drive (loopback mounting), in order to copy across the files

# (If you need to blank the floppy image: 'mkdosfs disk_images/mikeos.flp')


if [ ! -e disk_images/wickyOS.flp ]
then
	echo ">>> Creating new wickyOS floppy image..."
	mkdosfs -C disk_images/wickyOS.flp 1440 || exit
fi


echo ">>> Assembling bootloader..."

nasm -O0 -f bin -o source/bootload/bootload.bin source/bootload/bootload.asm || exit


echo ">>> Assembling wickyOS kernel..."

cd source
nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm || exit
cd ..




echo ">>> Adding bootloader to floppy image..."

dd status=noxfer conv=notrunc if=source/bootload/bootload.bin of=disk_images/wickyOS.flp || exit


echo ">>> Copying wickyOS kernel and programs..."

rm -rf tmp-loop

mkdir tmp-loop && mount -o loop -t vfat disk_images/wickyOS.flp tmp-loop && cp source/kernel.bin tmp-loop/


sleep 0.2

echo ">>> Unmounting loopback floppy..."

umount tmp-loop || exit

rm -rf tmp-loop


echo ">>> Creating CD-ROM ISO image..."

rm -f disk_images/wickyOS.iso
mkisofs -quiet -V 'wickyOS' -input-charset iso8859-1 -o disk_images/wickyOS.iso -b wickyOS.flp disk_images/ || exit

echo '>>> Done!'

qemu-system-x86_64 -cdrom disk_images/wickyOS.iso

