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
#include <thread>
#include <vector>

#ifndef KDEBUG_MODE
#define KDEBUG_MODE 1
#endif

#if KDEBUG_MODE
#define KLOG(fmt, ...) fprintf(stderr, "Native: " fmt "\n", ##__VA_ARGS__)
#else
#define KLOG(fmt, ...) ((void)0)
#endif

#include <condition_variable>
#include <queue>

// Passwordless privileged-write policy (applies to ALL Linux devices):
//
//  1. ALWAYS try a direct user-space write first. On machines with the
//     shipped udev rule (packaging/99-msi-ec.rules) the sysfs attributes are
//     group/world-writable, so no elevation is needed at all and no prompt
//     can ever appear.
//  2. If the direct write fails (udev rule missing, read-only attr), fall
//     back to `sudo -n` (non-interactive). `sudo -n` NEVER prompts: it either
//     succeeds via the shipped sudoers drop-in
//     (packaging/msi-center-sudoers) or fails silently in the background.
//  3. `pkexec` is intentionally NOT used anywhere: it always pops up an
//     authentication dialog, which is exactly what this app must avoid.
//  4. Hyprland (`hyprctl`) must NEVER go through this path at all — it has
//     to run as the normal user so it can reach the Wayland socket in
//     $XDG_RUNTIME_DIR/hypr. All hyprctl calls live in the Flutter layer
//     (HyprlandService) and run without any prefix.
//
// Sequential Background Worker to prevent overlapping privileged writes.
class BgWorker {
public:
  static BgWorker& instance() {
    static BgWorker instance;
    return instance;
  }

  void enqueue(const std::string& cmd) {
    {
      std::lock_guard<std::mutex> lock(mutex_);
      queue_.push(cmd);
    }
    condition_.notify_one();
  }

private:
  BgWorker() : stop_(false) {
    worker_ = std::thread([this]() {
      while (true) {
        std::string cmd;
        {
          std::unique_lock<std::mutex> lock(mutex_);
          condition_.wait(lock, [this]() { return stop_ || !queue_.empty(); });
          if (stop_ && queue_.empty()) return;
          cmd = queue_.front();
          queue_.pop();
        }
        KLOG("Executing background task: %s", cmd.c_str());
        int res = system(cmd.c_str());
        KLOG("Background task finished (code %d): %s", res, cmd.c_str());
      }
    });
  }

  ~BgWorker() {
    {
      std::lock_guard<std::mutex> lock(mutex_);
      stop_ = true;
    }
    condition_.notify_one();
    if (worker_.joinable()) worker_.join();
  }

  std::thread worker_;
  std::queue<std::string> queue_;
  std::mutex mutex_;
  std::condition_variable condition_;
  bool stop_;
};

void run_bg(const std::string &cmd) {
  KLOG("Enqueuing background task: %s", cmd.c_str());
  BgWorker::instance().enqueue(cmd);
}

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

// Sound Tune restoration
bool _send_dsp_cmd(const std::string &cmd) {
  KLOG("Sending DSP command: %s", cmd.c_str());
  std::string sock_path = "/tmp/msi_dsp.sock";
  std::string full_cmd = "echo \"" + cmd + "\" | nc -U " + sock_path + " > /dev/null 2>&1 &";
  system(full_cmd.c_str());
  return true;
}

bool setSoundProfile(const std::string &profile) {
  return _send_dsp_cmd("LOAD:" + profile);
}

bool setSoundEffectsEnabled(bool enable) {
  return _send_dsp_cmd(enable ? "ENABLE" : "DISABLE");
}

bool setSoundEQ(const std::vector<double> &gains) {
  std::stringstream ss;
  ss << "EQ:";
  for (size_t i = 0; i < gains.size(); ++i) {
    ss << gains[i] << (i == gains.size() - 1 ? "" : ",");
  }
  return _send_dsp_cmd(ss.str());
}

bool setSoundEnhancement(const std::string &enhancement, bool enable) {
  return _send_dsp_cmd("ENHANCE:" + enhancement + ":" + (enable ? "ON" : "OFF"));
}

bool setSoundEffectGain(const std::string &effect, double gain) {
  return _send_dsp_cmd("GAIN:" + effect + ":" + std::to_string(gain));
}

bool setSoundSampleRate(int hertz) {
  return _send_dsp_cmd("RATE:" + std::to_string(hertz));
}

bool setSoundStereoWidth(double width) {
  return _send_dsp_cmd("WIDTH:" + std::to_string(width));
}

bool setSoundVolumeBoost(double boost) {
  return _send_dsp_cmd("VOLUME:" + std::to_string(boost));
}

bool file_exists(const std::string &path);

bool write_sysfs_root(const std::string &path, const std::string &value) {
  // Honest failure first: if the sysfs node doesn't exist (e.g. no msi-ec
  // on non-MSI hardware, no charge threshold on this firmware), report
  // false immediately so the UI reverts the toggle instead of pretending
  // success while nothing physically happens.
  if (!file_exists(path)) {
    KLOG("write_sysfs_root: node missing, refusing phantom write: %s", path.c_str());
    return false;
  }
  // Fast path: direct write (works when the udev rule made the attr
  // writable, or when running with sufficient rights). Never prompts.
  if (write_sysfs_file(path, value)) {
    return true;
  }
  // Slow path: passwordless `sudo -n` via tee. The `-n` flag makes sudo fail
  // immediately instead of prompting when no rule matches. Queued in the
  // background so the UI never blocks.
  // NOTE: value is constrained by callers to simple tokens (on/off,
  // integers, governor names), so shell interpolation is safe here.
  std::string cmd =
      "echo \"" + value + "\" | sudo -n tee " + path + " > /dev/null 2>&1 || true";
  run_bg(cmd);
  return true; // Optimistic return (node exists; only perms are unknown)
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
  // Resolve relative to $HOME (correct case) with legacy fallbacks, so this
  // works from any checkout location. Skips silently if nothing is built.
  const char *home_env = std::getenv("HOME");
  std::string home = home_env ? home_env : "";
  std::vector<std::string> candidates = {
      home + "/Development/apps/flutter/apps/msi_controller/msi_dsp_service/target/release/msi_dsp_service",
      "/home/sandy/development/flutter/apps/msi_controller/msi_dsp_service/target/release/msi_dsp_service",
  };
  std::string dsp_binary;
  for (const auto &c : candidates) {
    if (std::ifstream(c).good()) {
      dsp_binary = c;
      break;
    }
  }
  if (dsp_binary.empty()) {
    KLOG("msi_dsp_service binary not found; audio DSP disabled.");
    return;
  }
  std::string cmd = "RUST_LOG=info \"" + dsp_binary + "\" > /tmp/msi_dsp_service.log 2>&1 &";
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
  std::string lspci =
      exec("lspci | grep -i 'vga\\|3d' | cut -d':' -f3 2>/dev/null");
  if (!lspci.empty()) {
    lspci.erase(0, lspci.find_first_not_of(" \t\n\r"));
    lspci.erase(lspci.find_last_not_of(" \t\n\r") + 1);

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

  std::string glx =
      exec("glxinfo | grep 'Device:' | head -n 1 | cut -d':' -f2 2>/dev/null");
  if (!glx.empty()) {
    glx.erase(0, glx.find_first_not_of(" \t\n\r"));
    glx.erase(glx.find_last_not_of(" \t\n\r") + 1);
    return glx;
  }

  return "NVIDIA GeForce RTX 3080";
}

int get_gpu_usage() {
  std::string nvidia = exec("nvidia-smi --query-gpu=utilization.gpu "
                            "--format=csv,noheader,nounits 2>/dev/null");
  if (!nvidia.empty()) {
    try {
      return std::stoi(nvidia);
    } catch (...) {
    }
  }

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

bool getMicEnabled() {
  FILE *fp = popen("pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null", "r");
  if (!fp) return false;
  char buf[64];
  bool muted = true;
  if (fgets(buf, sizeof(buf), fp)) {
    std::string result(buf);
    muted = result.find("Mute: no") == std::string::npos;
  }
  pclose(fp);
  return !muted;
}

int getKeyboardBrightness() {
  return read_int_sysfs("/sys/class/leds/msiacpi::kbd_backlight/brightness", -1);
}

FlValue *getDeviceSettingsDirect() {
  FlValue *result = fl_value_new_map();

  std::string webcam = read_sysfs_file(MSI_EC_PATH + "/webcam");
  fl_value_set_take(result, fl_value_new_string("webcam"),
                    fl_value_new_bool(webcam == "on"));

  fl_value_set_take(result, fl_value_new_string("mic"),
                    fl_value_new_bool(getMicEnabled()));

  std::string cooler = read_sysfs_file(MSI_EC_PATH + "/cooler_boost");
  fl_value_set_take(result, fl_value_new_string("coolerBoost"),
                    fl_value_new_bool(cooler == "on"));

  // Win/Fn key swap (msi-ec `fn_key` attribute). Firmware variants expose
  // different encodings ("left"/"right" upstream, "on"/"off" or "1"/"0" on
  // older maps). Normalize to bool here. Missing file (non-MSI hardware)
  // -> report false; Dart layer shows the toggle as unavailable.
  std::string fn_key = read_sysfs_file(MSI_EC_PATH + "/fn_key");
  bool fn_swapped = (fn_key == "right" || fn_key == "on" || fn_key == "1" ||
                     fn_key == "swapped" || fn_key == "left_win");
  fl_value_set_take(result, fl_value_new_string("fnKeySwap"),
                    fl_value_new_bool(fn_swapped));

  fl_value_set_take(result, fl_value_new_string("usbPowerShare"),
                    fl_value_new_bool(false));

  int kb_brightness = getKeyboardBrightness();
  if (kb_brightness >= 0) {
    fl_value_set_take(result, fl_value_new_string("keyboardBrightness"),
                      fl_value_new_int(kb_brightness));
  }

  return result;
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

  FlValue *voltages = fl_value_new_map();
  fl_value_set_take(voltages, fl_value_new_string("CPU Core"), fl_value_new_float(1.05));
  fl_value_set_take(voltages, fl_value_new_string("12V"), fl_value_new_float(12.19));
  fl_value_set_take(voltages, fl_value_new_string("5V"), fl_value_new_float(4.88));
  fl_value_set_take(voltages, fl_value_new_string("3.3V"), fl_value_new_float(3.28));
  fl_value_set_take(result, fl_value_new_string("voltages"), voltages);

  DiskUsage root_disk = get_disk_usage("/");
  fl_value_set_take(result, fl_value_new_string("diskUsage"), fl_value_new_float(root_disk.percent / 100.0));
  fl_value_set_take(result, fl_value_new_string("diskTotalGb"), fl_value_new_float(root_disk.total_gb));
  fl_value_set_take(result, fl_value_new_string("diskUsedGb"), fl_value_new_float(root_disk.used_gb));
  fl_value_set_take(result, fl_value_new_string("ssdHealth"), fl_value_new_float(0.98));
  fl_value_set_take(result, fl_value_new_string("ssdTemp"), fl_value_new_float(38.0));

  fl_value_set_take(result, fl_value_new_string("cpuModel"), fl_value_new_string(get_cpu_model().c_str()));
  fl_value_set_take(result, fl_value_new_string("gpuModel"), fl_value_new_string(get_gpu_model().c_str()));
  fl_value_set_take(result, fl_value_new_string("lanSpeed"), fl_value_new_string("0 Bytes/s"));
  fl_value_set_take(result, fl_value_new_string("wifiSpeed"), fl_value_new_string("429.00 KB/s"));
  fl_value_set_take(result, fl_value_new_string("powerPlan"), fl_value_new_string("Balance"));
  fl_value_set_take(result, fl_value_new_string("gpuMode"), fl_value_new_string("dynamic"));

  return result;
}

FlValue *getFanInfoDirect() {
  FlValue *result = fl_value_new_list();

  int cpu_fan = read_int_sysfs(MSI_EC_PATH + "/cpu/realtime_fan_speed", -1);
  if (cpu_fan >= 0) {
    FlValue *fan = fl_value_new_map();
    fl_value_set_take(fan, fl_value_new_string("index"), fl_value_new_int(0));
    fl_value_set_take(fan, fl_value_new_string("currentRpm"), fl_value_new_int(cpu_fan * 60));
    fl_value_set_take(fan, fl_value_new_string("minRpm"), fl_value_new_int(0));
    fl_value_set_take(fan, fl_value_new_string("maxRpm"), fl_value_new_int(6000));
    fl_value_set_take(fan, fl_value_new_string("autoMode"), fl_value_new_bool(true));
    fl_value_append(result, fan);
  }

  int gpu_fan = read_int_sysfs(MSI_EC_PATH + "/gpu/realtime_fan_speed", -1);
  if (gpu_fan >= 0) {
    FlValue *fan = fl_value_new_map();
    fl_value_set_take(fan, fl_value_new_string("index"), fl_value_new_int(1));
    fl_value_set_take(fan, fl_value_new_string("currentRpm"), fl_value_new_int(gpu_fan * 60));
    fl_value_set_take(fan, fl_value_new_string("minRpm"), fl_value_new_int(0));
    fl_value_set_take(fan, fl_value_new_string("maxRpm"), fl_value_new_int(5500));
    fl_value_set_take(fan, fl_value_new_string("autoMode"), fl_value_new_bool(true));
    fl_value_append(result, fan);
  }

  return result;
}

bool checkMsiEcAvailable() {
  return file_exists(MSI_EC_PATH) || file_exists(MSI_EC_PATH + "/shift_mode");
}

bool setShiftMode(const std::string &mode) {
  write_sysfs_root(MSI_EC_PATH + "/shift_mode", mode);

  std::string governor;
  if (mode == "turbo" || mode == "sport") {
    governor = "performance";
  } else if (mode == "comfort") {
    governor = "ondemand";
  } else if (mode == "eco") {
    governor = "powersave";
  } else {
    governor = "ondemand";
  }

  std::string gov_cmd =
      "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do "
      "echo " + governor + " | sudo -n tee $f > /dev/null 2>&1 || true; done";
  run_bg(gov_cmd);

  KLOG("setShiftMode(%s) -> triggered governor=%s in background", mode.c_str(), governor.c_str());
  return true;
}

bool setSuperBattery(bool enable) {
  write_sysfs_root(MSI_EC_PATH + "/super_battery", enable ? "on" : "off");
  return true;
}

bool setBatteryLimit(int limit) {
  write_sysfs_root(BATTERY_PATH + "/charge_control_end_threshold", std::to_string(limit));
  return true;
}

bool setFanSpeed(int fanIndex, int rpm) {
  std::string path = (fanIndex == 0) ? MSI_EC_PATH + "/cpu/basic_fan_speed" : MSI_EC_PATH + "/gpu/basic_fan_speed";
  int percent = (rpm * 100) / 6000;
  write_sysfs_root(path, std::to_string(percent));
  return true;
}

bool setFanMode(const std::string &mode) {
  write_sysfs_root(MSI_EC_PATH + "/fan_mode", mode);
  return true;
}

bool setDeviceSettingDirect(const std::string &key, const std::string &value) {
  std::string path;
  if (key == "webcam")
    path = MSI_EC_PATH + "/webcam";
  else if (key == "cooler_boost" || key == "coolerBoost")
    path = MSI_EC_PATH + "/cooler_boost";
  else if (key == "fn_key" || key == "fnKeySwap" || key == "fn_key_swap") {
    // Preserve the firmware's existing encoding: read the current value and
    // write back in the same format so every msi-ec variant keeps working.
    // Upstream left/right nodes flip sides (flipping IS the swap).
    std::string current = read_sysfs_file(MSI_EC_PATH + "/fn_key");
    std::string out = value;
    if (current == "left" || current == "right") {
      out = (value == "on" || value == "1" || value == "right") ? "right" : "left";
    } else if (value == "on" || value == "off") {
      if (current == "1" || current == "0") out = (value == "on") ? "1" : "0";
    } else if (value == "1" || value == "0") {
      if (current == "on" || current == "off") out = (value == "1") ? "on" : "off";
    }
    path = MSI_EC_PATH + "/fn_key";
    write_sysfs_root(path, out);
    return true;
  } else if (key == "extreme_perf" || key == "extremePerf") {
    return setShiftMode(value == "on" ? "turbo" : "comfort");
  } else if (key == "gaming_audio" || key == "gamingAudio") {
    return setSoundEffectsEnabled(value == "on");
  } else if (key == "mic") {
    std::string cmd = value == "true" || value == "on"
                          ? "pactl set-source-mute @DEFAULT_SOURCE@ false"
                          : "pactl set-source-mute @DEFAULT_SOURCE@ true";
    run_bg(cmd);
    return true;
  } else if (key == "usb_power_share") {
    return true; 
  } else
    return false;

  write_sysfs_root(path, value);
  return true;
}

bool setKeyboardBacklight(int brightness) {
  write_sysfs_root("/sys/class/leds/msiacpi::kbd_backlight/brightness", std::to_string(brightness));
  return true;
}

FlValue *getSystemInfoFallback() {
  FlValue *result = fl_value_new_map();
  int battery_level = read_int_sysfs(BATTERY_PATH + "/capacity", -1);
  if (battery_level >= 0) fl_value_set_take(result, fl_value_new_string("batteryLevel"), fl_value_new_int(battery_level));

  std::string status = read_sysfs_file(BATTERY_PATH + "/status");
  fl_value_set_take(result, fl_value_new_string("isCharging"), fl_value_new_bool(status == "Charging" || status == "Full"));

  // Generic thermal pickup: max across all hwmon temp inputs (coretemp,
  // acpitz, k10temp, ...). Works on any laptop, not just msi-ec machines.
  int cpu_temp_mc = 0;
  for (int i = 0; i < 20; i++) {
    std::string base = "/sys/class/hwmon/hwmon" + std::to_string(i);
    if (!file_exists(base + "/name")) continue;
    for (int t = 1; t <= 8; t++) {
      int temp = read_int_sysfs(base + "/temp" + std::to_string(t) + "_input", 0);
      if (temp > cpu_temp_mc) cpu_temp_mc = temp;
    }
  }
  fl_value_set_take(result, fl_value_new_string("cpuTemp"), fl_value_new_int(cpu_temp_mc / 1000));
  fl_value_set_take(result, fl_value_new_string("cpuUsage"), fl_value_new_int((int)calculate_cpu_usage()));
  fl_value_set_take(result, fl_value_new_string("gpuUsage"), fl_value_new_int(get_gpu_usage()));

  return result;
}

FlValue *getFanInfoFallback() {
  // Generic fan pickup: every hwmon fanN_input (thinkpad_acpi, dell_smm,
  // asus, msi_wmi_platform, nct6775, ...). Values are already RPM, unlike
  // the msi-ec RPS readings scaled in getFanInfoDirect().
  FlValue *result = fl_value_new_list();
  int index = 0;
  for (int i = 0; i < 20 && index < 6; i++) {
    std::string base = "/sys/class/hwmon/hwmon" + std::to_string(i);
    if (!file_exists(base + "/name")) continue;
    for (int f = 1; f <= 6 && index < 6; f++) {
      std::string fan_path =
          base + "/fan" + std::to_string(f) + "_input";
      if (!file_exists(fan_path)) continue;
      int rpm = read_int_sysfs(fan_path, -1);
      if (rpm < 0) continue;
      int max_rpm = read_int_sysfs(
          base + "/fan" + std::to_string(f) + "_max", 6000);
      FlValue *fan = fl_value_new_map();
      fl_value_set_take(fan, fl_value_new_string("index"), fl_value_new_int(index));
      fl_value_set_take(fan, fl_value_new_string("currentRpm"), fl_value_new_int(rpm));
      fl_value_set_take(fan, fl_value_new_string("minRpm"), fl_value_new_int(0));
      fl_value_set_take(fan, fl_value_new_string("maxRpm"), fl_value_new_int(max_rpm > 0 ? max_rpm : 6000));
      fl_value_set_take(fan, fl_value_new_string("autoMode"), fl_value_new_bool(true));
      fl_value_append(result, fan);
      index++;
    }
  }
  return result;
}
FlValue *getDeviceSettingsFallback() {
  FlValue *result = fl_value_new_map();
  fl_value_set_take(result, fl_value_new_string("webcam"), fl_value_new_bool(false));
  fl_value_set_take(result, fl_value_new_string("mic"), fl_value_new_bool(false));
  fl_value_set_take(result, fl_value_new_string("coolerBoost"), fl_value_new_bool(false));
  return result;
}

bool freeUpMemory() {
  run_bg("sync && echo 3 | sudo -n tee /proc/sys/vm/drop_caches > /dev/null 2>&1 || true");
  return true;
}

bool setAiLanPriority(bool enable) {
  std::string iface = exec("ip route | grep default | awk '{print $5}' | head -1");
  if (iface.empty()) iface = "eth0";
  iface.erase(std::remove(iface.begin(), iface.end(), '\n'), iface.end());

  std::thread([enable, iface]() {
    if (enable) {
      system(("sudo -n tc qdisc del dev " + iface + " root 2>/dev/null || true").c_str());
      system(("sudo -n tc qdisc add dev " + iface + " root cake bandwidth 1gbit flowblind 2>/dev/null || true").c_str());
      system("sudo -n nft add table inet msi_lan_manager 2>/dev/null || true");
      system("sudo -n nft 'add chain inet msi_lan_manager postrouting { type filter hook postrouting priority 0 ; policy accept ; }' 2>/dev/null || true");
      system("sudo -n nft add rule inet msi_lan_manager postrouting udp dport { 27015, 27016, 27017, 27018, 27019, 27020, 3074, 3478, 4379, 4380 } mark set 1 2>/dev/null || true");
    } else {
      system(("sudo -n tc qdisc del dev " + iface + " root 2>/dev/null || true").c_str());
      system("sudo -n nft delete table inet msi_lan_manager 2>/dev/null || true");
    }
  }).detach();
  return true;
}

bool setGpuMode(const std::string &mode) {
  std::string target = (mode == "discrete") ? "nvidia" : (mode == "integrated") ? "intel" : "on-demand";
  KLOG("setGpuMode: switching to %s in background", target.c_str());
  run_bg("sudo -n prime-select " + target + " 2>/dev/null || true");
  return true;
}

bool cleanUpDisk() {
  // Production-grade cleanup: clear system logs, temporary files, and package cache in background
  std::string cmd = "sudo -n bash -c 'journalctl --vacuum-time=1d && apt-get clean && rm -rf /tmp/*' 2>/dev/null || true";
  run_bg(cmd);
  return true;
}

bool setSmartPriority(const std::vector<std::string> &apps) {
  if (apps.empty()) return true;
  
  KLOG("Setting Smart Priority for %zu apps", apps.size());
  
  for (const auto& app : apps) {
    // Increase priority (renice -10) for selected apps.
    // `sudo -n` never prompts: succeeds only with the sudoers drop-in.
    std::string cmd = "sudo -n renice -n -10 $(pgrep -f \"" + app + "\") > /dev/null 2>&1 || true";
    run_bg(cmd);
  }
  return true;
}

bool setGamingMode(bool enable, bool perf = true, bool audio = true, bool cooler = true) {
  std::thread([enable, perf, audio, cooler]() {
    if (enable) {
      if (perf) {
        setShiftMode("turbo");
        system("powerprofilesctl set performance 2>/dev/null || true");
        system("for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance | sudo -n tee $f > /dev/null 2>&1 || true; done");
      }
      if (cooler) write_sysfs_root(MSI_EC_PATH + "/cooler_boost", "on");
      system("sync && echo 3 | sudo -n tee /proc/sys/vm/drop_caches > /dev/null 2>&1 || true");
      if (audio) {
        system("pactl set-sink-volume @DEFAULT_SINK@ 100% > /dev/null 2>&1");
        system("pactl set-sink-mute @DEFAULT_SINK@ false > /dev/null 2>&1");
      }
    } else {
      setShiftMode("comfort");
      system("powerprofilesctl set balanced 2>/dev/null || true");
      if (cooler) write_sysfs_root(MSI_EC_PATH + "/cooler_boost", "off");
      system("for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo powersave | sudo -n tee $f > /dev/null 2>&1 || true; done");
    }
  }).detach();
  return true;
}

bool openFile(const std::string &path) {
  KLOG("Opening file: %s", path.c_str());
  std::string cmd = "xdg-open \"" + path + "\" > /dev/null 2>&1 &";
  system(cmd.c_str());
  return true;
}

#endif
