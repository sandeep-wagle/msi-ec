//! MSI DSP Service
//! 
//! This service handles audio profile settings via Unix socket.
//! It saves/loads profiles and manages PipeWire filter chain for audio DSP.

use anyhow::Result;
use log::{error, info, warn};
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
    info!("Linking filter chain to default audio sink...");
    
    let output = Command::new("pw-link")
        .args(["-l"])
        .output();
    
    if let Ok(out) = output {
        let links = String::from_utf8_lossy(&out.stdout);
        
        if !links.contains("msi_dsp_output") || !links.contains("msi_dsp_input") {
            let _ = Command::new("pw-link")
                .args(["msi_dsp_output:output_FL", "msi_dsp_input:playback_FL"])
                .output();
            let _ = Command::new("pw-link")
                .args(["msi_dsp_output:output_FR", "msi_dsp_input:playback_FR"])
                .output();
            
            let output = Command::new("pactl")
                .args(["get-default-sink"])
                .output();
            
            if let Ok(out) = output {
                let sink_name = String::from_utf8_lossy(&out.stdout).trim().to_string();
                let _ = Command::new("pw-link")
                    .args(["msi_dsp_input:monitor_FL", &format!("{}:playback_FL", sink_name)])
                    .output();
                let _ = Command::new("pw-link")
                    .args(["msi_dsp_input:monitor_FR", &format!("{}:playback_FR", sink_name)])
                    .output();
            }
        }
    }
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
    
    let bass_gain = profile.bass;
    let treble_gain = profile.treble;
    let voice_gain = profile.voice;
    
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
            node.description = "MSI DSP Engine"
            media.name       = "MSI DSP Engine"
            audio.channels   = 2
            audio.position   = [ FL FR ]
            filter.graph = {{
                nodes = [
{eq_nodes}            {{ type = builtin label = bq_lowshelf name = "bassL" control = {{ "Freq" = 100 "Gain" = {bass_gain} "Q" = 0.707 }} }}
            {{ type = builtin label = bq_lowshelf name = "bassR" control = {{ "Freq" = 100 "Gain" = {bass_gain} "Q" = 0.707 }} }}
            {{ type = builtin label = bq_highshelf name = "trebleL" control = {{ "Freq" = 5000 "Gain" = {treble_gain} "Q" = 0.707 }} }}
            {{ type = builtin label = bq_highshelf name = "trebleR" control = {{ "Freq" = 5000 "Gain" = {treble_gain} "Q" = 0.707 }} }}
            {{ type = builtin label = bq_peaking name = "voiceL" control = {{ "Freq" = 2000 "Gain" = {voice_gain} "Q" = 0.5 }} }}
            {{ type = builtin label = bq_peaking name = "voiceR" control = {{ "Freq" = 2000 "Gain" = {voice_gain} "Q" = 0.5 }} }}
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
                ]
                inputs  = [ "eq0L:In" "eq0R:In" ]
                outputs = [ "voiceL:Out" "voiceR:Out" ]
            }}
            capture.props = {{
                node.name      = "msi_dsp_input"
                media.class    = Audio/Sink
                audio.channels = 2
                audio.position = [ FL FR ]
            }}
            playback.props = {{
                node.name      = "msi_dsp_output"
                audio.channels = 2
                audio.position = [ FL FR ]
            }}
        }}
    }}
]
"#);
    
    fs::write(FILTER_CHAIN_CONFIG_PATH, config)?;
    info!("Filter chain config written to {}", FILTER_CHAIN_CONFIG_PATH);
    Ok(())
}

fn get_filter_node_id() -> Option<u32> {
    let output = Command::new("pw-cli")
        .args(["info", "msi_dsp_input"])
        .output()
        .ok()?;
    
    let stdout = String::from_utf8_lossy(&output.stdout);
    
    for line in stdout.lines() {
        let trimmed = line.trim().to_string();
        if trimmed.starts_with("id:") {
            let id_str = trimmed.replace("id:", "").trim().to_string();
            return id_str.parse().ok();
        }
    }
    None
}

fn update_filter_params(profile: &AudioProfile) {
    if let Some(node_id) = get_filter_node_id() {
        info!("Updating filter params for node {}", node_id);
        
        let eq_bands = ["eq0", "eq1", "eq2", "eq3", "eq4", "eq5", "eq6", "eq7", "eq8", "eq9"];
        for (i, band) in eq_bands.iter().enumerate() {
            if let Some(gain) = profile.eq_gains.get(i) {
                for ch in ['L', 'R'] {
                    let param = format!("{}{}:Gain", band, ch);
                    let cmd = format!(
                        "pw-cli set-param {} Props '{{ params = [ \"{}\" {} ] }}'",
                        node_id, param, gain
                    );
                    let _ = Command::new("sh")
                        .args(["-c", &cmd])
                        .output();
                }
            }
        }
        
        for ch in ['L', 'R'] {
            let cmd = format!(
                "pw-cli set-param {} Props '{{ params = [ \"bass{}:Gain\" {} ] }}'",
                node_id, ch, profile.bass
            );
            let _ = Command::new("sh")
                .args(["-c", &cmd])
                .output();
            
            let cmd = format!(
                "pw-cli set-param {} Props '{{ params = [ \"treble{}:Gain\" {} ] }}'",
                node_id, ch, profile.treble
            );
            let _ = Command::new("sh")
                .args(["-c", &cmd])
                .output();
            
            let cmd = format!(
                "pw-cli set-param {} Props '{{ params = [ \"voice{}:Gain\" {} ] }}'",
                node_id, ch, profile.voice
            );
            let _ = Command::new("sh")
                .args(["-c", &cmd])
                .output();
        }
        
        info!("Filter parameters updated successfully");
    } else {
        warn!("Could not find filter node ID");
    }
}

fn apply_dsp_settings(profile: &AudioProfile) {
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
    
    {
        let mut settings = PROFILE_SETTINGS.lock().unwrap();
        settings.insert(profile.name.clone(), profile.clone());
        let _ = save_profile_to_file(profile);
    }
    
    let profile_changed = {
        let mut last = LAST_PROFILE_NAME.lock().unwrap();
        if *last != profile.name {
            info!("Profile changed from {} to {}", *last, profile.name);
            *last = profile.name.clone();
            true
        } else {
            false
        }
    };
    
    if !check_filter_chain_running() || profile_changed {
        info!("Filter chain not running or profile changed, starting/restarting...");
        if let Err(e) = generate_filter_chain_config(profile) {
            error!("Failed to generate filter chain config: {}", e);
            return;
        }
        
        info!("Starting/restarting filter chain...");
        if check_filter_chain_running() {
            kill_filter_chain();
            std::thread::sleep(std::time::Duration::from_millis(100));
        }
        
        if !start_filter_chain() {
            error!("Failed to start filter chain");
            return;
        }
        
        std::thread::sleep(std::time::Duration::from_millis(300));
        
        link_filter_chain();
        set_default_sink_to_dsp();
        
        std::thread::sleep(std::time::Duration::from_millis(100));
    } else if check_filter_chain_running() {
        // Dynamically update parameters without restarting the filter chain
        info!("Updating filter parameters dynamically...");
        update_filter_params(profile);
    }
    
    let new_volume = profile.volume.max(0.01);
    set_sink_volume(new_volume);
    info!("Volume set to {}%", (new_volume * 100.0) as i32);
    
    let _ = save_profile(profile);
    
    FILTER_CHAIN_RUNNING.store(true, Ordering::SeqCst);
    info!("DSP settings applied successfully");
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
    info!("Initial profile: {}", saved_profile.name);
    info!("  bass: {}, treble: {}, voice: {}", 
        saved_profile.bass, saved_profile.treble, saved_profile.voice);

    {
        let mut last = LAST_PROFILE_NAME.lock().unwrap();
        *last = saved_profile.name.clone();
    }
    
    apply_dsp_settings(&saved_profile);

    let _ = fs::remove_file(SOCKET_PATH);

    let listener = UnixListener::bind(SOCKET_PATH)?;
    info!("Waiting for connections...");

    loop {
        match listener.accept().await {
            Ok((mut socket, _)) => {
                let mut buf = vec![0u8; 8192];
                let n = socket.read(&mut buf).await.unwrap_or(0);
                if n > 0 {
                    let message = String::from_utf8_lossy(&buf[..n]).trim().to_string();
                    
                    if message == "ENABLE" {
                        info!("Received ENABLE command");
                        if !check_filter_chain_running() {
                            let profile = load_saved_profile();
                            apply_dsp_settings(&profile);
                        } else {
                            set_default_sink_to_dsp();
                        }
                        let _ = socket.write_all(b"OK\n").await;
                    } else if message == "DISABLE" {
                        info!("Received DISABLE command");
                        disable_dsp_switch_to_direct();
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
                            // Send response immediately
                            let json = serde_json::to_string(&profile).unwrap_or_default();
                            let _ = socket.write_all(json.as_bytes()).await;
                            
                            // Then apply settings asynchronously
                            tokio::spawn(async move {
                                apply_dsp_settings(&profile);
                            });
                        } else {
                            let _ = socket.write_all(b"ERROR: profile not found\n").await;
                        }
                    } else if message.starts_with("SAVE:") {
                        let json_str = message.replace("SAVE:", "").trim().to_string();
                        if let Ok(profile) = serde_json::from_str::<AudioProfile>(&json_str) {
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
                            let new_vol: f64 = vol.max(0.01);
                            set_sink_volume(new_vol);
                            info!("Volume updated to {}%", (new_vol * 100.0) as i32);
                            let _ = socket.write_all(b"OK\n").await;
                        } else {
                            let _ = socket.write_all(b"ERROR: invalid volume\n").await;
                        }
                    } else if message.starts_with("UPDATE") {
                        info!("Received UPDATE command");
                        let json_str = message.replace("UPDATE:", "").replace("UPDATE", "");
                        if let Ok(profile) = serde_json::from_str::<AudioProfile>(&json_str) {
                            apply_dsp_settings(&profile);
                            info!("Update applied with profile settings");
                            let _ = socket.write_all(b"OK\n").await;
                        } else {
                            let _ = socket.write_all(b"ERROR: invalid JSON\n").await;
                        }
                    } else {
                        match serde_json::from_slice::<AudioProfile>(&buf[..n]) {
                            Ok(profile) => {
                                info!("Received: {}", profile.name);
                                info!("  bass: {}, treble: {}, voice: {}", 
                                    profile.bass, profile.treble, profile.voice);
                                info!("  EQ: {:?}", profile.eq_gains);
                                
                                if let Err(e) = save_profile(&profile) {
                                    error!("Failed to save profile: {}", e);
                                }
                                
                                apply_dsp_settings(&profile);
                                
                                let _ = socket.write_all(b"OK\n").await;
                                info!("Profile applied and saved");
                            }
                            Err(e) => {
                                error!("Failed to parse profile: {}", e);
                                let _ = socket.write_all(b"ERROR: invalid JSON\n").await;
                            }
                        }
                    }
                }
            }
            Err(e) => {
                error!("Accept error: {}", e);
            }
        }
    }
}
