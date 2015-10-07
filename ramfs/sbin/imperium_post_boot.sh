#!/sbin/busybox sh

BB=/sbin/busybox

$BB mount -o remount,rw /system;
$BB mount -o remount,rw /;

/system/xbin/busybox --install -s /system/xbin/
chmod 06755 /system/xbin/busybox;

$BB sh /sbin/imperium.sh;

