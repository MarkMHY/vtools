#!/system/bin/sh

action=$1

stop perfd
echo 0 > /sys/module/msm_thermal/core_control/enabled
echo 0 > /sys/module/msm_thermal/vdd_restriction/enabled
echo N > /sys/module/msm_thermal/parameters/enabled

#if [ ! `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` = "interactive" ]; then
#	sh /system/etc/init.qcom.post_boot.sh
#fi

# /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
# 300000 364800 441600 518400 595200 672000 748800 825600 883200 960000 1036800 1094400 1171200 1248000 1324800 1401600 1478400 1555200 1670400 1747200 1824000 1900800

# /sys/devices/system/cpu/cpu4/cpufreq/scaling_available_frequencies
# 300000 345600 422400 499200 576000 652800 729600 806400 902400 979200 1056000 1132800 1190400 1267200 1344000 1420800 1497600 1574400 1651200 1728000 1804800 1881600 1958400 2035200 2112000 2208000 2265600 2323200 2342400 2361600 2457600

echo 0 > /dev/cpuset/background/cpus
echo 0-2 > /dev/cpuset/system-background/cpus
echo 4-5 > /dev/cpuset/foreground/boost/cpus
echo 0-5 > /dev/cpuset/foreground/cpus

echo 1 > /sys/devices/system/cpu/cpu0/online
echo 1 > /sys/devices/system/cpu/cpu1/online
echo 1 > /sys/devices/system/cpu/cpu2/online
echo 1 > /sys/devices/system/cpu/cpu3/online
echo 1 > /sys/devices/system/cpu/cpu4/online
echo 1 > /sys/devices/system/cpu/cpu5/online

function gpu_config()
{
    gpu_freqs=`cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies`
    max_freq='710000000'
    for freq in $gpu_freqs; do
        if [[ $freq -gt $max_freq ]]; then
            max_freq=$freq
        fi;
    done
    gpu_min_pl=6
    if [[ -f /sys/class/kgsl/kgsl-3d0//num_pwrlevels ]];then
        gpu_min_pl=`cat /sys/class/kgsl/kgsl-3d0//num_pwrlevels`
        gpu_min_pl=`expr $gpu_min_pl - 1`
    fi;

    if [[ "$gpu_min_pl" = "-1" ]];then
        $gpu_min_pl=1
    fi;

    echo "msm-adreno-tz" > /sys/class/kgsl/kgsl-3d0/devfreq/governor
    #echo 710000000 > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
    echo $max_freq > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
    #echo 257000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
    echo 100000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
    echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
    echo 0 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
}
gpu_config


function set_cpu_freq()
{
	echo "0:$2 1:$2 2:$2 3:$2 4:$4 5:$4" > /sys/module/msm_performance/parameters/cpu_max_freq
	echo $1 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo $2 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
	echo $3 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
	echo $4 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
}

if [ "$action" = "powersave" ]; then
	echo "0" > /sys/module/cpu_boost/parameters/input_boost_freq
	echo 0 > /sys/module/cpu_boost/parameters/input_boost_ms

	set_cpu_freq 5000 1401600 5000 1497600

	echo "85 300000:85 518400:67 748800:75 1248000:78" > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/target_loads
	echo 518400 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq

	echo "87 345600:89 1056000:89 1344000:92" > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/target_loads
	echo 652800 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/hispeed_freq

	echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/default_pwrlevel

	echo 0 > /proc/sys/kernel/sched_boost

    echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/io_is_busy
    echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/io_is_busy

	exit 0
fi

echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/io_is_busy

if [ "$action" = "balance" ]; then
    echo "0:1248000 1:1248000 2:1248000 3:1248000 4:0 5:0" > /sys/module/cpu_boost/parameters/input_boost_freq
    echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms

	set_cpu_freq 5000 1401600 5000 1651200
	
    echo "83 300000:85 595200:67 825600:75 1248000:78" > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/target_loads
	echo 960000 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq

    echo "83 300000:89 1056000:89 1344000:92" > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/target_loads
	echo 1056000 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/hispeed_freq
	
	echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/default_pwrlevel

	echo 0 > /proc/sys/kernel/sched_boost
    echo 0-1 > /dev/cpuset/background/cpus
    echo 0-3 > /dev/cpuset/system-background/cpus
    echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/io_is_busy

	exit 0
fi

echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/io_is_busy
if [ "$action" = "performance" ]; then
    echo "0:0 1:0 2:0 3:0 4:1267200 5:1267200" > /sys/module/cpu_boost/parameters/input_boost_freq
    echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms

	set_cpu_freq 5000 1900800 5000 2457600
	
    echo "73 960000:72 1478400:78 1804800:87" > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/target_loads
    echo 1478400 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq

    echo "78 1497600:80 2016000:87" > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/target_loads
    echo 1267200 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/hispeed_freq
	
	echo `expr $gpu_min_pl - 1` > /sys/class/kgsl/kgsl-3d0/default_pwrlevel

	echo 1 > /proc/sys/kernel/sched_boost

    echo 0-1 > /dev/cpuset/background/cpus
    echo 0-1 > /dev/cpuset/system-background/cpus
	
	exit 0
fi

if [ "$action" = "fast" ]; then
    echo "0:0 1:0 2:0 3:0 4:1804800 5:1804800" > /sys/module/cpu_boost/parameters/input_boost_freq
    echo 80 > /sys/module/cpu_boost/parameters/input_boost_ms

	set_cpu_freq 5000 2750000 1267200 2750000
    echo "72 960000:72 1478400:78 1804800:87" > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/target_loads
	echo 1036800 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq

    echo "73 1497600:78 2016000:87" > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/target_loads
	echo 1497600 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/hispeed_freq
	
	echo `expr $gpu_min_pl - 1` > /sys/class/kgsl/kgsl-3d0/default_pwrlevel

	echo 1 > /proc/sys/kernel/sched_boost

    echo 0 > /dev/cpuset/background/cpus
    echo 0-1 > /dev/cpuset/system-background/cpus
	
	exit 0
fi
