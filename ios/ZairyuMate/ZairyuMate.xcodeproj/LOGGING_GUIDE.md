# 📊 Logging Guide - ZairyuMate

## How to View Logs on Your Physical iPhone

### ✅ Method 1: Xcode Console (Recommended)

**Best for: Real-time debugging while developing**

1. **Connect your iPhone** to your Mac with USB cable
2. **Select your iPhone** as the run destination in Xcode
3. **Run the app** (⌘R)
4. **Open the Console** (bottom panel in Xcode)
5. **All logs appear in real-time** as you use the app

**Tips:**
- Filter by typing `[NFC]`, `[ViewModel]`, or `[Parser]` in the search box
- Look for emoji prefixes: 🔵 (progress), ✅ (success), ❌ (error)
- Console shows ONLY your app's logs automatically

---

### 🌐 Method 2: Wireless Debugging (No Cable Needed)

**Best for: Testing NFC scanning without cable in the way**

**One-time setup:**
1. Connect iPhone via **USB cable**
2. Open **Xcode** → **Window** → **Devices and Simulators** (⇧⌘2)
3. Select your iPhone from left sidebar
4. ✅ Check **"Connect via network"**
5. Wait for network icon 🌐 to appear (takes ~30 seconds)
6. **Disconnect the cable** when you see "Ready to use over network"

**Daily use:**
1. Make sure **iPhone and Mac are on same WiFi**
2. **iPhone appears in Xcode** with 🌐 icon (no cable needed!)
3. **Select it and run** (⌘R)
4. **Scan your card freely** without cable blocking the back
5. **Logs appear in Xcode Console** over WiFi

⚠️ **Important:** Both devices must be on the same WiFi network

---

### 📱 Method 3: Console.app (Detailed System Logs)

**Best for: Investigating crashes or system-level issues**

1. **Connect iPhone** to Mac (or use WiFi if configured)
2. **Open Console.app**
   - Press **⌘Space** and type "Console"
   - Or find it in `/Applications/Utilities/Console.app`
3. **Select your iPhone** from left sidebar under "Devices"
4. **Filter logs:**
   - In search box, type: `process:ZairyuMate`
   - Or click "Start" button to see all logs
5. **Use advanced filters:**
   - `subsystem:com.khanhnguyenhoangviet.zairyumate` - All app logs
   - `category:NFC` - Only NFC logs
   - `category:Parser` - Only parser logs
   - `category:ViewModel` - Only ViewModel logs

**Search examples:**
```
process:ZairyuMate AND category:NFC
process:ZairyuMate AND "Step 1"
process:ZairyuMate AND level:error
```

---

### 📝 Method 4: Xcode Devices Window

**Best for: Viewing logs after the fact**

1. **Open Xcode** → **Window** → **Devices and Simulators** (⇧⌘2)
2. **Select your iPhone**
3. **Click "Open Console"** button at bottom right
4. **Run your app** on the device
5. **Filter** by typing search terms in the filter box

---

## Current Logging System

### Print-based Logging (Current)

Your app currently uses `print()` statements wrapped in `#if DEBUG`:

**Advantages:**
- ✅ Simple and easy to use
- ✅ Works immediately in Xcode Console
- ✅ Zero overhead in Release builds
- ✅ Good for development

**Disadvantages:**
- ⚠️ Hard to filter in Console.app
- ⚠️ All logs mixed together
- ⚠️ No log levels (info vs error)

**Example:**
```swift
#if DEBUG
print("🔵 [NFC] Starting scan...")
#endif
```

---

## Optional Upgrade: OSLog (Recommended for Production Apps)

### What is OSLog?

OSLog is Apple's unified logging system that provides:
- ✅ **Better performance** - More efficient than print()
- ✅ **Easy filtering** - Filter by subsystem and category
- ✅ **Log levels** - Debug, Info, Error, Fault
- ✅ **Privacy** - Automatic redaction of sensitive data
- ✅ **Persistence** - Logs saved even after app closes
- ✅ **Works in Console.app** - Professional log viewing

### How to Use (Optional)

I've created `app-logger.swift` with pre-configured loggers:

```swift
// Instead of:
#if DEBUG
print("🔵 [NFC] Step 1: Selecting application...")
#endif

// Use:
AppLogger.nfc.step(1, "Selecting application...")

// Other examples:
AppLogger.nfc.success("Card read complete - \(data.count) bytes")
AppLogger.nfc.failure("Invalid response from card")
AppLogger.parser.info("Starting parse")
AppLogger.viewModel.warning("Card number invalid")
```

### Viewing OSLog in Console.app

1. **Open Console.app**
2. **Select your iPhone**
3. **Filter by subsystem:**
   ```
   subsystem:com.khanhnguyenhoangviet.zairyumate
   ```
4. **Or filter by category:**
   ```
   category:NFC
   category:Parser
   category:ViewModel
   ```

### Should You Migrate?

**Keep print() if:**
- You're still in early development
- You only debug via Xcode Console
- Simplicity is more important

**Migrate to OSLog if:**
- You want professional logging
- You debug complex issues with Console.app
- You want to see logs from TestFlight/Production (carefully!)
- You want better performance

**Migration is optional!** Your current print-based system works perfectly fine for development.

---

## Quick Reference: Current Log Prefixes

### Emojis:
- 🔵 = In progress / Step
- 🟢 = Success (intermediate)
- ✅ = Complete / Success (final)
- 🔴 = Failed step
- ❌ = Error / Failure
- ⚠️ = Warning
- 📦 = Data packet
- 📊 = Data information
- 📁 = File operation
- 💾 = Save operation
- 🚀 = Starting operation
- 🏁 = Finished operation
- 🛑 = Cancelled

### Tags:
- `[NFC]` - NFC reader service
- `[ViewModel]` - View model logic
- `[Parser]` - Data parser

### Example NFC Scan Log Flow:

```
🚀 [ViewModel] Starting scan with card number: AB12345678CD
📡 [ViewModel] Initiating NFC scan...

📶 NFC Session became active
🔵 [NFC] Starting card read at 2026-01-29...
🔵 [NFC] Step 1: Selecting application...
🟢 [NFC] Step 1 completed in 0.234s
🔵 [NFC] Step 2: Verifying card number...
🟢 [NFC] Step 2 completed in 0.156s
📁 [NFC] Selecting EF01 (0x01)...
📦 [NFC] Chunk 1 read in 0.089s - 255 bytes
✅ [NFC] EF01 complete: 512 bytes in 0.345s
🟢 [NFC] ✅ TOTAL READ TIME: 2.456s - Total data: 1234 bytes

✅ [ViewModel] NFC scan complete - received 1234 bytes
🔍 [ViewModel] Parsing card data...

🔍 [Parser] Starting parse - total data: 1234 bytes
📦 [Parser] EF01 segment: 8 bytes
📦 [Parser] DF1/EF01 segment: 1223 bytes
👤 [Parser] Name: JOHN DOE
✅ [Parser] Parsing complete!

✅ [ViewModel] Parsing complete
💾 [ViewModel] Saving card data to profile...
✅ [ViewModel] Profile updated successfully
🏁 [ViewModel] Scan process finished
```

---

## Troubleshooting

### "I don't see any logs!"

1. **Check build configuration:**
   - Logs only work in **DEBUG** builds
   - Click your scheme (top left) → Edit Scheme → Run → Build Configuration
   - Should be set to "Debug"

2. **Check console visibility:**
   - In Xcode, press **⌘⇧Y** to show/hide the console
   - Make sure you're not filtering out your logs

3. **Check device connection:**
   - Device must be connected (cable or WiFi)
   - Device must trust your Mac
   - App must be running from Xcode (not launched manually)

### "Logs are too noisy"

**In Xcode Console:**
- Use the search/filter box
- Type `[NFC]` to see only NFC logs
- Type `❌` to see only errors

**In Console.app:**
- Use process filter: `process:ZairyuMate`
- Add category filter: `AND category:NFC`
- Filter by level: `AND level:error`

### "Wireless debugging not working"

1. **Check WiFi:**
   - Both devices on same WiFi network
   - No VPN active
   - No firewall blocking

2. **Reset connection:**
   - Uncheck "Connect via network"
   - Reconnect USB cable
   - Check it again
   - Wait for 🌐 icon

3. **Restart:**
   - Restart Xcode
   - Restart your iPhone
   - Try USB cable first

---

## Best Practices

### ✅ Do:
- Use descriptive messages
- Include relevant data (sizes, counts, names)
- Log both success and failure paths
- Include timing for performance analysis
- Use emoji prefixes for visual scanning

### ❌ Don't:
- Log sensitive data (passwords, tokens)
- Log in tight loops (slows app down)
- Leave logs in Release builds (use `#if DEBUG`)
- Log personal information without user consent

### Example:
```swift
// ✅ Good
#if DEBUG
print("✅ [NFC] Card read complete - \(data.count) bytes in \(duration)s")
#endif

// ❌ Bad (sensitive data)
#if DEBUG
print("User password: \(password)")
#endif

// ❌ Bad (too verbose)
for byte in data {
    print("Byte: \(byte)")  // Don't do this for large data!
}
```

---

## Summary: Quick Start

**To see logs RIGHT NOW:**

1. **Connect iPhone to Mac** (USB cable)
2. **Run app from Xcode** (⌘R)
3. **Use your NFC scan feature**
4. **Watch Xcode Console** (bottom panel)
5. **Search for** `[NFC]` to filter

That's it! You'll see all the logs in real-time. 🚀

**For wireless debugging:**
- Set up "Connect via network" once
- Then you can unplug and debug over WiFi
- Perfect for NFC testing (no cable in the way!)
