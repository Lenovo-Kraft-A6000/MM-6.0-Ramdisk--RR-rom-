#!/system/bin/sh

# Mount root as RW to apply tweaks and settings
mount -o remount,rw /;
mount -o rw,remount /system

BB=/sbin/busybox

# Make tmp folder
mkdir /tmp;

# Give permissions to execute
chown -R root:system /tmp/;
chmod -R 777 /tmp/;
chmod -R 777 /res/;
chmod 6755 /data/UKM/actions/*;
chmod 6755 /sbin/*;
chmod 6755 /system/xbin/*;
echo "Boot initiated on $(date)" > /tmp/bootcheck;

# Permissions for LMK
chmod 0664 /sys/module/lowmemorykiller/parameters/adj;
chmod 0664 /sys/module/lowmemorykiller/parameters/cost;
chmod 0664 /sys/module/lowmemorykiller/parameters/minfree;
chmod 0664 /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk;
chmod 0664 /sys/module/lowmemorykiller/parameters/vmpressure_file_min;

# Tune LMK with values we love
echo "12288,15360,18432,21504,24576,30720" > /sys/module/lowmemorykiller/parameters/minfree;
echo "32" > /sys/module/lowmemorykiller/parameters/cost;

# Adaptive LMK
echo "1" > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk;
echo "53059" > /sys/module/lowmemorykiller/parameters/vmpressure_file_min;

# Process Reclaim
echo "100" > /sys/module/process_reclaim/parameters/pressure_max;
echo "1" > /sys/module/process_reclaim/parameters/enable_process_reclaim;

# Vibrator amplitude
echo "50" > /sys/class/timed_output/vibrator/amp;

# Tweaks
echo "0" > /proc/sys/kernel/randomize_va_space;
echo "0" > /proc/sys/vm/page-cluster;
echo "50" > /proc/sys/vm/vfs_cache_pressure;
echo "5" > /proc/sys/vm/dirty_background_ratio;
echo "3000" > /proc/sys/vm/dirty_writeback_centisecs;
echo "600" > /proc/sys/vm/dirty_expire_centisecs;
echo "80" > /proc/sys/vm/swappiness;
echo "5120000" > /proc/sys/vm/dirty_background_bytes;

# general queue tweaks
for i in /sys/block/*/queue; do
  echo 512 > $i/nr_requests;
  echo 512 > $i/read_ahead_kb;
  echo 2 > $i/rq_affinity;
  echo 0 > $i/nomerges;
  echo 0 > $i/add_random;
  echo 0 > $i/rotational;
done;

# disable debugging
echo 0 > /sys/module/alarm/parameters/debug_mask;
echo 0 > /sys/module/alarm_dev/parameters/debug_mask;
echo 0 > /sys/module/binder/parameters/debug_mask;

# initialize init.d
if [ -d /system/etc/init.d ]; then
	$BB run-parts /system/etc/init.d
fi;

# Synapse initialization
$BB ln -fs /data/UKM/uci /xbin/uci;
cd /
/xbin/uci;

# Install Busybox
$BB --install -s /sbin

# Allow untrusted apps to read from debugfs
if [ -e /system/lib/libsupol.so ]; then
/system/xbin/supolicy --live \
	"allow untrusted_app debugfs file { open read getattr }" \
	"allow untrusted_app sysfs_lowmemorykiller file { open read getattr }" \
	"allow untrusted_app persist_file dir { open read getattr }" \
	"allow debuggerd gpu_device chr_file { open read getattr }" \
	"allow netd netd capability fsetid" \
	"allow netd { hostapd dnsmasq } process fork" \
	"allow { system_app shell } dalvikcache_data_file file write" \
	"allow { zygote mediaserver bootanim appdomain }  theme_data_file dir { search r_file_perms r_dir_perms }" \
	"allow { zygote mediaserver bootanim appdomain }  theme_data_file file { r_file_perms r_dir_perms }" \
	"allow system_server { rootfs resourcecache_data_file } dir { open read write getattr add_name setattr create remove_name rmdir unlink link }" \
	"allow system_server resourcecache_data_file file { open read write getattr add_name setattr create remove_name unlink link }" \
	"allow system_server dex2oat_exec file rx_file_perms" \
	"allow mediaserver mediaserver_tmpfs file execute" \
	"allow drmserver theme_data_file file r_file_perms" \
	"allow zygote system_file file write" \
	"allow atfwd property_socket sock_file write" \
	"allow debuggerd app_data_file dir search" \
	"allow sensors diag_device chr_file { read write open ioctl }" \
	"allow sensors sensors capability net_raw" \
	"allow init kernel security setenforce" \
	"allow netmgrd netmgrd netlink_xfrm_socket nlmsg_write" \
	"allow netmgrd netmgrd socket { read write open ioctl }"
fi;

# Google Services battery drain fixer by Alcolawl@xda
pm enable com.google.android.gms/.update.SystemUpdateActivity
pm enable com.google.android.gms/.update.SystemUpdateService
pm enable com.google.android.gms/.update.SystemUpdateService$ActiveReceiver
pm enable com.google.android.gms/.update.SystemUpdateService$Receiver
pm enable com.google.android.gms/.update.SystemUpdateService$SecretCodeReceiver
pm enable com.google.android.gsf/.update.SystemUpdateActivity
pm enable com.google.android.gsf/.update.SystemUpdatePanoActivity
pm enable com.google.android.gsf/.update.SystemUpdateService
pm enable com.google.android.gsf/.update.SystemUpdateService$Receiver
pm enable com.google.android.gsf/.update.SystemUpdateService$SecretCodeReceiver
