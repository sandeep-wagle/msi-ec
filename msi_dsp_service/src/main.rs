//! MSI DSP Service
//! 
//! This service handles audio profile settings via Unix socket.
//! It saves/loads profiles and manages PipeWire filter chain for audio DSP.

use anyhow::Result;
use log::{debug, error, info, warn};
use serde::{Deserialize, Serialize};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;
use std::sync::LazyLock;
use std::collections::HashMap;
use std::fs;
use std::process::Command;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::UnixListener;

const SOCKET_PATH: &str = "/tmp/msi_dsp.sock";
const PROFILE_PATH: &str = "/tmp/msi_dsp_config/profile.json";
const PROFILES_DIR: &str = "/tmp/msi_dsp_config/profiles";
const FILTER_CHAIN_CONFIG_PATH: &str = "/tmp/msi_dsp_config/pw-filter-chain.conf";

static FILTER_CHAIN_RUNNING: AtomicBool = AtomicBool::new(false);
static LAST_PROFILE_NAME: Mutex<String> = Mutex::new(String::new());
static DSP_ENABLED: AtomicBool = AtomicBool::new(true);

static PROFILE_SETTINGS: LazyLock<Mutex<HashMap<String, AudioProfile>>> = 
    LazyLock::new(|| Mutex::new(HashMap::new()));

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AudioProfile {
    pub name: String,
    pub bass: f64,
    pub treble: f64,
    pub voice: f64,
    #[serde(alias = "eqGains", alias = "eq_gains")]
    pub eq_gains: Vec<f64>,
    pub compressor: bool,
    pub surround: bool,
    pub volume: f64,
    #[serde(alias = "bufferSize", alias = "buffer_size")]
    pub buffer_size: usize,
    // Nahimic-style enhancements
    pub noise_level: f64,
    pub stereo_width: f64,
    pub limiter_enabled: bool,
    pub compressor_ratio: f64,
    pub surround_variation: String,
    pub night_mode: bool,
    pub effects_enabled: bool,
    pub mic_enabled: bool,
    pub mic_gain: f64,
    pub mic_noise_suppression: bool,
    pub echo_cancellation: bool,
    pub voice_clarity: bool,
    pub treble_enhancer: bool,
    pub bass_boost: bool,
    pub tracker_enabled: bool,
    pub sharing_enabled: bool,
}

impl Default for AudioProfile {
    fn default() -> Self {
        Self {
            name: "Default".into(),
            bass: 0.0,
            treble: 0.0,
            voice: 0.0,
            eq_gains: vec![0.0; 10],
            compressor: false,
            surround: false,
            volume: 1.0,
            buffer_size: 256,
            noise_level: 0.0,
            stereo_width: 0.0,
            limiter_enabled: false,
            compressor_ratio: 4.0,
            surround_variation: "Surround".into(),
            night_mode: false,
            effects_enabled: true,
            mic_enabled: true,
            mic_gain: 1.0,
            mic_noise_suppression: false,
            echo_cancellation: false,
            voice_clarity: false,
            treble_enhancer: false,
            bass_boost: false,
            tracker_enabled: false,
            sharing_enabled: false,
        }
    }
}

fn get_default_profile(name: &str) -> AudioProfile {
    match name {
        "Music" => AudioProfile {
            name: "Music".into(),
            bass: 8.0,
            treble: 2.0,
            voice: 4.0,
            eq_gains: vec![2.0, 1.5, 0.5, 0.0, 0.0, -1.0, -1.5, -2.0, -2.5, -3.0],
            compressor: false,
            surround: true,
            volume: 1.0,
            buffer_size: 256,
            noise_level: 2.0,
            stereo_width: 1.5,
            limiter_enabled: false,
            compressor_ratio: 3.0,
            surround_variation: "Surround".into(),
            night_mode: false,
            effects_enabled: true,
            mic_enabled: true,
            mic_gain: 1.0,
            mic_noise_suppression: false,
            echo_cancellation: false,
            voice_clarity: true,
            treble_enhancer: false,
            bass_boost: true,
            tracker_enabled: false,
            sharing_enabled: false,
        },
        "Gaming" => AudioProfile {
            name: "Gaming".into(),
            bass: 4.0,
            treble: 4.0,
            voice: 6.0,
            eq_gains: vec![0.0; 10],
            compressor: false,
            surround: true,
            volume: 1.0,
            buffer_size: 128,
            noise_level: 1.0,
            stereo_width: 2.0,
            limiter_enabled: true,
            compressor_ratio: 2.0,
            surround_variation: "Surround".into(),
            night_mode: false,
            effects_enabled: true,
            mic_enabled: true,
            mic_gain: 1.0,
            mic_noise_suppression: true,
            echo_cancellation: false,
            voice_clarity: true,
            treble_enhancer: true,
            bass_boost: true,
            tracker_enabled: false,
            sharing_enabled: false,
        },
        "Movie" => AudioProfile {
            name: "Movie".into(),
            bass: 6.0,
            treble: 3.0,
            voice: 8.0,
            eq_gains: vec![3.0, 2.0, 1.0, 0.5, 0.0, -0.5, -1.0, -1.5, -2.0, -2.5],
            compressor: true,
            surround: true,
            volume: 1.0,
            buffer_size: 256,
            noise_level: 3.0,
            stereo_width: 1.0,
            limiter_enabled: true,
            compressor_ratio: 6.0,
            surround_variation: "Headset".into(),
            night_mode: false,
            effects_enabled: true,
            mic_enabled: true,
            mic_gain: 1.0,
            mic_noise_suppression: false,
            echo_cancellation: false,
            voice_clarity: true,
            treble_enhancer: false,
            bass_boost: true,
            tracker_enabled: false,
            sharing_enabled: false,
        },
        "Voice" | "Communication" => AudioProfile {
            name: name.into(),
            bass: 2.0,
            treble: 6.0,
            voice: 10.0,
            eq_gains: vec![-2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 2.0, 1.0, 0.0, -1.0],
            compressor: true,
            surround: false,
            volume: 1.0,
            buffer_size: 256,
            noise_level: 5.0,
            stereo_width: 0.5,
            limiter_enabled: true,
            compressor_ratio: 8.0,
            surround_variation: "Surround".into(),
            night_mode: false,
            effects_enabled: true,
            mic_enabled: true,
            mic_gain: 1.2,
            mic_noise_suppression: true,
            echo_cancellation: true,
            voice_clarity: true,
            treble_enhancer: true,
            bass_boost: true,
            tracker_enabled: false,
            sharing_enabled: false,
        },
        "Smart" => AudioProfile {
            name: "Smart".into(),
            bass: 5.0,
            treble: 3.0,
            voice: 5.0,
            eq_gains: vec![1.0, 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            compressor: true,
            surround: true,
            volume: 1.0,
            buffer_size: 256,
            noise_level: 2.5,
            stereo_width: 1.5,
            limiter_enabled: true,
            compressor_ratio: 4.0,
            surround_variation: "Surround".into(),
            night_mode: false,
            effects_enabled: true,
            mic_enabled: true,
            mic_gain: 1.0,
            mic_noise_suppression: true,
            echo_cancellation: false,
            voice_clarity: true,
            treble_enhancer: true,
            bass_boost: true,
            tracker_enabled: false,
            sharing_enabled: false,
        },
        "Custom" => AudioProfile {
            name: "Custom".into(),
            bass: 0.0,
            treble: 0.0,
            voice: 0.0,
            eq_gains: vec![0.0; 10],
            compressor: false,
            surround: false,
            volume: 1.0,
            buffer_size: 256,
            noise_level: 0.0,
            stereo_width: 0.0,
            limiter_enabled: false,
            compressor_ratio: 4.0,
            surround_variation: "Surround".into(),
            night_mode: false,
            effects_enabled: true,
            mic_enabled: true,
            mic_gain: 1.0,
            mic_noise_suppression: false,
            echo_cancellation: false,
            voice_clarity: false,
            treble_enhancer: false,
            bass_boost: false,
            tracker_enabled: false,
            sharing_enabled: false,
        },
        _ => AudioProfile::default(),
    }
}

fn initialize_profiles() {
    let mut settings = PROFILE_SETTINGS.lock().unwrap();
    let profile_names = ["Music", "Gaming", "Movie", "Voice", "Communication", "Smart", "Custom"];
    
    for name in profile_names.iter() {
        let profile_path = format!("{}/{}.json", PROFILES_DIR, name);
        if let Ok(content) = fs::read_to_string(&profile_path) {
            if let Ok(profile) = serde_json::from_str::<AudioProfile>(&content) {
                info!("Loaded profile {} from disk", name);
                settings.insert(name.to_string(), profile);
            }
        } else {
            let default_profile = get_default_profile(name);
            info!("Using default profile for {}", name);
            settings.insert(name.to_string(), default_profile.clone());
            
            if let Err(e) = save_profile_to_file(&default_profile) {
                warn!("Failed to save default profile {}: {}", name, e);
            }
        }
    }
}

fn save_profile_to_file(profile: &AudioProfile) -> Result<()> {
    fs::create_dir_all(PROFILES_DIR)?;
    let path = format!("{}/{}.json", PROFILES_DIR, profile.name);
    let json = serde_json::to_string_pretty(profile)?;
    fs::write(path, json)?;
    Ok(())
}

fn load_saved_profile() -> AudioProfile {
    if let Ok(content) = fs::read_to_string(PROFILE_PATH) {
        if let Ok(profile) = serde_json::from_str(&content) {
            info!("Loaded saved profile from {}", PROFILE_PATH);
            return profile;
        }
    }
    info!("No saved profile found, using defaults");
    AudioProfile::default()
}

fn save_profile(profile: &AudioProfile) -> Result<()> {
    fs::create_dir_all("/tmp/msi_dsp_config")?;
    let json = serde_json::to_string_pretty(profile)?;
    fs::write(PROFILE_PATH, json)?;
    info!("Profile saved to {}", PROFILE_PATH);
    Ok(())
}

fn get_sink_volume() -> f64 {
    let output = Command::new("wpctl")
        .args(["get-volume", "@DEFAULT_AUDIO_SINK@"])
        .output();
    
    match output {
        Ok(out) => {
            let stdout = String::from_utf8_lossy(&out.stdout);
            if let Some(vol) = stdout.trim().split_whitespace().next() {
                vol.parse::<f64>().unwrap_or(1.0)
            } else {
                1.0
            }
        }
        Err(_) => 1.0,
    }
}

fn set_sink_volume(volume: f64) {
    let _ = Command::new("wpctl")
        .args(["set-volume", "@DEFAULT_AUDIO_SINK@", &format!("{}%", (volume * 100.0) as i32)])
        .output();
}

fn check_filter_chain_running() -> bool {
    let output = Command::new("pgrep")
        .args(["-f", "pw-filter-chain.*msi_dsp"])
        .output();
    
    match output {
        Ok(out) => !out.stdout.is_empty(),
        Err(_) => false,
    }
}

fn kill_filter_chain() {
    info!("Killing existing pw-filter-chain instances...");
    let output = Command::new("pkill")
        .args(["-f", "pw-filter-chain.*msi_dsp"])
        .output();
    
    if let Err(e) = output {
        warn!("Failed to kill filter chain: {}", e);
    }
    
    std::thread::sleep(std::time::Duration::from_millis(500));
}

fn start_filter_chain() -> bool {
    info!("Starting pw-filter-chain with config...");
    
    let child = Command::new("pw-filter-chain")
        .args(["-c", FILTER_CHAIN_CONFIG_PATH])
        .spawn();
    
    match child {
        Ok(_) => {
            info!("pw-filter-chain started, waiting for it to connect...");
            std::thread::sleep(std::time::Duration::from_secs(2));
            true
        }
        Err(e) => {
            error!("Failed to start pw-filter-chain: {}", e);
            false
        }
    }
}

fn link_filter_chain() {
    info!("Relinking filter chain output to physical audio sink...");
    
    // 1. Find the default physical sink (actual hardware)
    let output = Command::new("pactl")
        .args(["get-default-sink"])
        .output();
    
    if let Ok(out) = output {
        let default_sink = String::from_utf8_lossy(&out.stdout).trim().to_string();
        
        // If the default sink is ALREADY our DSP input, we need to find the REAL fallback sink
        // to avoid a loop. Usually, this means we look at 'pactl list sinks' and find the first
        // sink that isn't ours.
        let mut target_sink = default_sink.clone();
        if target_sink == "msi_dsp_input" {
             let sink_list = Command::new("pactl")
                .args(["list", "short", "sinks"])
                .output();
             if let Ok(sl_out) = sink_list {
                 let sl_str = String::from_utf8_lossy(&sl_out.stdout);
                 for line in sl_str.lines() {
                     let parts: Vec<&str> = line.split(char::is_whitespace).filter(|s| !s.is_empty()).collect();
                     if parts.len() > 1 {
                         let name = parts[1];
                         if name != "msi_dsp_input" && !name.contains("monitor") {
                             target_sink = name.to_string();
                             break;
                         }
                     }
                 }
             }
        }

        info!("Targeting physical sink: {}", target_sink);

        // 2. Link msi_dsp_output (our chain's exit) to the physical sink
        // Note: pw-link handles node:port syntax
        // Use -d to disconnect existing links first for robustness
        let _ = Command::new("pw-link")
            .args(["-d", "msi_dsp_output:output_FL", "msi_dsp_output:output_FR"])
            .output();

        let l1 = Command::new("pw-link")
            .args(["msi_dsp_output:output_FL", &format!("{}:playback_FL", target_sink)])
            .output();
        let l2 = Command::new("pw-link")
            .args(["msi_dsp_output:output_FR", &format!("{}:playback_FR", target_sink)])
            .output();
        
        if l1.is_ok() && l2.is_ok() {
            info!("Links established to {}", target_sink);
        } else {
            warn!("Failed to establish links to {}", target_sink);
        }
    }
}

fn start_device_monitor() {
    info!("Starting PipeWire device monitor...");
    tokio::spawn(async move {
        use tokio::process::Command as TokioCommand;
        use std::process::Stdio;
        use tokio::io::{AsyncBufReadExt, BufReader};

        loop {
            let mut child = TokioCommand::new("pactl")
                .arg("subscribe")
                .stdout(Stdio::piped())
                .spawn();

            if let Ok(mut child) = child {
                if let Some(stdout) = child.stdout.take() {
                    let mut reader = BufReader::new(stdout).lines();
                    info!("Device monitor connected to PulseAudio events");
                    
                    while let Ok(Some(line)) = reader.next_line().await {
                        // Only relink on actual device addition/removal (new sink appears or disappears)
                        // NOT on property changes (which fire on every pw-cli set-param and would glitch audio)
                        if line.contains("Event 'new' on sink") || line.contains("Event 'remove' on sink") {
                            info!("Sink added or removed, re-linking...");
                            tokio::time::sleep(tokio::time::Duration::from_millis(600)).await;
                            link_filter_chain();
                        }
                    }
                }
                let _ = child.kill().await;
            }
            
            warn!("pactl subscribe failed or exited, restarting in 5s...");
            tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
        }
    });
}

fn set_default_sink_to_dsp() {
    info!("Setting MSI DSP as default audio sink...");
    
    let output = Command::new("pactl")
        .args(["set-default-sink", "msi_dsp_input"])
        .output();
    
    match output {
        Ok(out) if out.status.success() => {
            info!("Successfully set msi_dsp_input as default sink");
        }
        Ok(out) => {
            let stderr = String::from_utf8_lossy(&out.stderr);
            warn!("Failed to set default sink: {}", stderr);
        }
        Err(e) => {
            warn!("Error setting default sink: {}", e);
        }
    }
}

fn disable_dsp_switch_to_direct() {
    info!("Switching to direct audio output (bypassing DSP)...");
    
    let output = Command::new("pactl")
        .args(["list", "short", "sinks"])
        .output();
    
    if let Ok(out) = output {
        let sinks = String::from_utf8_lossy(&out.stdout);
        
        for line in sinks.lines() {
            if line.contains("Speaker__sink") {
                let name = line.split('\t').nth(1).unwrap_or("").trim();
                if !name.is_empty() {
                    let _ = Command::new("pactl")
                        .args(["set-default-sink", name])
                        .output();
                    info!("Switched to speaker: {}", name);
                    return;
                }
            }
        }
        
        for line in sinks.lines() {
            if line.contains("HiFi__") {
                let name = line.split('\t').nth(1).unwrap_or("").trim();
                if !name.is_empty() && !name.contains("HDMI") {
                    let _ = Command::new("pactl")
                        .args(["set-default-sink", name])
                        .output();
                    info!("Switched to audio output: {}", name);
                    return;
                }
            }
        }
    }
    
    let _ = Command::new("pactl")
        .args(["set-default-sink", "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"])
        .output();
    info!("Fallback: switched to default speaker");
}

fn generate_filter_chain_config(profile: &AudioProfile) -> Result<()> {
    let eq_bands = [
        (32, "eq0"), (64, "eq1"), (125, "eq2"), (250, "eq3"), (500, "eq4"),
        (1000, "eq5"), (2000, "eq6"), (4000, "eq7"), (8000, "eq8"), (16000, "eq9")
    ];
    
    let mut eq_nodes = String::new();
    for (i, (freq, name)) in eq_bands.iter().enumerate() {
        let gain = profile.eq_gains.get(i).unwrap_or(&0.0);
        eq_nodes.push_str(&format!(
            r#"            {{ type = builtin label = bq_peaking name = "{}L" control = {{ "Freq" = {} "Gain" = {} "Q" = 1.41 }} }}
            {{ type = builtin label = bq_peaking name = "{}R" control = {{ "Freq" = {} "Gain" = {} "Q" = 1.41 }} }}
"#,
            name, freq, gain, name, freq, gain
        ));
    }
    // Base gains from profile
    let bass_gain = profile.bass;
    let treble_gain = profile.treble;
    let voice_gain = profile.voice;

    // Advanced Logic
    let mut stereo_width = profile.stereo_width;
    
    // Surround Variations
    if profile.surround {
        match profile.surround_variation.as_str() {
            "Headset" => {
                stereo_width *= 0.8; // Tighter for headphones
            }
            "Virtual" | "Surround" => {
                stereo_width *= 1.4; // Wider for virtual speakers
            }
            "3D" => {
                stereo_width *= 2.0; // Very wide for cinematic feel
            }
            "Wide" => {
                stereo_width *= 2.8; // Maximum expansion
            }
            _ => {}
        }
    } else {
        stereo_width = 1.0; // Neutral
    }

    // Night Mode & Volume Stabilizer (Dynamic Range Compression)
    // We use dysonCompress for Night Mode (soft compression)
    // and fastLookaheadLimiter for Volume Stabilizer (hard limiting)
    let night_mode_active = profile.night_mode && profile.effects_enabled;
    let _volume_stabilizer_active = profile.limiter_enabled && profile.effects_enabled;
    
    let limiter_threshold = if night_mode_active { -12.0 } else { -1.0 };
    let compress_ratio = if night_mode_active { 8.0 } else { profile.compressor_ratio.max(1.0) };

    // Effects Toggle
    let _global_effects_enabled = profile.effects_enabled;

    
    let config = format!(r#"context.properties = {{
    log.level = 3
}}

context.modules = [
    {{ name = libpipewire-module-rt
        args = {{ rt.prio = 83 }}
        flags = [ ifexists nofail ]
    }}
    {{ name = libpipewire-module-protocol-native }}
    {{ name = libpipewire-module-client-node }}
    {{ name = libpipewire-module-adapter }}
    
    {{ name = libpipewire-module-filter-chain
        args = {{
            node.name        = "msi_dsp_filter"
            node.description = "MSI DSP Playback"
            media.name       = "MSI DSP Engine"
            audio.channels   = 2
            audio.position   = [ "FL" "FR" ]
            filter.graph = {{
                nodes = [
{eq_nodes}            {{ type = builtin label = bq_lowshelf name = "bassL" control = {{ "Freq" = 100 "Gain" = {bass_gain} "Q" = 0.707 }} }}
            {{ type = builtin label = bq_lowshelf name = "bassR" control = {{ "Freq" = 100 "Gain" = {bass_gain} "Q" = 0.707 }} }}
            {{ type = builtin label = bq_highshelf name = "trebleL" control = {{ "Freq" = 5000 "Gain" = {treble_gain} "Q" = 0.707 }} }}
            {{ type = builtin label = bq_highshelf name = "trebleR" control = {{ "Freq" = 5000 "Gain" = {treble_gain} "Q" = 0.707 }} }}
            {{ type = builtin label = bq_peaking name = "voiceL" control = {{ "Freq" = 2000 "Gain" = {voice_gain} "Q" = 0.5 }} }}
            {{ type = builtin label = bq_peaking name = "voiceR" control = {{ "Freq" = 2000 "Gain" = {voice_gain} "Q" = 0.5 }} }}
            {{
                type = ladspa
                name = "spatializer"
                plugin = "/usr/lib/ladspa/matrix_spatialiser_1422.so"
                label = "matrixSpatialiser"
                control = {{ "Width" = {stereo_width} }}
            }}
            {{
                type = ladspa
                name = "compressorL"
                plugin = "/usr/lib/ladspa/dyson_compress_1403.so"
                label = "dysonCompress"
                control = {{ "Peak limit (dB)" = {limiter_threshold} "Release time (s)" = 0.5 "Compression ratio" = {compress_ratio} }}
            }}
            {{
                type = ladspa
                name = "compressorR"
                plugin = "/usr/lib/ladspa/dyson_compress_1403.so"
                label = "dysonCompress"
                control = {{ "Peak limit (dB)" = {limiter_threshold} "Release time (s)" = 0.5 "Compression ratio" = {compress_ratio} }}
            }}
            {{
                type = ladspa
                name = "limiter"
                plugin = "/usr/lib/ladspa/fast_lookahead_limiter_1913.so"
                label = "fastLookaheadLimiter"
                control = {{ "Input gain (dB)" = 0 "Limit (dB)" = -0.1 "Release time (s)" = 0.1 }}
            }}
                ]
                links = [
                    {{ output = "eq0L:Out" input = "eq1L:In" }}
                    {{ output = "eq0R:Out" input = "eq1R:In" }}
                    {{ output = "eq1L:Out" input = "eq2L:In" }}
                    {{ output = "eq1R:Out" input = "eq2R:In" }}
                    {{ output = "eq2L:Out" input = "eq3L:In" }}
                    {{ output = "eq2R:Out" input = "eq3R:In" }}
                    {{ output = "eq3L:Out" input = "eq4L:In" }}
                    {{ output = "eq3R:Out" input = "eq4R:In" }}
                    {{ output = "eq4L:Out" input = "eq5L:In" }}
                    {{ output = "eq4R:Out" input = "eq5R:In" }}
                    {{ output = "eq5L:Out" input = "eq6L:In" }}
                    {{ output = "eq5R:Out" input = "eq6R:In" }}
                    {{ output = "eq6L:Out" input = "eq7L:In" }}
                    {{ output = "eq6R:Out" input = "eq7R:In" }}
                    {{ output = "eq7L:Out" input = "eq8L:In" }}
                    {{ output = "eq7R:Out" input = "eq8R:In" }}
                    {{ output = "eq8L:Out" input = "eq9L:In" }}
                    {{ output = "eq8R:Out" input = "eq9R:In" }}
                    {{ output = "eq9L:Out" input = "bassL:In" }}
                    {{ output = "eq9R:Out" input = "bassR:In" }}
                    {{ output = "bassL:Out" input = "trebleL:In" }}
                    {{ output = "bassR:Out" input = "trebleR:In" }}
                    {{ output = "trebleL:Out" input = "voiceL:In" }}
                    {{ output = "trebleR:Out" input = "voiceR:In" }}
                    {{ output = "voiceL:Out" input = "spatializer:Input L" }}
                    {{ output = "voiceR:Out" input = "spatializer:Input R" }}
                    {{ output = "spatializer:Output L" input = "compressorL:Input" }}
                    {{ output = "spatializer:Output R" input = "compressorR:Input" }}
                    {{ output = "compressorL:Output" input = "limiter:Input 1" }}
                    {{ output = "compressorR:Output" input = "limiter:Input 2" }}
                ]
                inputs  = [ "eq0L:In" "eq0R:In" ]
                outputs = [ "limiter:Output 1" "limiter:Output 2" ]
            }}
            capture.props = {{
                node.name      = "msi_dsp_input"
                media.class    = "Audio/Sink"
                audio.channels = 2
                audio.position = [ "FL" "FR" ]
            }}
            playback.props = {{
                node.name      = "msi_dsp_output"
                audio.channels = 2
                audio.position = [ "FL" "FR" ]
            }}
        }}
    }}
    {{ name = libpipewire-module-filter-chain
        args = {{
            node.name        = "msi_dsp_mic_filter"
            node.description = "MSI DSP Microphone"
            media.name       = "MSI DSP Microphone Engine"
            audio.channels   = 1
            audio.position   = [ "MONO" ]
            filter.graph = {{
                nodes = [
                    {{
                        type = builtin
                        label = bq_highpass
                        name = "mic_hp"
                        control = {{ "Freq" = 100 "Q" = 0.707 }}
                    }}
                ]
                inputs  = [ "mic_hp:In" ]
                outputs = [ "mic_hp:Out" ]
            }}
            capture.props = {{
                node.name      = "msi_dsp_mic_input"
                media.class    = "Audio/Source"
                audio.channels = 1
                audio.position = [ "MONO" ]
            }}
            playback.props = {{
                node.name      = "msi_dsp_mic_output"
                audio.channels = 1
                audio.position = [ "MONO" ]
            }}
        }}
    }}
    {{ name = libpipewire-module-echo-cancel
        args = {{
            monitor.mode = true
            capture.props = {{
                node.name = "msi_dsp_echo_cancel"
                node.description = "MSI DSP Echo Cancel & Noise Suppression"
            }}
        }}
    }}

]
"#);
    
    fs::write(FILTER_CHAIN_CONFIG_PATH, config)?;
    info!("Filter chain config written: Name={}, Mode={}, Width={:.2}", 
        profile.name, profile.surround_variation, stereo_width);
    Ok(())
}


fn get_node_id_by_name(name: &str) -> Option<u32> {
    let output = Command::new("pw-cli")
        .args(["ls", "Node"])
        .output()
        .ok()?;
    
    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut current_id = None;
    
    for line in stdout.lines() {
        if line.contains("id ") && line.contains("type PipeWire:Interface:Node") {
            if let Some(id_part) = line.split("id ").nth(1) {
                if let Some(id_val) = id_part.split(',').next() {
                    current_id = id_val.trim().parse::<u32>().ok();
                }
            }
        }
        
        if line.contains(&format!("node.name = \"{}\"", name)) {
            if let Some(id) = current_id {
                info!("Found node {} at id {}", name, id);
                return Some(id);
            }
        }
    }
    None
}

fn send_single_param(node_id: u32, param: &str, value: f64) {
    let cmd = format!("pw-cli set-param {} Props '{{ params = [ \"{}\" {} ] }}'", node_id, param, value);
    let _ = Command::new("sh").args(["-c", &cmd]).output();
}

fn update_filter_params(profile: &AudioProfile) {
    // 1. Playback Node Updates
    if let Some(playback_id) = get_node_id_by_name("msi_dsp_input") {
        info!("Updating playback filter params for node {}", playback_id);
        
        // Bypass logic
        let (bass, treble, voice, eq_gains, spatializer_width) = if profile.effects_enabled {
            (
                if profile.bass_boost { profile.bass } else { 0.0 },
                if profile.treble_enhancer { profile.treble } else { 0.0 },
                if profile.voice_clarity { profile.voice } else { 0.0 },
                profile.eq_gains.clone(),
                profile.stereo_width
            )
        } else {
            (0.0, 0.0, 0.0, vec![0.0; 10], 1.0)
        };

        // Apply each param individually — avoids a massive atomic batch that can glitch audio
        // Send EQs in one batch (they need to change together for balanced sound)
        let eq_bands = ["eq0", "eq1", "eq2", "eq3", "eq4", "eq5", "eq6", "eq7", "eq8", "eq9"];
        for (i, band) in eq_bands.iter().enumerate() {
            let gain = eq_gains.get(i).unwrap_or(&0.0);
            send_single_param(playback_id, &format!("{}L:Gain", band), *gain);
            send_single_param(playback_id, &format!("{}R:Gain", band), *gain);
        }
        
        // Basic Gains
        send_single_param(playback_id, "bassL:Gain", bass);
        send_single_param(playback_id, "bassR:Gain", bass);
        send_single_param(playback_id, "trebleL:Gain", treble);
        send_single_param(playback_id, "trebleR:Gain", treble);
        send_single_param(playback_id, "voiceL:Gain", voice);
        send_single_param(playback_id, "voiceR:Gain", voice);
        
        // Spatializer
        let mut width = spatializer_width;
        if profile.surround {
            match profile.surround_variation.as_str() {
                "Headset" => width *= 0.8,
                "Virtual" | "Surround" => width *= 1.4,
                "3D" => width *= 1.8,
                "Wide" => width *= 2.5,
                _ => {}
            }
        } else {
            width = 1.0;
        }
        send_single_param(playback_id, "spatializer:Width", width);
        
        // Limiter & Night Mode
        let night_mode_active = profile.night_mode && profile.effects_enabled;
        let volume_stabilizer_active = profile.limiter_enabled && profile.effects_enabled;
        let limiter_threshold = if night_mode_active { -12.0 } else if volume_stabilizer_active { -1.0 } else { -0.1 };
        let compress_ratio = if night_mode_active { 8.0 } else { profile.compressor_ratio.max(1.0) };
        
        send_single_param(playback_id, "compressorL:Peak limit (dB)", limiter_threshold);
        send_single_param(playback_id, "compressorR:Peak limit (dB)", limiter_threshold);
        send_single_param(playback_id, "compressorL:Compression ratio", compress_ratio);
        send_single_param(playback_id, "compressorR:Compression ratio", compress_ratio);
        send_single_param(playback_id, "limiter:Limit (dB)", -0.1);
    }

    // 2. Microphone Node Updates
    if let Some(mic_id) = get_node_id_by_name("msi_dsp_mic_input") {
        info!("Updating microphone filter params for node {}", mic_id);
        let mic_gain = if profile.mic_enabled { profile.mic_gain } else { 0.0 };
        send_single_param(mic_id, "mic_hp:Gain", mic_gain);
    }
}


fn apply_dsp_settings(profile: &AudioProfile, update_volume: bool) {
    if !DSP_ENABLED.load(Ordering::SeqCst) {
        info!("DSP is disabled, skipping settings application");
        return;
    }
    
    info!("Applying DSP settings...");
    info!("  Profile: {}", profile.name);
    info!("  Bass: {} dB, Treble: {} dB, Voice: {} dB", 
        profile.bass, profile.treble, profile.voice);
    info!("  EQ bands: {:?}", profile.eq_gains);
    info!("  Volume: {}%", (profile.volume * 100.0) as i32);
    
    let effects_changed = {
        let last_name = LAST_PROFILE_NAME.lock().unwrap();
        last_name.as_str() != profile.name
    };
    
    {
        let mut settings = PROFILE_SETTINGS.lock().unwrap();
        settings.insert(profile.name.clone(), profile.clone());
    }
    
    // EasyEffects-style: Always use persistent filter chain, never restart
    // Only update parameters dynamically
    if !check_filter_chain_running() {
        info!("Filter chain not running, starting persistent chain...");
        if let Err(e) = generate_filter_chain_config(profile) {
            error!("Failed to generate filter chain config: {}", e);
            return;
        }
        
        if !start_filter_chain() {
            error!("Failed to start filter chain");
            return;
        }
        
        std::thread::sleep(std::time::Duration::from_millis(300));
        link_filter_chain();
        
        std::thread::sleep(std::time::Duration::from_millis(100));
    } else {
        // Filter chain is already running - just update parameters
        info!("Updating filter parameters dynamically (persistent chain)...");
        update_filter_params(profile);
    }
    
    if update_volume {
        let new_volume = profile.volume.max(0.01);
        set_sink_volume(new_volume);
        info!("Volume set to {}%", (new_volume * 100.0) as i32);
    }
    
    // Only persist profile.json when the profile name actually changed
    if effects_changed {
        let _ = save_profile_to_file(profile);
    }
    let _ = save_profile(profile);
    
    {
        let mut last = LAST_PROFILE_NAME.lock().unwrap();
        *last = profile.name.clone();
    }
    
    FILTER_CHAIN_RUNNING.store(true, Ordering::SeqCst);
    info!("COMMITTING full DSP state: Profile={}, Effects={}", profile.name, profile.effects_enabled);
    info!("DSP settings applied successfully (persistent architecture)");
}

#[tokio::main]
async fn main() -> Result<()> {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info"))
        .init();

    info!("MSI DSP Service v0.4.0");
    info!("=================================");
    info!("Socket: {}", SOCKET_PATH);
    info!("Profile: {}", PROFILE_PATH);

    initialize_profiles();
    
    let saved_profile = load_saved_profile();
    info!("Initial profile loaded: {}", saved_profile.name);
    info!("  bass: {}, treble: {}, voice: {}", 
        saved_profile.bass, saved_profile.treble, saved_profile.voice);
    info!("  EQ gains: {:?}", saved_profile.eq_gains);
    info!("  Volume: {}%", (saved_profile.volume * 100.0) as i32);

    {
        let mut last = LAST_PROFILE_NAME.lock().unwrap();
        *last = saved_profile.name.clone();
    }
    
    // Auto-apply saved profile on startup
    info!("Auto-applying saved DSP profile on service startup...");
    apply_dsp_settings(&saved_profile, false);

    // Start background device monitor for seamless switching
    start_device_monitor();
    
    // Auto-set default sink to DSP if DSP is enabled
    if DSP_ENABLED.load(Ordering::SeqCst) && check_filter_chain_running() {
        set_default_sink_to_dsp();
        info!("Auto-set default sink to MSI DSP");
    }

    let _ = fs::remove_file(SOCKET_PATH);

    let listener = UnixListener::bind(SOCKET_PATH)?;
    info!("Waiting for connections...");

    loop {
        match listener.accept().await {
            Ok((mut socket, _)) => {
                tokio::spawn(async move {
                    let mut buf = vec![0u8; 8192];
                    info!("Client connected to DSP socket");
                    loop {
                        match socket.read(&mut buf).await {
                            Ok(0) => {
                                info!("Client disconnected");
                                break;
                            }
                            Ok(n) => {
                                let raw_msg = String::from_utf8_lossy(&buf[..n]);
                                // Split multiple commands in one packet if they arrived together
                                for message in raw_msg.split('\n').map(|s| s.trim()).filter(|s| !s.is_empty()) {
                                    if message == "ENABLE" {
                                        info!("Received ENABLE command");
                                        if !check_filter_chain_running() {
                                            let profile = load_saved_profile();
                                            apply_dsp_settings(&profile, false);
                                        }
                                        // Always set DSP as default sink on enable (handles the case where chain was stopped)
                                        set_default_sink_to_dsp();
                                        let _ = socket.write_all(b"OK\n").await;
                                    } else if message == "DISABLE" {
                                        info!("Received DISABLE command");
                                        disable_dsp_switch_to_direct();
                                        // Also stop the filter chain so it restarts cleanly on next ENABLE
                                        kill_filter_chain();
                                        let _ = socket.write_all(b"OK\n").await;
                                    } else if message.starts_with("LOAD:") {
                                        let profile_name = message.replace("LOAD:", "").trim().to_string();
                                        info!("Received LOAD profile command: {}", profile_name);

                                        let mut profile_opt = {
                                            let settings = PROFILE_SETTINGS.lock().unwrap();
                                            settings.get(&profile_name).cloned()
                                        };

                                        if profile_opt.is_none() {
                                            let profile_path = format!("{}/{}.json", PROFILES_DIR, profile_name);
                                            if let Ok(content) = fs::read_to_string(&profile_path) {
                                                if let Ok(profile) = serde_json::from_str::<AudioProfile>(&content) {
                                                    info!("Loaded profile {} from disk on demand", profile_name);
                                                    {
                                                        let mut settings = PROFILE_SETTINGS.lock().unwrap();
                                                        settings.insert(profile_name.clone(), profile.clone());
                                                    }
                                                    profile_opt = Some(profile);
                                                }
                                            }
                                        }

                                        if profile_opt.is_none() {
                                            let mut fallback = get_default_profile(&profile_name);
                                            fallback.name = profile_name.clone();
                                            info!("Using default profile fallback for {}", profile_name);
                                            {
                                                let mut settings = PROFILE_SETTINGS.lock().unwrap();
                                                settings.insert(profile_name.clone(), fallback.clone());
                                                let _ = save_profile_to_file(&fallback);
                                            }
                                            profile_opt = Some(fallback);
                                        }
                                        
                                        if let Some(profile) = profile_opt {
                                            let json = serde_json::to_string(&profile).unwrap_or_default();
                                            let _ = socket.write_all(json.as_bytes()).await;
                                            let _ = socket.write_all(b"\n").await;
                                            apply_dsp_settings(&profile, false); // Don't reset volume on profile load
                                        } else {
                                            let _ = socket.write_all(b"ERROR: profile not found\n").await;
                                        }
                                    } else if message.starts_with("SAVE:") {
                                        let json_str = message.replace("SAVE:", "").trim().to_string();
                                        if let Ok(mut profile) = serde_json::from_str::<AudioProfile>(&json_str) {
                                            clamp_profile(&mut profile);
                                            {
                                                let mut settings = PROFILE_SETTINGS.lock().unwrap();
                                                settings.insert(profile.name.clone(), profile.clone());
                                                let _ = save_profile_to_file(&profile);
                                            }
                                            let _ = socket.write_all(b"OK\n").await;
                                        } else {
                                            let _ = socket.write_all(b"ERROR: invalid JSON\n").await;
                                        }
                                    } else if message == "STATUS" {
                                        let status = if DSP_ENABLED.load(Ordering::SeqCst) && check_filter_chain_running() { "enabled" } else { "disabled" };
                                        let response = format!("{}\n", status);
                                        let _ = socket.write_all(response.as_bytes()).await;
                                    } else if message.starts_with("VOLUME") {
                                        info!("Received VOLUME command: {}", message);
                                        let vol_str = message.replace("VOLUME:", "").replace("VOLUME", "");
                                        if let Ok(vol) = vol_str.trim().parse::<f64>() {
                                            let new_vol: f64 = vol.clamp(0.2, 1.3);
                                            set_sink_volume(new_vol);
                                            let _ = socket.write_all(b"OK\n").await;
                                        } else {
                                            let _ = socket.write_all(b"ERROR: invalid volume\n").await;
                                        }
                                    } else if message.starts_with("UPDATE") {
                                        let json_str = message.replace("UPDATE:", "").replace("UPDATE", "");
                                        if let Ok(mut profile) = serde_json::from_str::<AudioProfile>(&json_str) {
                                            clamp_profile(&mut profile);
                                            apply_dsp_settings(&profile, false); // UPDATE command should not change volume unless explicitly requested
                                            let _ = socket.write_all(b"OK\n").await;
                                        } else {
                                            let _ = socket.write_all(b"ERROR: invalid JSON\n").await;
                                        }
                                    }
                                }
                            }
                            Err(e) => {
                                error!("Socket read error: {}", e);
                                break;
                            }
                        }
                    }
                });
            }
            Err(e) => {
                error!("Accept error: {}", e);
            }
        }
    }
}

fn clamp_profile(profile: &mut AudioProfile) {
    profile.bass = profile.bass.clamp(-12.0, 12.0);
    profile.treble = profile.treble.clamp(-12.0, 12.0);
    profile.voice = profile.voice.clamp(-12.0, 12.0);
    for gain in profile.eq_gains.iter_mut() {
        *gain = gain.clamp(-15.0, 15.0);
    }
    profile.volume = profile.volume.clamp(0.0, 1.3);
    profile.stereo_width = profile.stereo_width.clamp(0.0, 2.0);
}
