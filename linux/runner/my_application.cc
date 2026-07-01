#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include "msi_handler.h"

static void method_call_handler(FlMethodChannel *channel,
                                FlMethodCall *method_call, gpointer user_data) {
  const gchar *method = fl_method_call_get_name(method_call);
  FlValue *args = fl_method_call_get_args(method_call);

  std::string method_str(method);

  if (method_str == "initialize") {
    ensureMsiDspServiceRunning(); // Start the Rust DSP service
    bool available = checkMsiEcAvailable();
    g_autoptr(FlMethodSuccessResponse) response =
        fl_method_success_response_new(fl_value_new_bool(available));
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
    return;
  }

  if (method_str == "getSystemInfoDirect") {
    g_autoptr(FlValue) result = getSystemInfoDirect();
    g_autoptr(FlMethodSuccessResponse) response =
        fl_method_success_response_new(result);
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
    return;
  }

  if (method_str == "getSystemInfoFallback") {
    g_autoptr(FlValue) result = getSystemInfoFallback();
    g_autoptr(FlMethodSuccessResponse) response =
        fl_method_success_response_new(result);
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
    return;
  }

  if (method_str == "getFanInfoDirect") {
    g_autoptr(FlValue) result = getFanInfoDirect();
    g_autoptr(FlMethodSuccessResponse) response =
        fl_method_success_response_new(result);
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
    return;
  }

  if (method_str == "getFanInfoFallback") {
    g_autoptr(FlValue) result = getFanInfoFallback();
    g_autoptr(FlMethodSuccessResponse) response =
        fl_method_success_response_new(result);
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
    return;
  }

  if (method_str == "getDeviceSettingsFallback") {
    g_autoptr(FlValue) result = getDeviceSettingsFallback();
    g_autoptr(FlMethodSuccessResponse) response =
        fl_method_success_response_new(result);
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
    return;
  }

  if (method_str == "getSystemInfo" || method_str == "getFanInfo") {
    g_autoptr(FlMethodErrorResponse) response = fl_method_error_response_new(
        "DBUS_NOT_AVAILABLE", "D-Bus service not available", nullptr);
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
    return;
  }

  if (method_str == "setMode") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) key = fl_value_new_string("mode");
    FlValue *mode_arg = fl_value_lookup(args, key);
    if (mode_arg != nullptr &&
        fl_value_get_type(mode_arg) == FL_VALUE_TYPE_STRING) {
      std::string mode = fl_value_get_string(mode_arg);
      bool success = setShiftMode(mode);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setSuperBattery") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) key = fl_value_new_string("enable");
    FlValue *enable_arg = fl_value_lookup(args, key);
    if (enable_arg != nullptr &&
        fl_value_get_type(enable_arg) == FL_VALUE_TYPE_BOOL) {
      bool enable = fl_value_get_bool(enable_arg);
      bool success = setSuperBattery(enable);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setBatteryLimit") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) key = fl_value_new_string("limit");
    FlValue *limit_arg = fl_value_lookup(args, key);
    if (limit_arg != nullptr &&
        fl_value_get_type(limit_arg) == FL_VALUE_TYPE_INT) {
      int limit = fl_value_get_int(limit_arg);
      bool success = setBatteryLimit(limit);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setFanSpeed") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_index = fl_value_new_string("index");
    g_autoptr(FlValue) k_rpm = fl_value_new_string("rpm");
    FlValue *index_arg = fl_value_lookup(args, k_index);
    FlValue *rpm_arg = fl_value_lookup(args, k_rpm);
    if (index_arg != nullptr && rpm_arg != nullptr &&
        fl_value_get_type(index_arg) == FL_VALUE_TYPE_INT &&
        fl_value_get_type(rpm_arg) == FL_VALUE_TYPE_INT) {
      int index = fl_value_get_int(index_arg);
      int rpm = fl_value_get_int(rpm_arg);
      bool success = setFanSpeed(index, rpm);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setFanMode") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) key = fl_value_new_string("mode");
    FlValue *mode_arg = fl_value_lookup(args, key);
    if (mode_arg != nullptr &&
        fl_value_get_type(mode_arg) == FL_VALUE_TYPE_STRING) {
      std::string mode = fl_value_get_string(mode_arg);
      bool success = setFanMode(mode);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setFanModeUnified") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) key = fl_value_new_string("mode");
    FlValue *mode_arg = fl_value_lookup(args, key);
    if (mode_arg != nullptr &&
        fl_value_get_type(mode_arg) == FL_VALUE_TYPE_STRING) {
      std::string mode = fl_value_get_string(mode_arg);
      bool success = false;
      if (mode == "auto") {
        success = setFanMode("auto");
        setDeviceSettingDirect("cooler_boost", "off");
      } else if (mode == "coolerBoost") {
        success = setDeviceSettingDirect("cooler_boost", "on");
      } else if (mode == "manual") {
        success = setFanMode("basic");
        setDeviceSettingDirect("cooler_boost", "off");
      }

      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "getDeviceSettingsDirect") {
    g_autoptr(FlValue) result = getDeviceSettingsDirect();
    g_autoptr(FlMethodSuccessResponse) response =
        fl_method_success_response_new(result);
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
    return;
  }

  if (method_str == "setDeviceSetting") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_key = fl_value_new_string("key");
    g_autoptr(FlValue) k_val = fl_value_new_string("value");
    FlValue *key_arg = fl_value_lookup(args, k_key);
    FlValue *value_arg = fl_value_lookup(args, k_val);
    if (key_arg != nullptr && value_arg != nullptr &&
        fl_value_get_type(key_arg) == FL_VALUE_TYPE_STRING) {
      std::string key = fl_value_get_string(key_arg);
      std::string value;
      if (fl_value_get_type(value_arg) == FL_VALUE_TYPE_BOOL) {
        value = fl_value_get_bool(value_arg) ? "on" : "off";
      } else if (fl_value_get_type(value_arg) == FL_VALUE_TYPE_STRING) {
        value = fl_value_get_string(value_arg);
      } else {
        return;
      }
      bool success = setDeviceSettingDirect(key, value);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "getKeyboardBacklight") {
    int brightness = getKeyboardBrightness();
    FlValue *result = fl_value_new_map();
    fl_value_set_take(result, fl_value_new_string("brightness"),
                      fl_value_new_int(brightness >= 0 ? brightness : 0));
    g_autoptr(FlMethodSuccessResponse) response =
        fl_method_success_response_new(result);
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                           nullptr);
    return;
  }

  if (method_str == "setKeyboardBacklight") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_br = fl_value_new_string("brightness");
    FlValue *brightness_arg = fl_value_lookup(args, k_br);
    if (brightness_arg != nullptr &&
        fl_value_get_type(brightness_arg) == FL_VALUE_TYPE_INT) {
      int brightness = fl_value_get_int(brightness_arg);
      bool success = setKeyboardBacklight(brightness);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "freeUpMemory") {
    bool success = freeUpMemory();
    g_autoptr(FlMethodSuccessResponse) response =
        fl_method_success_response_new(fl_value_new_bool(success));
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
    return;
  }

  if (method_str == "setSoundProfile") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_pr = fl_value_new_string("profile");
    FlValue *profile_arg = fl_value_lookup(args, k_pr);
    if (profile_arg != nullptr &&
        fl_value_get_type(profile_arg) == FL_VALUE_TYPE_STRING) {
      std::string profile = fl_value_get_string(profile_arg);
      bool success = setSoundProfile(profile);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setSoundEQ") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_gains = fl_value_new_string("gains");
    FlValue *gains_arg = fl_value_lookup(args, k_gains);
    if (gains_arg != nullptr &&
        fl_value_get_type(gains_arg) == FL_VALUE_TYPE_LIST) {
      std::vector<double> gains;
      for (size_t i = 0; i < fl_value_get_length(gains_arg); i++) {
        FlValue *v = fl_value_get_list_value(gains_arg, i);
        if (fl_value_get_type(v) == FL_VALUE_TYPE_FLOAT) {
          gains.push_back(fl_value_get_float(v));
        } else if (fl_value_get_type(v) == FL_VALUE_TYPE_INT) {
          gains.push_back((double)fl_value_get_int(v));
        }
      }
      bool success = setSoundEQ(gains);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setAiLanPriority") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_en = fl_value_new_string("enable");
    FlValue *enable_arg = fl_value_lookup(args, k_en);
    if (enable_arg != nullptr &&
        fl_value_get_type(enable_arg) == FL_VALUE_TYPE_BOOL) {
      bool enable = fl_value_get_bool(enable_arg);
      bool success = setAiLanPriority(enable);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setSoundEnhancement") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_enh = fl_value_new_string("enhancement");
    g_autoptr(FlValue) k_en = fl_value_new_string("enable");
    FlValue *enh_arg = fl_value_lookup(args, k_enh);
    FlValue *en_arg = fl_value_lookup(args, k_en);
    if (enh_arg != nullptr && en_arg != nullptr &&
        fl_value_get_type(enh_arg) == FL_VALUE_TYPE_STRING &&
        fl_value_get_type(en_arg) == FL_VALUE_TYPE_BOOL) {
      bool success = setSoundEnhancement(fl_value_get_string(enh_arg),
                                         fl_value_get_bool(en_arg));
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setSoundEffectGain") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_eff = fl_value_new_string("effect");
    g_autoptr(FlValue) k_gain = fl_value_new_string("gain");
    FlValue *eff_arg = fl_value_lookup(args, k_eff);
    FlValue *gain_arg = fl_value_lookup(args, k_gain);
    if (eff_arg != nullptr && gain_arg != nullptr &&
        fl_value_get_type(eff_arg) == FL_VALUE_TYPE_STRING &&
        (fl_value_get_type(gain_arg) == FL_VALUE_TYPE_FLOAT ||
         fl_value_get_type(gain_arg) == FL_VALUE_TYPE_INT)) {
      double gain_val = fl_value_get_type(gain_arg) == FL_VALUE_TYPE_FLOAT
                            ? fl_value_get_float(gain_arg)
                            : (double)fl_value_get_int(gain_arg);
      bool success = setSoundEffectGain(fl_value_get_string(eff_arg), gain_val);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setSoundSampleRate") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_hz = fl_value_new_string("hertz");
    FlValue *hz_arg = fl_value_lookup(args, k_hz);
    if (hz_arg != nullptr && fl_value_get_type(hz_arg) == FL_VALUE_TYPE_INT) {
      bool success = setSoundSampleRate(fl_value_get_int(hz_arg));
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setSoundStereoWidth") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_width = fl_value_new_string("width");
    FlValue *width_arg = fl_value_lookup(args, k_width);
    if (width_arg != nullptr) {
      double width = 1.0;
      if (fl_value_get_type(width_arg) == FL_VALUE_TYPE_FLOAT) {
        width = fl_value_get_float(width_arg);
      } else if (fl_value_get_type(width_arg) == FL_VALUE_TYPE_INT) {
        width = (double)fl_value_get_int(width_arg);
      }
      bool success = setSoundStereoWidth(width);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setSoundVolumeBoost") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_boost = fl_value_new_string("boost");
    FlValue *boost_arg = fl_value_lookup(args, k_boost);
    if (boost_arg != nullptr) {
      double boost = 1.0;
      if (fl_value_get_type(boost_arg) == FL_VALUE_TYPE_FLOAT) {
        boost = fl_value_get_float(boost_arg);
      } else if (fl_value_get_type(boost_arg) == FL_VALUE_TYPE_INT) {
        boost = (double)fl_value_get_int(boost_arg);
      }
      setSoundVolumeBoost(boost);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(true));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "cleanUpDisk") {
    bool success = cleanUpDisk();
    g_autoptr(FlMethodSuccessResponse) response =
        fl_method_success_response_new(fl_value_new_bool(success));
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
    return;
  }

  if (method_str == "setSmartPriority") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_apps = fl_value_new_string("apps");
    FlValue *apps_arg = fl_value_lookup(args, k_apps);
    if (apps_arg != nullptr && fl_value_get_type(apps_arg) == FL_VALUE_TYPE_LIST) {
      std::vector<std::string> apps;
      for (size_t i = 0; i < fl_value_get_length(apps_arg); ++i) {
        FlValue *app_val = fl_value_get_list_value(apps_arg, i);
        if (fl_value_get_type(app_val) == FL_VALUE_TYPE_STRING) {
          apps.push_back(fl_value_get_string(app_val));
        }
      }
      bool success = setSmartPriority(apps);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
      return;
    }
  }

  if (method_str == "openFile") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) return;
    g_autoptr(FlValue) k_path = fl_value_new_string("path");
    FlValue *path_arg = fl_value_lookup(args, k_path);
    if (path_arg != nullptr && fl_value_get_type(path_arg) == FL_VALUE_TYPE_STRING) {
      openFile(fl_value_get_string(path_arg));
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(true));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
      return;
    }
  }

  if (method_str == "setGpuMode") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;
    g_autoptr(FlValue) k_mode = fl_value_new_string("mode");
    FlValue *mode_arg = fl_value_lookup(args, k_mode);
    if (mode_arg != nullptr &&
        fl_value_get_type(mode_arg) == FL_VALUE_TYPE_STRING) {
      std::string mode = fl_value_get_string(mode_arg);
      bool success = setGpuMode(mode);
      g_autoptr(FlMethodSuccessResponse) response =
          fl_method_success_response_new(fl_value_new_bool(success));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response),
                             nullptr);
      return;
    }
  }

  if (method_str == "setGamingMode") {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
      return;

    g_autoptr(FlValue) k_enable = fl_value_new_string("enable");
    g_autoptr(FlValue) k_perf = fl_value_new_string("perf");
    g_autoptr(FlValue) k_audio = fl_value_new_string("audio");
    g_autoptr(FlValue) k_cooler = fl_value_new_string("cooler");

    FlValue *enable_arg = fl_value_lookup(args, k_enable);
    FlValue *perf_arg = fl_value_lookup(args, k_perf);
    FlValue *audio_arg = fl_value_lookup(args, k_audio);
    FlValue *cooler_arg = fl_value_lookup(args, k_cooler);

    bool enable =
        (enable_arg && fl_value_get_type(enable_arg) == FL_VALUE_TYPE_BOOL)
            ? fl_value_get_bool(enable_arg)
            : false;
    bool perf = (perf_arg && fl_value_get_type(perf_arg) == FL_VALUE_TYPE_BOOL)
                    ? fl_value_get_bool(perf_arg)
                    : true;
    bool audio =
        (audio_arg && fl_value_get_type(audio_arg) == FL_VALUE_TYPE_BOOL)
            ? fl_value_get_bool(audio_arg)
            : true;
    bool cooler =
        (cooler_arg && fl_value_get_type(cooler_arg) == FL_VALUE_TYPE_BOOL)
            ? fl_value_get_bool(cooler_arg)
            : true;

    bool success = setGamingMode(enable, perf, audio, cooler);
    g_autoptr(FlMethodSuccessResponse) response =
        fl_method_success_response_new(fl_value_new_bool(success));
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
    return;
  }

  g_autoptr(FlMethodNotImplementedResponse) response =
      fl_method_not_implemented_response_new();
  fl_method_call_respond(method_call, FL_METHOD_RESPONSE(response), nullptr);
}

struct _MyApplication {
  GtkApplication parent_instance;
  char **dart_entrypoint_arguments;
  FlMethodChannel *channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void first_frame_cb(MyApplication *self, FlView *view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

static void my_application_activate(GApplication *application) {
  MyApplication *self = MY_APPLICATION(application);
  GtkWindow *window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen *screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar *wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar *header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "MSI Controller");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "MSI Controller");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView *view = fl_view_new(project);
  GdkRGBA background_color;
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  FlEngine *engine = fl_view_get_engine(view);
  self->channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(engine), "msi_controller/channel",
      FL_METHOD_CODEC(fl_standard_method_codec_new()));
  fl_method_channel_set_method_call_handler(self->channel, method_call_handler,
                                            nullptr, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

static gboolean my_application_local_command_line(GApplication *application,
                                                  gchar ***arguments,
                                                  int *exit_status) {
  MyApplication *self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

static void my_application_startup(GApplication *application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

static void my_application_shutdown(GApplication *application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

static void my_application_dispose(GObject *object) {
  MyApplication *self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  if (self->channel) {
    g_object_unref(self->channel);
    self->channel = nullptr;
  }
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass *klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication *self) {
  self->channel = nullptr;
}

MyApplication *my_application_new() {
  g_set_prgname("msi_controller");

  return MY_APPLICATION(g_object_new(
      my_application_get_type(), "application-id", "com.msi.controller",
      "flags", G_APPLICATION_NON_UNIQUE, nullptr));
}
