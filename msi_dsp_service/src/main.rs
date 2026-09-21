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
// Graph hosting: the filter graph runs INSIDE the main PipeWire daemon via
// a drop-in (a nested `pipewire -c` host exposes nodes but, on PipeWire
// >= 1.6, never exposes their ports — verified empirically). Structure is
// therefore install/boot-time state; runtime changes are params-only and
// can never pause audio.
const FILTER_DROPIN_PATH: &str = ".config/pipewire/pipewire.conf.d/99-msi-dsp.conf";
/// Bump whenever the graph TEMPLATE changes so a newer binary reloads the
/// daemon exactly once (gain values are live params, not structure).
const GRAPH_VERSION: u32 = 4;

fn filter_dropin_path() -> String {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    format!("{}/{}", home, FILTER_DROPIN_PATH)
}

static FILTER_CHAIN_RUNNING: AtomicBool = AtomicBool::new(false);
static LAST_PROFILE_NAME: Mutex<String> = Mutex::new(String::new());
static DSP_ENABLED: AtomicBool = AtomicBool::new(true);

// Audio path design (direct speaker, no virtual sinks):
//   apps -> msi_dsp_input (persistent filter-chain sink) -> msi_dsp_output
//       -> physical speaker (pw-linked, speaker stays the only HW output).
// There is deliberately NO msi_dsp_sink null-sink and NO loopback hops:
// every extra hop is latency plus a re-creation glitch source. The system
// default sink points at the chain while enabled (one stream move, a single
// brief gap only on enable/disable toggles) and NEVER moves on value
// changes — those only touch live filter params on the persistent graph.

/// Which optional processing stages are actually usable on this machine.
/// The core EQ path is pure builtin biquads (always available); LADSPA
/// stages are included only when their plugin files exist, so the service
/// degrades gracefully instead of failing the whole graph.
struct PluginProbe {
    spatializer: bool,
    compressor: bool,
    limiter: bool,
}

static PLUGINS: LazyLock<PluginProbe> = LazyLock::new(|| {
    fn exists(name: &str) -> bool {
        const DIRS: [&str; 3] = [
            "/usr/lib/ladspa",
            "/usr/lib64/ladspa",
            "/usr/local/lib/ladspa",
        ];
        DIRS.iter().any(|d| std::path::Path::new(d).join(name).exists())
    }
    let p = PluginProbe {
        spatializer: exists("matrix_spatialiser_1422.so"),
        compressor: exists("dyson_compress_1403.so"),
        limiter: exists("fast_lookahead_limiter_1913.so"),
    };
    info!(
        "LADSPA stages: spatializer={} compressor={} limiter={}",
        p.spatializer, p.compressor, p.limiter
    );
    p
});

// Glitch-free live updates: params are diffed against the last-pushed
// snapshot (slider drags mostly change 1-2 controls — the other ~30 are
// skipped), pushed in ONE shell spawn, at most every PUSH_INTERVAL_MS.
// The filter graph itself is NEVER restarted on value changes.
static FILTER_NODE_ID: Mutex<Option<u32>> = Mutex::new(None);
static LAST_PARAMS: LazyLock<Mutex<HashMap<String, f64>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));
static PENDING_PROFILE: Mutex<Option<AudioProfile>> = Mutex::new(None);
static PARAM_GEN: std::sync::atomic::AtomicU64 =
    std::sync::atomic::AtomicU64::new(0);
static LAST_PUSH: LazyLock<Mutex<std::time::Instant>> =
    LazyLock::new(|| Mutex::new(std::time::Instant::now()));
static FLUSH_LOCK: Mutex<()> = Mutex::new(());
const PUSH_INTERVAL_MS: u64 = 100;

/// Routing latch: once output→speaker is verified live, per-UPDATE work
/// skips ALL routing syscalls (re-linking identical links would unplug and
/// re-plug audio on every slider tick — an audible stutter source).
/// Cleared by the device monitor (topology changed), the watchdog (link
/// gone) and push failures (graph gone).
static ROUTING_OK: AtomicBool = AtomicBool::new(false);

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

/// Display-to-real temper: UIs show 0-100%, but the range is stretched
/// smoothly onto real 0.35-1.40: a displayed 0% lands on a 0.35 audible
/// floor, 100% lands on a 1.40 boost, linear in between
/// (real = 0.35 + 1.05 * display). True mute travels as a NEGATIVE
/// volume sentinel, never as zero.
fn temper_volume(display: f64) -> f64 {
    if display <= 0.01 {
        0.35
    } else {
        0.35 + 1.05 * display.clamp(0.0, 1.0)
    }
}

fn set_sink_volume(volume: f64) {
    let pct = (volume * 100.0).round() as i32;
    // Drive BOTH the processing chain and the physical speaker: the app
    // slider must mean "how loud is the room", not "how loud is one hop".
    // (A speaker left at 33% while the chain sits at 100% is exactly why
    // full volume used to feel quiet.)
    // NOTE: wpctl only accepts numeric IDs (names fail) while pactl only
    // accepts names for over-100% values — hence one of each.
    let _ = Command::new("wpctl")
        .args(["set-volume", "@DEFAULT_AUDIO_SINK@", &format!("{}%", pct)])
        .output();
    if let Some(speaker) = pick_physical_speaker() {
        let _ = Command::new("pactl")
            .args(["set-sink-volume", &speaker, &format!("{}%", pct)])
            .output();
    }
}

/// The chain is "running" iff its input sink node exists in the graph.
/// Node presence (not process names) is the source of truth: it also covers
/// PipeWire restarts and crashes, where the process may linger but the graph
/// is gone.
/// Structural signature the daemon should be running: template version +
/// LADSPA stage presence. Gain values are live params, NOT structure.
fn desired_signature() -> (u32, bool, bool, bool) {
    (GRAPH_VERSION, PLUGINS.spatializer, PLUGINS.compressor, PLUGINS.limiter)
}

/// True iff the on-disk drop-in already describes exactly the graph this
/// binary would generate (version + stages). Reads, never writes.
fn dropin_matches() -> bool {
    let (ver, sp, co, li) = desired_signature();
    let path = filter_dropin_path();
    let Ok(content) = fs::read_to_string(&path) else {
        return false;
    };
    content.contains(&format!("# graph-version = {}", ver))
        && content.contains("name = \"spatializer\"") == sp
        && content.contains("name = \"compressor\"") == co
        && content.contains("name = \"limiter\"") == li
}

/// Ensures the daemon runs THIS binary's graph, touching the daemon only
/// when necessary (file rewrite + restart is the single audio-blip
/// operation, confined to install/upgrade/recovery — never value changes).
/// Returns true when the input node is present afterwards.
fn ensure_graph_running(profile: &AudioProfile) -> bool {
    if !dropin_matches() {
        info!("Drop-in stale or missing — regenerating graph and reloading daemon...");
        if let Err(e) = generate_filter_chain_config(profile) {
            error!("Graph generation failed: {}", e);
            return false;
        }
        if !start_filter_chain() {
            error!("Daemon reload failed; staying on direct output");
            return false;
        }
    } else if !check_filter_chain_running() {
        info!("Drop-in current but nodes missing — reloading daemon...");
        if !start_filter_chain() {
            error!("Daemon reload failed; staying on direct output");
            return false;
        }
    }
    // (Re)loaded or already live: drop stale caches so ids/params resolve.
    forget_node_id(&FILTER_NODE_ID);
    LAST_PARAMS.lock().unwrap().clear();
    check_filter_chain_running()
}

fn check_filter_chain_running() -> bool {
    get_node_id_by_name("msi_dsp_input").is_some()
}

/// Engine lifecycle. The graph is main-daemon state (see FILTER_DROPIN_PATH):
/// starting = write drop-in + restart user audio services ONCE. This is the
/// ONLY operation that briefly interrupts audio, and it happens exclusively
/// on install/recovery — never on value changes.
fn kill_filter_chain() {
    info!("Removing DSP drop-in (full teardown)...");
    let _ = fs::remove_file(filter_dropin_path());
    let _ = Command::new("systemctl")
        .args(["--user", "restart", "pipewire", "wireplumber"])
        .output();
    std::thread::sleep(std::time::Duration::from_millis(1500));
}

fn restart_audio_services() -> bool {
    info!("Restarting user PipeWire services to (re)load DSP graph...");
    let out = Command::new("systemctl")
        .args(["--user", "restart", "pipewire", "wireplumber"])
        .output();
    match out {
        Ok(o) if o.status.success() => {
            std::thread::sleep(std::time::Duration::from_millis(1500));
            true
        }
        _ => {
            error!("Failed to restart PipeWire services");
            false
        }
    }
}

fn start_filter_chain() -> bool {
    // Drop-in must already be (re)generated by the caller; this only
    // reloads the daemon and waits for the nodes. One audio blip here —
    // install/recovery path only, never on value changes.
    if !restart_audio_services() {
        return false;
    }

    // Poll for the input node: fast machines proceed immediately.
    for _ in 0..50 {
        std::thread::sleep(std::time::Duration::from_millis(100));
        if get_node_id_by_name("msi_dsp_input").is_some() {
            info!("msi_dsp_input node online (main daemon)");
            return true;
        }
    }
    error!("Drop-in loaded but msi_dsp_input never appeared");
    false
}

fn link_filter_chain() -> bool {
    info!("Linking filter output straight to the physical speaker...");

    // Speaker picker (not the momentary pactl default: during daemon
    // restarts the default can briefly be an HDMI sink, which misroutes us).
    // Skips our own nodes so a loop is impossible.
    let target_sink = match pick_physical_speaker() {
        Some(s) => s,
        None => {
            warn!("No physical speaker found, skipping link");
            return false;
        }
    };

    info!("Targeting physical sink: {}", target_sink);

    // Ports materialize a moment after the nodes do; poll briefly instead
    // of one-shotting (otherwise the first link attempt always loses).
    let mut ports_ready = false;
    for _ in 0..30 {
        let probe = Command::new("pw-link")
            .args(["-o", "msi_dsp_output"])
            .output();
        if let Ok(o) = probe {
            let t = String::from_utf8_lossy(&o.stdout);
            if t.contains("msi_dsp_output:output_FL")
                && t.contains("msi_dsp_output:output_FR")
            {
                ports_ready = true;
                break;
            }
        }
        std::thread::sleep(std::time::Duration::from_millis(100));
    }
    if !ports_ready {
        warn!("Output ports never appeared; will retry via watchdog");
        return false;
    }

    // Link msi_dsp_output (chain exit) to the physical sink. Disconnect
    // each output port first (a two-port -d targets the wrong thing and
    // leaves stale links behind).
    for port in ["msi_dsp_output:output_FL", "msi_dsp_output:output_FR"] {
        let _ = Command::new("pw-link").args(["-d", port]).output();
    }

    let l1 = Command::new("pw-link")
        .args(["msi_dsp_output:output_FL", &format!("{}:playback_FL", target_sink)])
        .output();
    let l2 = Command::new("pw-link")
        .args(["msi_dsp_output:output_FR", &format!("{}:playback_FR", target_sink)])
        .output();

    match (l1, l2) {
        (Ok(o1), Ok(o2)) if o1.status.success() && o2.status.success() => {
            info!("Output linked to {}", target_sink);
            true
        }
        _ if output_linked() => {
            // pw-link reports failure when the exact link already exists
            // ("File exists") — verify instead of trusting exit codes.
            info!("Output already linked to {}", target_sink);
            true
        }
        _ => {
            warn!("Failed to link output to {} (ports missing?)", target_sink);
            false
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
                            ROUTING_OK.store(false, Ordering::SeqCst);
                            tokio::time::sleep(tokio::time::Duration::from_millis(600)).await;
                            if link_filter_chain() {
                                ROUTING_OK.store(true, Ordering::SeqCst);
                            }
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

    // NOTE: `pactl set-default-sink` exits 0 but silently does NOTHING for
    // filter-chain sinks on PipeWire — the default must be written through
    // the metadata store instead. Verified empirically.
    let meta = Command::new("pw-metadata")
        .args(["-n", "default", "0", "default.audio.sink", "{\"name\":\"msi_dsp_input\"}"])
        .output();
    std::thread::sleep(std::time::Duration::from_millis(300));

    if meta.is_ok() {
        if get_default_sink_name().as_deref() == Some("msi_dsp_input") {
            info!("Default sink is msi_dsp_input (via pw-metadata)");
            return;
        }
    }
    warn!("pw-metadata did not stick, trying pactl fallback...");
    let _ = Command::new("pactl")
        .args(["set-default-sink", "msi_dsp_input"])
        .output();
}

/// True iff the chain output is actually linked to a physical (non-DSP)
/// sink. `pw-link -l` prints each port followed by peer lines:
///   msi_dsp_output:output_FL
///     |-> <peer>:playback_FL
/// A peer that is one of our own nodes does NOT count (loop guard).
fn output_linked() -> bool {
    // Simpler robust check: pw-link lists links as "out -> in" lines.
    let lout = Command::new("pw-link").args(["-l"]).output();
    if let Ok(lout) = lout {
        let ltext = String::from_utf8_lossy(&lout.stdout);
        let mut iter = ltext.lines().peekable();
        while let Some(line) = iter.next() {
            if line.contains("msi_dsp_output:output_") {
                // Next non-empty lines show the peer with "<-" marker.
                for peer in iter.by_ref().take(4) {
                    if peer.contains("<-") && !peer.contains("msi_dsp_output") {
                        return true;
                    }
                    if !peer.starts_with(' ') && !peer.starts_with('\t') && peer.contains(':') {
                        break;
                    }
                }
            }
        }
    }
    false
}
fn pick_physical_speaker() -> Option<String> {
    let out = Command::new("pactl").args(["list", "short", "sinks"]).output().ok()?;
    let text = String::from_utf8_lossy(&out.stdout);
    let mut fallback: Option<String> = None;
    for line in text.lines() {
        let parts: Vec<&str> = line.split(char::is_whitespace).filter(|s| !s.is_empty()).collect();
        if parts.len() < 2 {
            continue;
        }
        let name = parts[1].to_string();
        if name.starts_with("msi_dsp") || name.contains("monitor") {
            continue;
        }
        if fallback.is_none() {
            fallback = Some(name.clone());
        }
        if name.contains("Speaker") {
            return Some(name);
        }
    }
    fallback
}

fn get_default_sink_name() -> Option<String> {
    let out = Command::new("pactl").args(["get-default-sink"]).output().ok()?;
    if !out.status.success() {
        return None;
    }
    let name = String::from_utf8_lossy(&out.stdout).trim().to_string();
    if name.is_empty() {
        None
    } else {
        Some(name)
    }
}

fn disable_dsp_switch_to_direct() {
    info!("Switching to direct audio output (bypassing DSP)...");

    // pw-metadata, NOT pactl: pactl set-default-sink silently no-ops here.
    if let Some(name) = pick_physical_speaker() {
        let _ = Command::new("pw-metadata")
            .args(["-n", "default", "0", "default.audio.sink", &format!("{{\"name\":\"{}\"}}", name)])
            .output();
        std::thread::sleep(std::time::Duration::from_millis(300));
        if get_default_sink_name().as_deref() == Some(name.as_str()) {
            info!("Switched to speaker: {}", name);
            return;
        }
    }
    warn!("No physical speaker found; leaving routing untouched");
}

/// Watchdog: guarantees the system can NEVER be left silent or unlinked.
///  - Chain nodes gone + default still ours  -> move default back to speaker.
///  - DSP enabled + chain nodes gone        -> rebuild + relink + default.
///  - DSP enabled + output unlinked         -> relink live (daemon restarts
///    silently drop links while node names survive — this was the actual
///    cause of "controls do nothing audible").
/// Runs every 10s; covers crashes and PipeWire restarts.
fn watchdog_once() {
    let chain_alive = get_node_id_by_name("msi_dsp_input").is_some();
    let default = get_default_sink_name().unwrap_or_default();

    if !chain_alive && default == "msi_dsp_input" {
        warn!("Watchdog: chain dead while default — restoring speaker");
        disable_dsp_switch_to_direct();
    }

    if DSP_ENABLED.load(Ordering::SeqCst) && chain_alive && !output_linked() {
        warn!("Watchdog: output unlinked — relinking live (no restart, no gap)");
        ROUTING_OK.store(false, Ordering::SeqCst);
        if link_filter_chain() {
            ROUTING_OK.store(true, Ordering::SeqCst);
        }
    }

    if DSP_ENABLED.load(Ordering::SeqCst) && !chain_alive {
        warn!("Watchdog: rebuilding missing filter graph...");
        ROUTING_OK.store(false, Ordering::SeqCst);
        warn!("Watchdog: rebuilding missing filter graph...");
        let profile = load_saved_profile();
        // Reuse the structural path; never touches volume.
        forget_node_id(&FILTER_NODE_ID);
        LAST_PARAMS.lock().unwrap().clear();
        if generate_filter_chain_config(&profile).is_ok() && start_filter_chain() {
            link_filter_chain();
            set_default_sink_to_dsp();
            schedule_param_push(&profile);
        } else {
            error!("Watchdog: rebuild failed; system stays on direct output");
        }
    }
}

fn start_watchdog() {
    info!("Starting DSP watchdog (10s interval)...");
    tokio::spawn(async move {
        loop {
            tokio::time::sleep(tokio::time::Duration::from_secs(10)).await;
            watchdog_once();
        }
    });
}

/// Fully-resolved DSP controls: the SINGLE source of truth shared by graph
/// generation (initial values) and the live param pusher, so the two can
/// never disagree about what a profile means.
struct ResolvedControls {
    eq: [f64; 10],
    bass: f64,
    treble: f64,
    voice: f64,
    width: f64,
    limiter_threshold: f64,
    compress_ratio: f64,
}

fn resolve_controls(profile: &AudioProfile) -> ResolvedControls {
    let (mut bass, mut treble, mut voice, mut eq, width_base) = if profile.effects_enabled {
        let mut e = [0.0f64; 10];
        for (i, v) in e.iter_mut().enumerate() {
            *v = *profile.eq_gains.get(i).unwrap_or(&0.0);
        }
        (
            if profile.bass_boost { profile.bass } else { 0.0 },
            if profile.treble_enhancer { profile.treble } else { 0.0 },
            if profile.voice_clarity { profile.voice } else { 0.0 },
            e,
            profile.stereo_width,
        )
    } else {
        (0.0, 0.0, 0.0, [0.0; 10], 1.0)
    };

    // Surround width variations (neutral 1.0 when off).
    let width = if profile.surround {
        match profile.surround_variation.as_str() {
            "Headset" => width_base * 0.8,
            "Virtual" | "Surround" => width_base * 1.4,
            "3D" => width_base * 1.8,
            "Wide" => width_base * 2.5,
            _ => width_base,
        }
    } else {
        1.0
    };

    // Night mode + volume stabilizer targets for the compressor stage.
    let night_mode_active = profile.night_mode && profile.effects_enabled;
    let stabilizer_active = profile.limiter_enabled && profile.effects_enabled;
    let limiter_threshold = if night_mode_active {
        -12.0
    } else if stabilizer_active {
        -1.0
    } else {
        -0.1
    };
    let compress_ratio = if night_mode_active {
        8.0
    } else {
        profile.compressor_ratio.max(1.0)
    };

    // Headroom pre-trim (clip protection without a limiter stage): series
    // biquads stack, so cap the worst-case stacked boost at +6 dB. The
    // correction is spread (/3: overlapping skirts mean a per-band cut
    // bites ~3x overall) to preserve tone shape. With a real limiter
    // stage present the trim is unnecessary — it absorbs excess
    // transparently — so it is skipped. Night mode without a compressor
    // stage additionally calms peaks statically (+3 dB into the excess).
    let max_band = eq.iter().fold(0.0f64, |m, v| m.max(*v));
    let stacked = max_band + bass.max(0.0) * 0.7 + treble.max(0.0) * 0.5 + voice.max(0.0) * 0.5;
    let mut excess = (stacked - 6.0).max(0.0);
    if night_mode_active && !PLUGINS.compressor {
        excess += 3.0;
        info!("Night mode via static fallback (no compressor stage)");
    }
    let trim = if PLUGINS.limiter {
        0.0
    } else {
        excess / 3.0
    };
    if trim > 0.05 {
        info!("Headroom pre-trim engaged: -{:.1} dB (stacked boost was +{:.1} dB)", trim, stacked);
        for v in eq.iter_mut() {
            *v -= trim;
        }
        bass -= trim;
        treble -= trim;
        voice -= trim;
    }

    ResolvedControls { eq, bass, treble, voice, width, limiter_threshold, compress_ratio }
}

fn generate_filter_chain_config(profile: &AudioProfile) -> Result<()> {
    let eq_bands = [
        (32, "eq0"), (64, "eq1"), (125, "eq2"), (250, "eq3"), (500, "eq4"),
        (1000, "eq5"), (2000, "eq6"), (4000, "eq7"), (8000, "eq8"), (16000, "eq9")
    ];
    
    // Mono chain, duplicated per channel by PipeWire (see module docs:
    // "the graph will then be duplicated as many times to match the number
    // of input/output channels"). NEVER split L/R manually: fanning one
    // stereo stream into two mono chains without a `copy` node yields a
    // graph with no inputs and total silence.
    let mut eq_nodes = String::new();
    // Resolved once so all 10 bands share the same trim decision.
    let eq_resolved = resolve_controls(profile);
    for (i, (freq, name)) in eq_bands.iter().enumerate() {
        let gain = eq_resolved.eq[i];
        eq_nodes.push_str(&format!(
            r#"            {{ type = builtin label = bq_peaking name = "{}" control = {{ "Freq" = {} "Gain" = {} "Q" = 1.41 }} }}
"#,
            name, freq, gain
        ));
    }
    // Base gains + all variation math resolve through ONE function shared
    // with the live pusher, so initial and live values can never disagree.
    let ctl = resolve_controls(profile);
    let bass_gain = ctl.bass;
    let treble_gain = ctl.treble;
    let voice_gain = ctl.voice;
    let stereo_width = ctl.width;
    let limiter_threshold = ctl.limiter_threshold;
    let compress_ratio = ctl.compress_ratio;

    // --- Dynamic stage assembly -------------------------------------------
    // Core EQ/tone path is always present (builtin biquads). LADSPA stages
    // are spliced in only when probed present; otherwise the voice stage
    // feeds the outputs directly. Links are rebuilt to match, so the graph
    // is always valid on any machine.
    let have_spatial = PLUGINS.spatializer;
    let have_compress = PLUGINS.compressor;
    let have_limiter = PLUGINS.limiter;

    let mut stage_nodes = String::new();
    if have_spatial {
        stage_nodes.push_str(&format!(
            r#"            {{
                type = ladspa
                name = "spatializer"
                plugin = "/usr/lib/ladspa/matrix_spatialiser_1422.so"
                label = "matrixSpatialiser"
                control = {{ "Width" = {stereo_width} }}
            }}
"#,
        ));
    }
    if have_compress {
        stage_nodes.push_str(&format!(
            r#"            {{
                type = ladspa
                name = "compressor"
                plugin = "/usr/lib/ladspa/dyson_compress_1403.so"
                label = "dysonCompress"
                control = {{ "Peak limit (dB)" = {limiter_threshold} "Release time (s)" = 0.5 "Compression ratio" = {compress_ratio} }}
            }}
"#,
        ));
    }
    if have_limiter {
        stage_nodes.push_str(
            r#"            {{
                type = ladspa
                name = "limiter"
                plugin = "/usr/lib/ladspa/fast_lookahead_limiter_1913.so"
                label = "fastLookaheadLimiter"
                control = {{ "Input gain (dB)" = 0 "Limit (dB)" = -0.1 "Release time (s)" = 0.1 }}
            }}
"#,
        );
    }

    // Ordered single-port stages; PipeWire duplicates them per channel.
    // (Multi-port stereo LADSPA nodes would need explicit per-channel
    // links — revisit if plugins are ever installed.)
    let mut chain: Vec<(&str, &str)> = Vec::new();
    if have_spatial {
        // NOTE: spatializer is genuinely stereo; wiring it correctly needs
        // per-channel links. Not reachable while the plugin is absent.
        chain.push(("spatializer:Output", "spatializer:Input"));
    }
    if have_compress {
        chain.push(("compressor:Output", "compressor:Input"));
    }
    if have_limiter {
        chain.push(("limiter:Output", "limiter:Input"));
    }

    let mut stage_links = String::new();
    let mut prev = "voice:Out".to_string();
    for (out_port, in_port) in &chain {
        stage_links.push_str(&format!(
            "                    {{{{ output = \"{}\" input = \"{}\" }}}}\n",
            prev, in_port
        ));
        prev = out_port.to_string();
    }
    let stage_outputs = format!("\"{}\"", prev);
    info!(
        "Graph stages: spatializer={} compressor={} limiter={} (core EQ always on)",
        have_spatial, have_compress, have_limiter
    );

    let config = format!(r#"# MSI Center DSP graph (managed — do not hand-edit; rewritten on profile save).
# graph-version = {GRAPH_VERSION}
# Merged into the main PipeWire daemon via pipewire.conf.d. The daemon
# already provides rt/protocol/client/adapter modules, so only our chains
# are declared here.
context.modules = [
    {{ name = libpipewire-module-filter-chain
        args = {{
            node.name        = "msi_dsp_filter"
            node.description = "MSI DSP Playback"
            media.name       = "MSI DSP Engine"
            audio.channels   = 2
            audio.position   = [ "FL" "FR" ]
            filter.graph = {{
                nodes = [
{eq_nodes}            {{ type = builtin label = bq_lowshelf name = "bass" control = {{ "Freq" = 100 "Gain" = {bass_gain} "Q" = 0.707 }} }}
            {{ type = builtin label = bq_highshelf name = "treble" control = {{ "Freq" = 5000 "Gain" = {treble_gain} "Q" = 0.707 }} }}
            {{ type = builtin label = bq_peaking name = "voice" control = {{ "Freq" = 2000 "Gain" = {voice_gain} "Q" = 0.5 }} }}
{stage_nodes}                ]
                links = [
                    {{ output = "eq0:Out" input = "eq1:In" }}
                    {{ output = "eq1:Out" input = "eq2:In" }}
                    {{ output = "eq2:Out" input = "eq3:In" }}
                    {{ output = "eq3:Out" input = "eq4:In" }}
                    {{ output = "eq4:Out" input = "eq5:In" }}
                    {{ output = "eq5:Out" input = "eq6:In" }}
                    {{ output = "eq6:Out" input = "eq7:In" }}
                    {{ output = "eq7:Out" input = "eq8:In" }}
                    {{ output = "eq8:Out" input = "eq9:In" }}
                    {{ output = "eq9:Out" input = "bass:In" }}
                    {{ output = "bass:Out" input = "treble:In" }}
                    {{ output = "treble:Out" input = "voice:In" }}
{stage_links}                ]
                inputs  = [ "eq0:In" ]
                outputs = [ {stage_outputs} ]
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
    {{ name = libpipewire-module-echo-cancel
        flags = [ ifexists nofail ]
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
    
    let path = filter_dropin_path();
    if let Some(parent) = std::path::Path::new(&path).parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(&path, config)?;
    info!("Filter graph drop-in written: {} (Name={}, stages spatial={} compress={} limiter={})",
        path, profile.name, have_spatial, have_compress, have_limiter);
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

/// Flat (control, value) list for live pushes, resolved through the same
/// function as graph generation (trim included), gated to stages present
/// in the running graph.
fn compute_params(profile: &AudioProfile) -> Vec<(String, f64)> {
    let ctl = resolve_controls(profile);
    let mut out = Vec::with_capacity(20);

    let eq_bands = ["eq0", "eq1", "eq2", "eq3", "eq4", "eq5", "eq6", "eq7", "eq8", "eq9"];
    for (i, band) in eq_bands.iter().enumerate() {
        // Mono names: the graph is duplicated per channel by PipeWire, so
        // one control addresses every duplicate at once.
        out.push((format!("{}:Gain", band), ctl.eq[i]));
    }

    out.push(("bass:Gain".into(), ctl.bass));
    out.push(("treble:Gain".into(), ctl.treble));
    out.push(("voice:Gain".into(), ctl.voice));

    // Only address stages that exist in the running graph; anything else is
    // a failed set-param (harmless but noisy) — skip it.
    if PLUGINS.spatializer {
        out.push(("spatializer:Width".into(), ctl.width));
    }

    if PLUGINS.compressor {
        out.push(("compressor:Peak limit (dB)".into(), ctl.limiter_threshold));
        out.push(("compressor:Compression ratio".into(), ctl.compress_ratio));
    }

    if PLUGINS.limiter {
        out.push(("limiter:Limit (dB)".into(), -0.1));
    }

    out
}

fn cached_node_id(name: &str, cache: &Mutex<Option<u32>>) -> Option<u32> {
    if let Some(id) = *cache.lock().unwrap() {
        return Some(id);
    }
    let id = get_node_id_by_name(name)?;
    *cache.lock().unwrap() = Some(id);
    Some(id)
}

fn forget_node_id(cache: &Mutex<Option<u32>>) {
    *cache.lock().unwrap() = None;
}

/// Pushes ONLY changed controls in a SINGLE shell spawn (one fork per
/// UPDATE instead of ~40). Identical values are skipped entirely, so a
/// no-op UPDATE costs zero syscalls and zero graph negotiation.
fn push_params_diffed(node_id: u32, params: &[(String, f64)]) -> bool {
    const EPS: f64 = 1e-6;
    let mut last = LAST_PARAMS.lock().unwrap();
    let mut script = String::new();
    let mut count = 0;
    for (name, value) in params {
        let prev = last.get(name).copied().unwrap_or(f64::NAN);
        if (prev - value).abs() <= EPS {
            continue;
        }
        last.insert(name.clone(), *value);
        // Quote the control name: several contain spaces and parentheses.
        script.push_str(&format!(
            "pw-cli set-param {} Props '{{ params = [ \"{}\" {} ] }}' >/dev/null 2>&1; ",
            node_id, name, value
        ));
        count += 1;
    }
    drop(last);
    if count == 0 {
        return true;
    }
    debug!("Pushing {} changed params to node {}", count, node_id);
    Command::new("sh")
        .args(["-c", &script])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

fn push_profile_params(profile: &AudioProfile) {
    let params = compute_params(profile);
    // Drop the flush serialization lock quickly; the actual push is short.
    let _guard = FLUSH_LOCK.lock().unwrap();
    for attempt in 0..2 {
        if let Some(id) = cached_node_id("msi_dsp_input", &FILTER_NODE_ID) {
            if push_params_diffed(id, &params) {
                return;
            }
            // Push failed (stale id after a graph rebuild?) — re-resolve once.
            warn!("Param push failed (attempt {}), re-resolving node id", attempt);
            forget_node_id(&FILTER_NODE_ID);
        } else {
            warn!("msi_dsp_input node not found, skipping param push");
            // Graph is gone: force full recovery on the next apply.
            ROUTING_OK.store(false, Ordering::SeqCst);
            return;
        }
    }
    // Both attempts failed: graph likely gone; force recovery next time.
    ROUTING_OK.store(false, Ordering::SeqCst);
}

/// Coalescing entry point: rapid UPDATE storms (EQ slider drags) collapse
/// into at most one graph push per PUSH_INTERVAL_MS, always the LATEST
/// values. The graph is never restarted — only params move.
fn schedule_param_push(profile: &AudioProfile) {
    use std::sync::atomic::Ordering;
    let generation = PARAM_GEN.fetch_add(1, Ordering::SeqCst) + 1;
    *PENDING_PROFILE.lock().unwrap() = Some(profile.clone());

    let elapsed = LAST_PUSH.lock().unwrap().elapsed().as_millis() as u64;
    if elapsed >= PUSH_INTERVAL_MS {
        flush_pending(generation);
    } else {
        let wait = PUSH_INTERVAL_MS - elapsed;
        std::thread::spawn(move || {
            std::thread::sleep(std::time::Duration::from_millis(wait));
            if PARAM_GEN.load(Ordering::SeqCst) == generation {
                flush_pending(generation);
            }
            // Else: a newer generation arrived; it owns the flush.
        });
    }
}

fn flush_pending(generation: u64) {
    let profile = PENDING_PROFILE.lock().unwrap().clone();
    if let Some(p) = profile {
        push_profile_params(&p);
        *LAST_PUSH.lock().unwrap() = std::time::Instant::now();
        debug!("Flushed param generation {}", generation);
    }
}


/// Microphone side-effects. These act on the real capture device via pactl
/// (user space, no graph needed), so they apply even when DSP processing
/// itself is bypassed. Echo-cancellation/noise-suppression toggles need a
/// WebRTC backend that this system does not provide; the echo-cancel
/// module stays loaded for its monitor plumbing and the flags are logged
/// honestly instead of pretending.
fn apply_mic_settings(profile: &AudioProfile) {
    let mute = if profile.mic_enabled { "false" } else { "true" };
    let _ = Command::new("pactl")
        .args(["set-source-mute", "@DEFAULT_SOURCE@", mute])
        .output();

    // mic_gain is a linear multiplier roughly in 0.0..2.0.
    let pct = (profile.mic_gain.clamp(0.0, 2.0) * 100.0).round() as i32;
    let _ = Command::new("pactl")
        .args(["set-source-volume", "@DEFAULT_SOURCE@", &format!("{}%", pct)])
        .output();

    if profile.echo_cancellation || profile.mic_noise_suppression {
        info!(
            "Mic FX requested (echo-cancel={}, noise-suppression={}): no WebRTC backend on this system — mic stays dry apart from mute/gain",
            profile.echo_cancellation, profile.mic_noise_suppression
        );
    }
}

fn apply_dsp_settings(profile: &AudioProfile, update_volume: bool) {
    // Mic first: independent of the playback graph state.
    apply_mic_settings(profile);

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
    
    // Persistent-graph policy: the daemon runs this binary's structure
    // (reloaded only on version/stage change or vanished nodes — the only
    // audio blip, never on value changes). Routing (link + default) runs
    // once per topology via the ROUTING_OK latch; values go through the
    // coalesced param pusher. Steady-state UPDATEs touch NOTHING but
    // changed filter params: no relink, no default move, no pause.
    let mut routed = ROUTING_OK.load(Ordering::SeqCst);
    if !routed || !dropin_matches() {
        if !ensure_graph_running(profile) {
            error!("Graph unavailable; staying on direct output");
            return;
        }
        if link_filter_chain() {
            routed = true;
            ROUTING_OK.store(true, Ordering::SeqCst);
            if DSP_ENABLED.load(Ordering::SeqCst) {
                set_default_sink_to_dsp();
            }
        } else {
            ROUTING_OK.store(false, Ordering::SeqCst);
            error!("Routing unavailable; staying on direct output");
            return;
        }
    }
    schedule_param_push(profile);
    
    if update_volume {
        let applied = temper_volume(profile.volume);
        set_sink_volume(applied);
        info!("Volume set to {}% (tempered)", (applied * 100.0) as i32);
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
    
    // Always (re)generate the drop-in at startup: the binary may be newer
    // than the on-disk graph (updates must reach the daemon). Cheap when
    // unchanged; runtime UPDATEs never touch structure.
    if let Err(e) = generate_filter_chain_config(&saved_profile) {
        error!("Startup graph generation failed: {}", e);
    }

    // Auto-apply saved profile on startup
    info!("Auto-applying saved DSP profile on service startup...");
    apply_dsp_settings(&saved_profile, false);

    // Start background device monitor for seamless switching
    start_device_monitor();

    // Watchdog: rebuilds a dead graph, never leaves a dead default sink.
    start_watchdog();

    // Auto-set default sink to DSP if DSP is enabled
    if DSP_ENABLED.load(Ordering::SeqCst) && check_filter_chain_running() {
        set_default_sink_to_dsp();
        info!("Auto-set default sink to MSI DSP");
    } else if DSP_ENABLED.load(Ordering::SeqCst) {
        warn!("Filter graph unavailable at startup; audio stays direct until it can start");
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
                                        DSP_ENABLED.store(true, Ordering::SeqCst);
                                        ROUTING_OK.store(false, Ordering::SeqCst);
                                        if !check_filter_chain_running() {
                                            let profile = load_saved_profile();
                                            apply_dsp_settings(&profile, false);
                                        } else {
                                            // Warm graph: relink + default only, no restart, no gap.
                                            if link_filter_chain() {
                                                ROUTING_OK.store(true, Ordering::SeqCst);
                                            }
                                            set_default_sink_to_dsp();
                                        }
                                        let _ = socket.write_all(b"OK\n").await;
                                    } else if message == "DISABLE" {
                                        info!("Received DISABLE command");
                                        DSP_ENABLED.store(false, Ordering::SeqCst);
                                        disable_dsp_switch_to_direct();
                                        // Graph stays warm on purpose: re-enable is
                                        // instant (relink + default) with no 2s rebuild.
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
                                            if vol < 0.0 {
                                                // Mute sentinel from the app mute button.
                                                // NOTE: pactl only resolves @DEFAULT_SINK@
                                                // (@DEFAULT_AUDIO_SINK@ is wpctl-only).
                                                for target in ["@DEFAULT_SINK@"] {
                                                    let _ = Command::new("pactl")
                                                        .args(["set-sink-mute", target, "true"])
                                                        .output();
                                                }
                                                if let Some(speaker) = pick_physical_speaker() {
                                                    let _ = Command::new("pactl")
                                                        .args(["set-sink-mute", &speaker, "true"])
                                                        .output();
                                                }
                                            } else {
                                                // Any real volume drag unmutes first.
                                                for target in ["@DEFAULT_SINK@"] {
                                                    let _ = Command::new("pactl")
                                                        .args(["set-sink-mute", target, "false"])
                                                        .output();
                                                }
                                                if let Some(speaker) = pick_physical_speaker() {
                                                    let _ = Command::new("pactl")
                                                        .args(["set-sink-mute", &speaker, "false"])
                                                        .output();
                                                }
                                                set_sink_volume(temper_volume(vol));
                                            }
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
    profile.volume = temper_volume(profile.volume);
    profile.stereo_width = profile.stereo_width.clamp(0.0, 2.0);
}
