#!/sbin/busybox sh

BB=/sbin/busybox
PROFILE_PATH=/data/.imperium

# Mounting partition in RW mode

OPEN_RW()
{
        $BB mount -o remount,rw /;
        $BB mount -o remount,rw /system;
}
OPEN_RW;

# Installing Busybox
/system/xbin/busybox --install -s /system/xbin/
$BB chmod 06755 /system/xbin/busybox

# Fixing ROOT
/system/xbin/daemonsu --auto-daemon &

sleep 1;

# Run Qualcomm scripts in system/etc folder if exists
if [ -f /system/etc/init.qcom.post_boot.sh ]; then
	$BB chmod 755 /system/etc/init.qcom.post_boot.sh;
	$BB sh /system/etc/init.qcom.post_boot.sh;
fi;

sleep 1;

OPEN_RW;

# Create init.d folder if missing
if [ ! -d /system/etc/init.d ]; then
	$BB mkdir -p /system/etc/init.d/
	$BB chmod 755 /system/etc/init.d/
fi

# Symlink
if [ ! -e /cpufreq ]; then
	$BB ln -s /sys/devices/system/cpu/cpu0/cpufreq/ /cpufreq;
	$BB ln -s /sys/devices/system/cpu/cpufreq/ /cpugov;
fi;

# Cleaning
$BB rm -rf /cache/lost+found/* 2> /dev/null;
$BB rm -rf /data/lost+found/* 2> /dev/null;
$BB rm -rf /data/tombstones/* 2> /dev/null;

OPEN_RW;

CRITICAL_PERM_FIX()
{
	# critical Permissions fix
	$BB chown -R system:system /data/anr;
	$BB chown -R root:root /tmp;
	$BB chown -R root:root /res;
	$BB chown -R root:root /sbin;
	$BB chown -R root:root /lib;
	$BB chmod -R 777 /tmp/;
	$BB chmod -R 775 /res/;
	$BB chmod -R 06755 /sbin/ext/;
	$BB chmod -R 0777 /data/anr/;
	$BB chmod -R 0400 /data/tombstones;
	$BB chown -R root:root /data/property;
	$BB chmod -R 0700 /data/property;
	$BB chmod 06755 /sbin/busybox;
}
CRITICAL_PERM_FIX;

# Prop tweaks
setprop persist.adb.notify 0
setprop persist.service.adb.enable 1
setprop pm.sleep_mode 1
setprop logcat.live disable
setprop profiler.force_disable_ulog 1
setprop ro.ril.disable.power.collapse 0
setprop persist.service.btui.use_aptx 1

# Make sure that max gpu clock is set by default to 450 MHz
$BB echo 450000000 > /sys/class/kgsl/kgsl-3d0/max_gpuclk;

# STweaks suppot
$BB rm -f /system/app/HybridTweaks.apk > /dev/null 2>&1;
$BB rm -f /system/app/Hulk-Kernel sTweaks.apk > /dev/null 2>&1;
$BB rm -f /system/app/STweaks.apk > /dev/null 2>&1;
$BB rm -f /system/app/STweaks_Googy-Max.apk > /dev/null 2>&1;
$BB rm -f /system/app/GTweaks.apk > /dev/null 2>&1;
$BB rm -f /data/app/com.gokhanmoral.stweaks* > /dev/null 2>&1;
$BB rm -f /data/data/com.gokhanmoral.stweaks*/* > /dev/null 2>&1;
$BB chown root.root /system/priv-app/STweaks.apk;
$BB chmod 644 /system/priv-app/STweaks.apk;

if [ ! -d /data/.imperium ]; then
	$BB mkdir -p /data/.imperium;
fi;

$BB chmod -R 0777 /data/.imperium/;

. /res/customconfig/customconfig-helper;

ccxmlsum=`md5sum /res/customconfig/customconfig.xml | awk '{print $1}'`
if [ "a${ccxmlsum}" != "a`cat /data/.imperium/.ccxmlsum`" ];
then
   $BB rm -f /data/.imperium/*.profile;
   $BB echo ${ccxmlsum} > /data/.imperium/.ccxmlsum;
fi;

[ ! -f /data/.imperium/default.profile ] && cp /res/customconfig/default.profile /data/.imperium/default.profile;
[ ! -f /data/.imperium/battery.profile ] && cp /res/customconfig/battery.profile /data/.imperium/battery.profile;
[ ! -f /data/.imperium/balanced.profile ] && cp /res/customconfig/balanced.profile /data/.imperium/balanced.profile;
[ ! -f /data/.imperium/performance.profile ] && cp /res/customconfig/performance.profile /data/.imperium/performance.profile;

chmod -R 0777 /data/.imperium/;
chmod 777 $PROFILE_PATH/default.profile

read_defaults;
read_config;

# Android logger
if [ "$logger_mode" == "on" ]; then
	$BB echo "1" > /sys/kernel/logger_mode/logger_mode;
else
	$BB echo "0" > /sys/kernel/logger_mode/logger_mode;
fi;

# zRam
if [ "$sammyzram" == "on" ];then
UNIT="M"
	/system/bin/rtccd3 -a "$zramdisksize$UNIT"
	$BB echo "0" > /proc/sys/vm/page-cluster;
fi;

# Scheduler
	$BB echo "$int_scheduler" > /sys/block/mmcblk0/queue/scheduler;
	$BB echo "$int_read_ahead_kb" > /sys/block/mmcblk0/bdi/read_ahead_kb;
	$BB echo "$ext_scheduler" > /sys/block/mmcblk1/queue/scheduler;
	$BB echo "$ext_read_ahead_kb" > /sys/block/mmcblk1/bdi/read_ahead_kb;

# CPU
	$BB echo "$scaling_governor_cpu0" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
	$BB echo "$scaling_governor_cpu0" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor;
	$BB echo "$scaling_governor_cpu0" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor;
	$BB echo "$scaling_governor_cpu0" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor;
	$BB echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
	$BB echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
	$BB echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq;
	$BB echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq;
	$BB echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq;
	$BB echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq;
	$BB echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq;
	$BB echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq;

# Apply STweaks defaults
export CONFIG_BOOTING=1
/res/uci.sh apply
export CONFIG_BOOTING=

OPEN_RW;

$BB chmod 777 $PROFILE_PATH/default.profile

# Fix critical perms again after init.d mess
	CRITICAL_PERM_FIX;
	
sleep 2;

# script finish here, so let me know when
rm /data/local/tmp/Imperium_LL_Kernel
touch /data/local/tmp/Imperium_LL_Kernel
echo "Imperium LL Kernel script correctly applied" > /data/local/tmp/Imperium_LL_Kernel;

$BB mount -t rootfs -o remount,ro rootfs
$BB mount -o remount,ro /system

