![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

# 🚀 WiFi Watchdog Intelligent

WiFi Watchdog is a lightweight and intelligent Linux tool that automatically monitors and repairs Wi-Fi connectivity issues.

It detects common problems such as:
- ❌ Driver crashes
- ❌ Missing IP (DHCP issues)
- ❌ DNS failures
- ❌ Wi-Fi interface instability

And applies automatic fixes without user intervention.

---

# 🎯 Features

- ✅ Automatic Wi-Fi health monitoring
- ✅ Smart issue detection (driver / DHCP / DNS)
- ✅ Automatic recovery actions
- ✅ Systemd integration (timer-based, efficient)
- ✅ Multi-distro support:
  - Debian / Ubuntu / Linux Mint
  - Fedora
  - Arch / Manjaro
- ✅ KDE notifications (notify-send)
- ✅ Logging system with history tracking
- ✅ Lightweight (no background loops, uses systemd timer)

---

# ⚙️ How it works

WiFi Watchdog runs periodically using a systemd timer:

1. Checks network connectivity (ping)
2. Detects if:
   - Interface is down
   - No IP assigned (DHCP issue)
   - DNS is failing
3. Applies the appropriate fix:
   - Reload Wi-Fi driver
   - Renew DHCP lease
   - Restart NetworkManager
   - Reset Wi-Fi radio

---

# 📦 Installation

## One-line install (recommended)

```bash
curl -sSL https://raw.githubusercontent.com/dpfpic/wifi-watchdog/main/wifi-watchdog-install.sh | sudo bash
