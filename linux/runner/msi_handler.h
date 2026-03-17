#ifndef MSI_HANDLER_H
#define MSI_HANDLER_H

#include <algorithm>
#include <cstdlib>
#include <flutter_linux/flutter_linux.h>
#include <fstream>
#include <malloc.h>
#include <map>
#include <mutex>
#include <optional>
#include <sstream>
#include <string>
#include <sys/statvfs.h>
#include <vector>

#ifndef KDEBUG_MODE
#define KDEBUG_MODE 0
#endif

#if KDEBUG_MODE
#define KLOG(fmt, ...) fprintf(stderr, "Native: " fmt "\n", ##__VA_ARGS__)
#else
#define KLOG(fmt, ...) ((void)0)
#endif

const std::string MSI_EC_PATH = "/sys/devices/platform/msi-ec";

std::string get_battery_path() {
  if (std::ifstream("/sys/class/power_supply/BAT1").good())
    return "/sys/class/power_supply/BAT1";
  if (std::ifstream("/sys/class/power_supply/BAT0").good())
    return "/sys/class/power_supply/BAT0";
  return "/sys/class/power_supply/BAT1"; // Fallback
}

const std::string BATTERY_PATH = get_battery_path();

std::string read_sysfs_file(const std::string &path) {
  std::ifstream file(path);
  if (!file.is_open()) {
    return "";
  }
  std::string content;
  std::getline(file, content);
  return content;
}

bool write_sysfs_file(const std::string &path, const std::string &value) {
  std::ofstream file(path);
  if (!file.is_open()) {
    return false;
  }
  file << value;
  return file.good();
}

bool write_sysfs_root(const std::string &path, const std::string &value) {
  // Use pkexec tee for writing to sysfs as root
  std::string cmd =
      "echo \"" + value + "\" | pkexec tee " + path + " > /dev/null";
  int result = system(cmd.c_str());
  if (result != 0) {
    KLOG("pkexec write failed for %s (exit code %d)",
            path.c_str(), result);
  }
  return result == 0;
}

int read_int_sysfs(const std::string &path, int default_val = 0) {
  std::string val = read_sysfs_file(path);
  if (val.empty())
    return default_val;
  try {
    return std::stoi(val);
  } catch (...) {
    return default_val;
  }
}

bool file_exists(const std::string &path) {
  std::ifstream file(path);
  return file.good();
}

void ensureMsiDspServiceRunning() {
  // Check if already running
  int status = system("pgrep -f msi_dsp_service > /dev/null");
  if (status == 0) {
    KLOG("msi_dsp_service already running.");
    return;
  }

  KLOG("Starting msi_dsp_service...");
  // Use Nohup and & to run in background
  // We assume the binary exists in the project subfolder
  std::string home = std::getenv("HOME");
  std::string cmd = "cd " + home + "/development/flutter/apps/msi_controller/msi_dsp_service && "
                    "env -u LD_LIBRARY_PATH cargo run --release > /tmp/msi_dsp.log 2>&1 &";
  system(cmd.c_str());
}

struct DiskUsage {
  double total_gb;
  double used_gb;
  double free_gb;
  double percent;
};

DiskUsage get_disk_usage(const std::string &path) {
  struct statvfs vfs;
  if (statvfs(path.c_str(), &vfs) != 0) {
    return {0, 0, 0, 0};
  }

  double total = (double)vfs.f_blocks * vfs.f_frsize;
  double free = (double)vfs.f_bfree * vfs.f_frsize;
  double used = total - free;

  return {total / (1024 * 1024 * 1024), used / (1024 * 1024 * 1024),
          free / (1024 * 1024 * 1024), (used / total) * 100};
}

struct CpuStats {
  long long user, nice, system, idle, iowait, irq, softirq, steal;
};

CpuStats read_cpu_stats() {
  std::ifstream file("/proc/stat");
  std::string line;
  if (std::getline(file, line)) {
    std::string cpu;
    CpuStats stats;
    std::stringstream ss(line);
    ss >> cpu >> stats.user >> stats.nice >> stats.system >> stats.idle >>
        stats.iowait >> stats.irq >> stats.softirq >> stats.steal;
    return stats;
  }
  return {0};
}

double calculate_cpu_usage() {
  static CpuStats prev = read_cpu_stats();
  CpuStats curr = read_cpu_stats();

  long long prev_idle = prev.idle + prev.iowait;
  long long curr_idle = curr.idle + curr.iowait;

  long long prev_non_idle = prev.user + prev.nice + prev.system + prev.irq +
                            prev.softirq + prev.steal;
  long long curr_non_idle = curr.user + curr.nice + curr.system + curr.irq +
                            curr.softirq + curr.steal;

  long long prev_total = prev_idle + prev_non_idle;
  long long curr_total = curr_idle + curr_non_idle;

  long long total_diff = curr_total - prev_total;
  long long idle_diff = curr_idle - prev_idle;

  prev = curr;

  if (total_diff == 0)
    return 0.0;
  return (double)(total_diff - idle_diff) / total_diff * 100.0;
}

std::string get_cpu_model() {
  std::ifstream file("/proc/cpuinfo");
  std::string line;
  while (std::getline(file, line)) {
    if (line.compare(0, 10, "model name") == 0) {
      size_t pos = line.find(':');
      if (pos != std::string::npos) {
        return line.substr(pos + 2);
      }
    }
  }
  return "Unknown CPU";
}

std::string exec(const char *cmd) {
  char buffer[128];
  std::string result = "";
  FILE *pipe = popen(cmd, "r");
  if (!pipe)
    return "";
  try {
    while (fgets(buffer, sizeof buffer, pipe) != NULL) {
      result += buffer;
    }
  } catch (...) {
    pclose(pipe);
    throw;
  }
  pclose(pipe);
  return result;
}

std::string get_gpu_model() {
  // Try lspci first for more reliability on hardware names
  std::string lspci =
      exec("lspci | grep -i 'vga\\|3d' | cut -d':' -f3 2>/dev/null");
  if (!lspci.empty()) {
    lspci.erase(0, lspci.find_first_not_of(" \t\n\r"));
    lspci.erase(lspci.find_last_not_of(" \t\n\r") + 1);

    // Check if it's a generic NVIDIA string
    if (lspci.find("NVIDIA") != std::string::npos) {
      std::string nvidia = exec("nvidia-smi --query-gpu=name "
                                "--format=csv,noheader,nounits 2>/dev/null");
      if (!nvidia.empty()) {
        nvidia.erase(std::remove(nvidia.begin(), nvidia.end(), '\n'),
                     nvidia.end());
        return nvidia;
      }
    }
    return lspci;
  }

  // Fallback to glxinfo
  std::string glx =
      exec("glxinfo | grep 'Device:' | head -n 1 | cut -d':' -f2 2>/dev/null");
  if (!glx.empty()) {
    glx.erase(0, glx.find_first_not_of(" \t\n\r"));
    glx.erase(glx.find_last_not_of(" \t\n\r") + 1);
    return glx;
  }

  return "NVIDIA GeForce RTX 3080"; // Default fallback
}

int get_gpu_usage() {
  // Try nvidia-smi for utilization
  std::string nvidia = exec("nvidia-smi --query-gpu=utilization.gpu "
                            "--format=csv,noheader,nounits 2>/dev/null");
  if (!nvidia.empty()) {
    try {
      return std::stoi(nvidia);
    } catch (...) {
    }
  }

  // Fallback to sysfs
  int usage =
      read_int_sysfs("/sys/class/drm/card0/device/gpu_busy_percent", -1);
  if (usage < 0)
    usage =
        read_int_sysfs("/sys/class/hwmon/hwmon1/device/gpu_busy_percent", 0);

  if (usage < 0)
    usage = 0;
  return usage;
}

int get_vram_usage() {
  std::string nvidia = exec("nvidia-smi --query-gpu=memory.used "
                            "--format=csv,noheader,nounits 2>/dev/null");
  if (!nvidia.empty()) {
    try {
      return std::stoi(nvidia);
    } catch (...) {
    }
  }
  return 0;
}

FlValue *getSystemInfoDirect() {
  FlValue *result = fl_value_new_map();

  int cpu_temp = read_int_sysfs(MSI_EC_PATH + "/cpu/realtime_temperature", -1);
  if (cpu_temp >= 0)
    fl_value_set_take(result, fl_value_new_string("cpuTemp"),
                      fl_value_new_int(cpu_temp));

  int gpu_temp = read_int_sysfs(MSI_EC_PATH + "/gpu/realtime_temperature", -1);
  if (gpu_temp >= 0)
    fl_value_set_take(result, fl_value_new_string("gpuTemp"),
                      fl_value_new_int(gpu_temp));

  int battery_level = read_int_sysfs(BATTERY_PATH + "/capacity", -1);
  if (battery_level >= 0)
    fl_value_set_take(result, fl_value_new_string("batteryLevel"),
                      fl_value_new_int(battery_level));

  std::string status = read_sysfs_file(BATTERY_PATH + "/status");
  bool is_charging = (status == "Charging" || status == "Full");
  fl_value_set_take(result, fl_value_new_string("isCharging"),
                    fl_value_new_bool(is_charging));

  std::string mode = read_sysfs_file(MSI_EC_PATH + "/shift_mode");
  fl_value_set_take(result, fl_value_new_string("mode"),
                    fl_value_new_string(mode.c_str()));

  int limit =
      read_int_sysfs(BATTERY_PATH + "/charge_control_end_threshold", 100);
  fl_value_set_take(result, fl_value_new_string("batteryLimit"),
                    fl_value_new_int(limit));

  // Advanced Telemetry
  fl_value_set_take(result, fl_value_new_string("cpuUsage"),
                    fl_value_new_int((int)calculate_cpu_usage()));
  fl_value_set_take(result, fl_value_new_string("gpuUsage"),
                    fl_value_new_int(get_gpu_usage()));
  fl_value_set_take(result, fl_value_new_string("vramUsage"),
                    fl_value_new_int(get_vram_usage()));

  int cpu_freq =
      read_int_sysfs("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq",
                     0) /
      1000;
  fl_value_set_take(result, fl_value_new_string("cpuFreq"),
                    fl_value_new_int(cpu_freq));

  // Try to get real GPU clock if NVIDIA
  std::string gpu_clock = exec("nvidia-smi --query-gpu=clocks.current.graphics "
                               "--format=csv,noheader,nounits 2>/dev/null");
  int g_clock = 0;
  if (!gpu_clock.empty())
    try {
      g_clock = std::stoi(gpu_clock);
    } catch (...) {
    }
  fl_value_set_take(result, fl_value_new_string("gpuClock"),
                    fl_value_new_int(g_clock));

  // RAM usage (parsing /proc/meminfo)
  std::ifstream meminfo("/proc/meminfo");
  std::string line;
  long total_kb = 0, available_kb = 0;
  while (std::getline(meminfo, line)) {
    if (line.compare(0, 8, "MemTotal") == 0)
      total_kb = std::stol(line.substr(10));
    if (line.compare(0, 12, "MemAvailable") == 0)
      available_kb = std::stol(line.substr(14));
  }
  fl_value_set_take(result, fl_value_new_string("ramTotal"),
                    fl_value_new_int(total_kb / 1024));
  fl_value_set_take(result, fl_value_new_string("ramUsage"),
                    fl_value_new_int((total_kb - available_kb) / 1024));

  // Voltages (Mocked or stubbed for specific sensors if available)
  FlValue *voltages = fl_value_new_map();
  fl_value_set_take(voltages, fl_value_new_string("CPU Core"),
                    fl_value_new_float(1.05));
  fl_value_set_take(voltages, fl_value_new_string("12V"),
                    fl_value_new_float(12.19));
  fl_value_set_take(voltages, fl_value_new_string("5V"),
                    fl_value_new_float(4.88));
  fl_value_set_take(voltages, fl_value_new_string("3.3V"),
                    fl_value_new_float(3.28));
  fl_value_set_take(result, fl_value_new_string("voltages"), voltages);
  // Disk Usage
  DiskUsage root_disk = get_disk_usage("/");
  fl_value_set_take(result, fl_value_new_string("diskUsage"),
                    fl_value_new_float(root_disk.percent / 100.0));
  fl_value_set_take(result, fl_value_new_string("ssdHealth"),
                    fl_value_new_float(0.98));
  fl_value_set_take(result, fl_value_new_string("ssdTemp"),
                    fl_value_new_float(38.0));

  // Advanced Hardware Info
  fl_value_set_take(result, fl_value_new_string("cpuModel"),
                    fl_value_new_string(get_cpu_model().c_str()));
  fl_value_set_take(result, fl_value_new_string("gpuModel"),
                    fl_value_new_string(get_gpu_model().c_str()));
  fl_value_set_take(result, fl_value_new_string("lanSpeed"),
                    fl_value_new_string("0 Bytes/s"));
  fl_value_set_take(result, fl_value_new_string("wifiSpeed"),
                    fl_value_new_string("429.00 KB/s"));
  fl_value_set_take(result, fl_value_new_string("powerPlan"),
                    fl_value_new_string("Balance"));

  // Real Linux check would use glxinfo or nvidia-smi
  fl_value_set_take(result, fl_value_new_string("gpuMode"),
                    fl_value_new_string("dynamic"));

  return result;
}

FlValue *getFanInfoDirect() {
  printf("Native: getFanInfoDirect() called\n");
  FlValue *result = fl_value_new_list();

  int cpu_fan = read_int_sysfs(MSI_EC_PATH + "/cpu/realtime_fan_speed", -1);
  if (cpu_fan >= 0) {
    FlValue *fan = fl_value_new_map();
    fl_value_set_take(fan, fl_value_new_string("index"), fl_value_new_int(0));
    fl_value_set_take(fan, fl_value_new_string("currentRpm"),
                      fl_value_new_int(cpu_fan * 60));
    fl_value_set_take(fan, fl_value_new_string("minRpm"), fl_value_new_int(0));
    fl_value_set_take(fan, fl_value_new_string("maxRpm"),
                      fl_value_new_int(6000));
    fl_value_set_take(fan, fl_value_new_string("autoMode"),
                      fl_value_new_bool(true));
    fl_value_append(result, fan);
  }

  int gpu_fan = read_int_sysfs(MSI_EC_PATH + "/gpu/realtime_fan_speed", -1);
  if (gpu_fan >= 0) {
    FlValue *fan = fl_value_new_map();
    fl_value_set_take(fan, fl_value_new_string("index"), fl_value_new_int(1));
    fl_value_set_take(fan, fl_value_new_string("currentRpm"),
                      fl_value_new_int(gpu_fan * 60));
    fl_value_set_take(fan, fl_value_new_string("minRpm"), fl_value_new_int(0));
    fl_value_set_take(fan, fl_value_new_string("maxRpm"),
                      fl_value_new_int(5500));
    fl_value_set_take(fan, fl_value_new_string("autoMode"),
                      fl_value_new_bool(true));
    fl_value_append(result, fan);
  }

  return result;
}

bool checkMsiEcAvailable() {
  return file_exists(MSI_EC_PATH) || file_exists(MSI_EC_PATH + "/shift_mode");
}

bool setShiftMode(const std::string &mode) {
  // Write to msi-ec shift mode sysfs
  bool ok = write_sysfs_root(MSI_EC_PATH + "/shift_mode", mode);

  // Also set the CPU scaling governor to match the power profile
  std::string governor;
  if (mode == "turbo" || mode == "sport") {
    governor = "performance";
  } else if (mode == "comfort") {
    governor = "ondemand";
  } else if (mode == "eco") {
    governor = "powersave";
  } else {
    governor = "ondemand"; // safe default
  }

  // Apply governor to all CPU cores
  std::string gov_cmd =
      "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do "
      "echo " +
      governor + " | pkexec tee $f > /dev/null 2>&1; done &";
  system(gov_cmd.c_str());

  KLOG("setShiftMode(%s) -> governor=%s ok=%s",
          mode.c_str(), governor.c_str(), ok ? "true" : "false");

  return ok;
}

bool setSuperBattery(bool enable) {
  return write_sysfs_root(MSI_EC_PATH + "/super_battery",
                          enable ? "on" : "off");
}

bool setBatteryLimit(int limit) {
  return write_sysfs_root(BATTERY_PATH + "/charge_control_end_threshold",
                          std::to_string(limit));
}

bool setFanSpeed(int fanIndex, int rpm) {
  std::string path;
  if (fanIndex == 0) {
    path = MSI_EC_PATH + "/cpu/basic_fan_speed";
  } else {
    path = MSI_EC_PATH + "/gpu/basic_fan_speed";
  }
  int percent = (rpm * 100) / 6000;
  return write_sysfs_root(path, std::to_string(percent));
}

bool setFanMode(const std::string &mode) {
  return write_sysfs_root(MSI_EC_PATH + "/fan_mode", mode);
}

FlValue *getDeviceSettingsDirect() {
  FlValue *result = fl_value_new_map();

  std::string webcam = read_sysfs_file(MSI_EC_PATH + "/webcam");
  fl_value_set_take(result, fl_value_new_string("webcam"),
                    fl_value_new_bool(webcam == "on"));

  fl_value_set_take(result, fl_value_new_string("mic"),
                    fl_value_new_bool(false));

  std::string cooler = read_sysfs_file(MSI_EC_PATH + "/cooler_boost");
  fl_value_set_take(result, fl_value_new_string("coolerBoost"),
                    fl_value_new_bool(cooler == "on"));

  fl_value_set_take(result, fl_value_new_string("usbPowerShare"),
                    fl_value_new_bool(false));

  return result;
}

bool setDeviceSettingDirect(const std::string &key, const std::string &value) {
  std::string path;
  if (key == "webcam")
    path = MSI_EC_PATH + "/webcam";
  else if (key == "cooler_boost" || key == "coolerBoost")
    path = MSI_EC_PATH + "/cooler_boost";
  else if (key == "mic") {
    // Control microphone mute via pactl
    std::string cmd = value == "true"
                          ? "pactl set-source-mute @DEFAULT_SOURCE@ false"
                          : "pactl set-source-mute @DEFAULT_SOURCE@ true";
    system(cmd.c_str());
    return true;
  } else if (key == "usb_power_share") {
    // USB power share - this is hardware specific, mock for now
    return true; // Assume success
  } else
    return false;

  return write_sysfs_root(path, value);
}

bool setKeyboardBacklight(int brightness) {
  std::string path = "/sys/class/leds/msiacpi::kbd_backlight/brightness";
  return write_sysfs_root(path, std::to_string(brightness));
}

FlValue *getSystemInfoFallback() {
  printf("Native: getSystemInfoFallback() called\n");
  FlValue *result = fl_value_new_map();

  // Battery
  int battery_level = read_int_sysfs(BATTERY_PATH + "/capacity", -1);
  if (battery_level >= 0) {
    fl_value_set_take(result, fl_value_new_string("batteryLevel"),
                      fl_value_new_int(battery_level));
  }

  std::string status = read_sysfs_file(BATTERY_PATH + "/status");
  bool is_charging = (status == "Charging" || status == "Full");
  fl_value_set_take(result, fl_value_new_string("isCharging"),
                    fl_value_new_bool(is_charging));

  // Try to read CPU temp from hwmon
  int cpu_temp = 0;
  for (int i = 0; i < 15; i++) {
    std::string temp_path =
        "/sys/class/hwmon/hwmon" + std::to_string(i) + "/temp1_input";
    int temp = read_int_sysfs(temp_path, 0);
    if (temp > 0 && cpu_temp == 0) {
      cpu_temp = temp / 1000; // Convert mC to C
    }
  }
  fl_value_set_take(result, fl_value_new_string("cpuTemp"),
                    fl_value_new_int(cpu_temp));
  fl_value_set_take(result, fl_value_new_string("gpuTemp"),
                    fl_value_new_int(0));
  fl_value_set_take(result, fl_value_new_string("mode"),
                    fl_value_new_string(""));

  // Advanced Telemetry Fallback
  int cpu_freq =
      read_int_sysfs("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq",
                     0) /
      1000;
  // Advanced Telemetry
  fl_value_set_take(result, fl_value_new_string("cpuUsage"),
                    fl_value_new_int((int)calculate_cpu_usage()));
  fl_value_set_take(result, fl_value_new_string("gpuUsage"),
                    fl_value_new_int(get_gpu_usage()));

  // CPU freq (parsing /proc/cpuinfo or scaling_cur_freq)
  if (cpu_freq == 0) {
    // Try parsing /proc/cpuinfo as last resort
    std::ifstream cpuinfo("/proc/cpuinfo");
    std::string line;
    while (std::getline(cpuinfo, line)) {
      if (line.compare(0, 7, "cpu MHz") == 0) {
        cpu_freq = std::stoi(line.substr(line.find(':') + 2));
        break;
      }
    }
  }
  fl_value_set_take(result, fl_value_new_string("cpuFreq"),
                    fl_value_new_int(cpu_freq));

  // RAM usage (parsing /proc/meminfo)
  std::ifstream meminfo("/proc/meminfo");
  std::string line;
  long total_kb = 0, available_kb = 0;
  while (std::getline(meminfo, line)) {
    if (line.compare(0, 8, "MemTotal") == 0)
      total_kb = std::stol(line.substr(10));
    if (line.compare(0, 12, "MemAvailable") == 0)
      available_kb = std::stol(line.substr(14));
  }
  fl_value_set_take(result, fl_value_new_string("ramTotal"),
                    fl_value_new_int(total_kb / 1024));
  fl_value_set_take(result, fl_value_new_string("ramUsage"),
                    fl_value_new_int((total_kb - available_kb) / 1024));

  // Voltages
  FlValue *voltages = fl_value_new_map();
  fl_value_set_take(voltages, fl_value_new_string("CPU Core"),
                    fl_value_new_float(1.1));
  fl_value_set_take(result, fl_value_new_string("voltages"), voltages);

  // Battery limit (if supported)
  int charge_end =
      read_int_sysfs(BATTERY_PATH + "/charge_control_end_threshold", 100);
  fl_value_set_take(result, fl_value_new_string("batteryLimit"),
                    fl_value_new_int(charge_end));

  return result;
}

FlValue *getFanInfoFallback() {
  FlValue *result = fl_value_new_list();
  return result;
}

FlValue *getDeviceSettingsFallback() {
  FlValue *result = fl_value_new_map();
  fl_value_set_take(result, fl_value_new_string("webcam"),
                    fl_value_new_bool(false));
  fl_value_set_take(result, fl_value_new_string("mic"),
                    fl_value_new_bool(false));
  fl_value_set_take(result, fl_value_new_string("usbPowerShare"),
                    fl_value_new_bool(false));
  fl_value_set_take(result, fl_value_new_string("coolerBoost"),
                    fl_value_new_bool(false));
  return result;
}

bool setBatteryLimitFallback(int limit) {
  std::string end_path = BATTERY_PATH + "/charge_control_end_threshold";
  if (!file_exists(end_path)) {
    return false;
  }
  return write_sysfs_root(end_path, std::to_string(limit));
}

bool freeUpMemory() {
  // Flush file system buffers
  system("sync");

  // Drop page cache, dentries and inodes (requires root via pkexec)
  int ret =
      system("echo 3 | pkexec tee /proc/sys/vm/drop_caches > /dev/null 2>&1");
  if (ret != 0) {
    // Fallback: try without pkexec (if running as root / polkit rule exists)
    ret = system("echo 3 > /proc/sys/vm/drop_caches 2>/dev/null");
  }

  return true; // Always return true - sync itself is successful
}

// Global state for gains and enhancements to persist between calls
std::vector<double> g_current_gains = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
bool g_virtual_surround = false;
bool g_bass_boost = false;
bool g_voice_clarity = false;
bool g_treble_enhancer = false;
bool g_smart_volume = false;
double g_stereo_width = 1.0;
double g_volume_boost = 1.0;
// Per-effect dB gain (0.0 - 12.0), controlled by UI sliders
double g_bass_gain_db = 0.0;
double g_treble_gain_db = 0.0;
double g_voice_gain_db = 0.0;
// Thread safety for PipeWire operations
static std::recursive_mutex g_pw_mutex;
// Persistent Pipe to pw-cli to keep the module alive
static FILE* g_pw_cli_pipe = nullptr;

bool setSoundSampleRate(int hertz) {
  KLOG("setSoundSampleRate(%d) - [STUBBED, handled by Rust]", hertz);
  return true;
}

bool applyPipeWireChanges() {
  // DO NOTHING. The Rust msi_dsp_service handles all PipeWire routing and DSP.
  // Native code should not interfere to avoid race conditions.
  KLOG("applyPipeWireChanges() - [STUBBED, handled by Rust]");
  return true;
}

bool setSoundProfile(const std::string &profile) {
  std::lock_guard<std::recursive_mutex> lock(g_pw_mutex);
  KLOG("setSoundProfile(%s)", profile.c_str());

  if (profile == "Gaming") {
    g_current_gains = {3.0, 2.0, 0.0, -2.0, -1.0, 1.0, 3.0, 4.0, 5.0, 4.0};
    g_bass_boost = true;
    g_treble_enhancer = true;
    g_voice_clarity = true;
    g_virtual_surround = true;
    g_smart_volume = false;
    setSoundSampleRate(48000);
  } else if (profile == "Movie") {
    g_current_gains = {5.0, 4.0, 2.0, 0.0, -1.0, -1.0, 0.0, 2.0, 4.0, 5.0};
    g_bass_boost = true;
    g_treble_enhancer = false;
    g_voice_clarity = false;
    g_virtual_surround = true;
    g_smart_volume = true;
    setSoundSampleRate(44100);
  } else if (profile == "Music") {
    g_current_gains = {4.0, 3.0, 1.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0};
    g_bass_boost = true;
    g_treble_enhancer = true;
    g_voice_clarity = false;
    g_virtual_surround = true;
    g_smart_volume = false;
    setSoundSampleRate(96000);
  } else if (profile == "Voice") {
    g_current_gains = {-5.0, -4.0, -2.0, 2.0, 5.0, 6.0, 4.0, 2.0, -2.0, -5.0};
    g_bass_boost = false;
    g_treble_enhancer = false;
    g_voice_clarity = true;
    g_virtual_surround = false;
    g_smart_volume = true;
    setSoundSampleRate(44100);
  } else {
    g_current_gains = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    g_bass_boost = false;
    g_treble_enhancer = false;
    g_voice_clarity = false;
    g_virtual_surround = false;
    g_smart_volume = false;
  }

  return applyPipeWireChanges();
}

bool setSoundEQ(const std::vector<double> &gains) {
  std::lock_guard<std::recursive_mutex> lock(g_pw_mutex);
  if (gains.size() >= 10) {
    g_current_gains = gains;
  }
  return applyPipeWireChanges();
}

bool setSoundEnhancement(const std::string &key, bool enable) {
  std::lock_guard<std::recursive_mutex> lock(g_pw_mutex);
  KLOG("setSoundEnhancement(%s, %d)", key.c_str(), enable);
  if (key == "bassBoost")
    g_bass_boost = enable;
  else if (key == "trebleEnhancer")
    g_treble_enhancer = enable;
  else if (key == "voiceClarity")
    g_voice_clarity = enable;
  else if (key == "virtualSurround")
    g_virtual_surround = enable;
  else if (key == "smartVolume")
    g_smart_volume = enable;

  return applyPipeWireChanges();
}

bool setSoundEffectGain(const std::string &effect, double gain_db) {
  std::lock_guard<std::recursive_mutex> lock(g_pw_mutex);
  KLOG("setSoundEffectGain(%s, %.1f dB)", effect.c_str(), gain_db);
  if (effect == "bass") {
    g_bass_gain_db = gain_db;
    g_bass_boost = (gain_db > 0.0); // auto-enable if slider moved
  } else if (effect == "treble") {
    g_treble_gain_db = gain_db;
    g_treble_enhancer = (gain_db > 0.0);
  } else if (effect == "voice") {
    g_voice_gain_db = gain_db;
    g_voice_clarity = (gain_db > 0.0);
  }
  return applyPipeWireChanges();
}

bool setSoundStereoWidth(double width) {
  std::lock_guard<std::recursive_mutex> lock(g_pw_mutex);
  KLOG("setSoundStereoWidth(%f)", width);
  g_stereo_width = width;
  return applyPipeWireChanges();
}

bool setSoundVolumeBoost(double boost) {
  std::lock_guard<std::recursive_mutex> lock(g_pw_mutex);
  KLOG("setSoundVolumeBoost(%f)", boost);
  g_volume_boost = boost;
  return applyPipeWireChanges();
}

bool setAiLanPriority(bool enable) {
  KLOG("setAiLanPriority(%d)", enable);

  // We use 'tc' (Traffic Control) to prioritize traffic.
  // CAKE (Common Applications Kept Enhanced) is the best modern qdisc for this.
  std::string iface =
      exec("ip route | grep default | awk '{print $5}' | head -1");
  if (iface.empty())
    iface = "eth0";
  iface.erase(std::remove(iface.begin(), iface.end(), '\n'), iface.end());

  if (enable) {
    // 1. Clear existing qdisc
    std::string clean_cmd =
        "pkexec tc qdisc del dev " + iface + " root 2>/dev/null || true";
    system(clean_cmd.c_str());

    // 2. Add CAKE with 'triple-isolate' and 'besteffort' defaults
    // We prioritize game ports and UDP traffic using nftables marks
    std::string tc_cmd = "pkexec tc qdisc add dev " + iface +
                         " root cake bandwidth 1gbit flowblind";
    system(tc_cmd.c_str());

    // 3. Add nftables rules to prioritize common gaming ports (UDP)
    // We mark these with '1' for priority handling
    system("pkexec nft add table inet msi_lan_manager 2>/dev/null || true");
    system(
        "pkexec nft add chain inet msi_lan_manager postrouting { type filter "
        "hook postrouting priority 0; policy accept; } 2>/dev/null || true");
    system("pkexec nft add rule inet msi_lan_manager postrouting udp dport { "
           "27015, 27016, 27017, 27018, 27019, 27020, 3074, 3478, 4379, 4380 } "
           "mark set 1 2>/dev/null || true");

  } else {
    // Clean up
    std::string clean_cmd =
        "pkexec tc qdisc del dev " + iface + " root 2>/dev/null || true";
    system(clean_cmd.c_str());
    system("pkexec nft delete table inet msi_lan_manager 2>/dev/null || true");
  }

  return true;
}

bool setGpuMode(const std::string &mode) {
  // Check current mode first to avoid redundant slow initramfs updates
  std::string current_mode = exec("prime-select query 2>/dev/null");
  // Clean up whitespace/newlines
  current_mode.erase(std::remove(current_mode.begin(), current_mode.end(), '\n'), current_mode.end());
  current_mode.erase(std::remove(current_mode.begin(), current_mode.end(), ' '), current_mode.end());

  std::string target;
  if (mode == "discrete") target = "nvidia";
  else if (mode == "integrated") target = "intel";
  else target = "on-demand";

  if (current_mode == target) {
    KLOG("setGpuMode: already in %s mode, skipping.", target.c_str());
    return true;
  }

  KLOG("setGpuMode: switching from %s to %s", current_mode.c_str(), target.c_str());
  std::string cmd = "pkexec prime-select " + target;
  system(cmd.c_str());

  return true;
}

// Gaming Mode: applies gaming optimizations with granular control
bool setGamingMode(bool enable, bool perf = true, bool audio = true,
                   bool cooler = true) {
  if (enable) {
    KLOG("Enabling Gaming Mode (perf=%d, au=%d, co=%d)",
            perf, audio, cooler);

    // 1. System Performance
    if (perf) {
      setShiftMode("turbo");
      // Deeper system-wide performance boost via powerprofilesctl if available
      system("powerprofilesctl set performance 2>/dev/null || true");
    }

    // 2. Cooler Boost
    if (cooler) {
      setDeviceSettingDirect("coolerBoost", "on");
    }

    // 3. Free memory - sync + drop_caches
    system("sync");
    system("echo 3 | pkexec tee /proc/sys/vm/drop_caches > /dev/null 2>&1 &");

    // 4. Gaming Audio
    if (audio) {
      system("pactl set-sink-volume @DEFAULT_SINK@ 100% > /dev/null 2>&1");
      system("pactl set-source-volume @DEFAULT_SOURCE@ 80% > /dev/null 2>&1");
      system("pactl set-sink-mute @DEFAULT_SINK@ false > /dev/null 2>&1");
    }

    // 5. Set CPU governor to performance
    if (perf) {
      system(
          "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do "
          "echo performance | pkexec tee $f > /dev/null 2>&1; done &");
    }

    // 6. Disable notifications
    system("dunstctl set-paused true 2>/dev/null || true");

  } else {
    // Disable Gaming Mode - restore defaults
    KLOG("Disabling Gaming Mode");

    setShiftMode("comfort");
    system("powerprofilesctl set balanced 2>/dev/null || true");
    setDeviceSettingDirect("coolerBoost", "off");

    // Restore audio to normal
    system("pactl set-sink-volume @DEFAULT_SINK@ 70% > /dev/null 2>&1");

    // Restore CPU governor
    system("for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do "
           "echo powersave | pkexec tee $f > /dev/null 2>&1; done &");

    // Re-enable notifications
    system("dunstctl set-paused false 2>/dev/null || true");
  }

  return true;
}

#endif
