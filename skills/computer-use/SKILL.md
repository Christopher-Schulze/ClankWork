---
name: computer-use
description: "Use this skill whenever the task requires seeing, interacting with, or automating the macOS desktop or any GUI application. Triggers: clicking UI elements, reading screen content, automating workflows across apps, taking screenshots, verifying visual output, controlling any running app. Works on local macOS only."
license: MIT
---

# Computer Use — Native Vision + Peekaboo MCP

## Entscheidungsbaum — was zuerst

```
Browser-Task?           → Playwright (kein Screenshot, DOM direkt)
UI-State lesen?         → osascript Accessibility (~50ms, kein Screenshot)
Visuelle Inhalte sehen? → screencapture + Read (~250ms)
App-Fenster spezifisch? → Peekaboo image (~500ms)
Apps/Bounds listen?     → Peekaboo list (~100ms)
```

| Methode | Speed | Wann |
|---------|-------|------|
| **osascript Accessibility** | ~50ms | UI-Text, Buttons, Felder, Zustand lesen — kein Bild nötig |
| **Playwright snapshot** | ~100ms | Alles im Browser |
| **screencapture + Read** | ~250ms | Visueller Screen-Inhalt, Charts, Bilder |
| **Peekaboo `image`** | ~500ms | App-Fenster spezifisch, Hintergrund-Capture |
| **Peekaboo `list`** | ~100ms | App-Liste, Window-IDs, Bounds |

**Goldene Regel: Screenshot ist letztes Mittel.** Erst Accessibility API versuchen — wenn UI-State als Text lesbar ist, braucht man kein Bild.

---

## Vision Fast Path (bevorzugt, wenn vom Modell unterstützt)

Qwen Code kann bei vision-fähiger Modellkonfiguration Bilder direkt über das `Read`-Tool in den Modellkontext laden. PNG/JPG/GIF/WEBP kommen als base64 inlineData zurück, ohne zusätzlichen MCP-Roundtrip.

### Screenshots

```bash
# Vollbild (alle Monitore, still/kein Sound)
screencapture -x /tmp/screen.png

# Einzelner Monitor (0-indexed: -D 1 = Monitor 1, -D 2 = Monitor 2)
screencapture -x -D 1 /tmp/screen.png

# Bestimmtes Fenster per Window-ID (ID aus Peekaboo list holen) - einzige korrekte Methode
screencapture -x -l <windowID> /tmp/window.png

# HINWEIS: Es gibt keine screencapture-Option für "aktives Fenster" ohne Window-ID.
# -o ohne -w hat keinen Effekt (macht Vollbild). Für frontmost window: Peekaboo image app_target="frontmost" verwenden.
```

Danach: `Read`-Tool auf `/tmp/screen.png` - Modell sieht das Bild direkt.

### Video Recording

Wenn das konfigurierte Modell Video unterstützt, kann macOS `screencapture` Bildschirmvideos für die Analyse aufnehmen:

```bash
# Bildschirmvideo aufnehmen (5 Sekunden, still)
screencapture -x -v -V 5 /tmp/recording.mov

# Mit Audio vom Mikrofon
screencapture -x -v -V 5 -g /tmp/recording.mov

# Bestimmter Monitor
screencapture -x -v -V 5 -D 1 /tmp/recording.mov
```

Flags:
- `-v` - Video-Modus (nimmt .mov auf)
- `-V <seconds>` - Maximale Dauer in Sekunden
- `-g` - Audio vom Default-Mikrofon mitaufnehmen
- `-x` - Kein UI-Sound beim Start

Danach: `Read`-Tool auf `/tmp/recording.mov` - Modell sieht das Video direkt.

**Einsatz**: UI-Flow-Analyse, Bug-Reproduktion aufnehmen, Animationen prüfen, Bildschirmaktivitaet beobachten.

**Cleanup nach Analyse:**
```bash
rm /tmp/recording.mov
```

**Cleanup nach Analyse:**
```bash
rm /tmp/screen.png
```

---

## Setup — Peekaboo MCP (weiterhin aktiv für list + window-captures)

| Component | Detail |
|-----------|--------|
| MCP Server | `peekaboo-mcp` (global install via npm) |
| Swift Binary | Peekaboo native binary (path from `npm root -g`) |
| Version | 2.0.3 |
| Screen Recording | Granted |
| Accessibility | Granted |
| Monitors detected | 2 |

MCP tools aktiv: **`image`**, **`list`**

> **`analyze`** braucht `PEEKABOO_AI_PROVIDERS` — nicht konfiguriert, nicht nutzen. Analyse macht das Modell selbst via native Vision.

---

## MCP Tools

### `image` — Screenshot aufnehmen

```json
{ "app_target": "Safari" }
{ "app_target": "screen:0" }
{ "app_target": "frontmost" }
{ "app_target": "Safari", "window_title": "Gmail", "path": "/tmp/shot.png" }
{ "app_target": "screen", "format": "data" }
```

**`app_target` Werte:**
- `"appname"` — Fenster einer App (Name oder Bundle-ID)
- `"screen:0"` / `"screen:1"` — Einzelner Monitor (0-indexiert)
- `"screen"` — Alle Monitore
- `"frontmost"` — Aktives Fenster
- `"PID:12345"` — Prozess-ID

**`format` Werte:**
- `"png"` (default) — speichert Datei, gibt Pfad zurück
- **`"data"`** — liefert Base64 direkt im MCP Response → das Modell sieht das Bild inline ← bevorzugen für App/Fenster-Captures

> **CRITICAL: `format: "data"` funktioniert NICHT für Screen-Captures** (`screen`, `screen:0`, `screen:1`).
> Bei Screen-Captures zu gross → JavaScript Stack Overflow → automatischer Fallback zu PNG-Datei.
> Für Screen-Captures immer `path` setzen: `{ "app_target": "screen:0", "path": "/tmp/screen.png" }`

**`capture_focus`:**
- `"auto"` (default) — bringt Fenster nach vorne wenn nötig
- `"background"` — Screenshot ohne Fokuswechsel
- `"foreground"` — immer nach vorne

> **Kein `question`-Parameter verwenden.** Ruft Peekaboos eigene KI auf (PEEKABOO_AI_PROVIDERS nicht konfiguriert → Fehler). Stattdessen: `format: "data"` → Bild inline → das konfigurierte Modell analysiert selbst.

---

### `list` — Apps und Fenster aufzählen

```json
{ "item_type": "running_applications" }
{ "item_type": "application_windows", "app": "Safari" }
{ "item_type": "application_windows", "app": "Safari", "include_window_details": ["ids", "bounds"] }
{ "item_type": "server_status" }
```

**`include_window_details`** (Array, nur bei `application_windows`):
- `"bounds"` — Fensterposition und Größe: `{ "x": 449, "y": -1415, "width": 533, "height": 1407 }` (globale Bildschirmkoordinaten in Punkten)
- `"ids"` — Window-ID (für gezieltes Targeting)
- `"off_screen"` — ob Fenster gerade ausserhalb des sichtbaren Bereichs ist

**`item_type` optional** — wird automatisch inferiert: wenn `app` angegeben → `application_windows`; sonst → `running_applications`.

**Immer zuerst `list` aufrufen** bevor ein App-Screenshot gemacht wird — prüfen ob die App läuft und wie die Fenster heißen.

---

### `analyze` — NICHT verwenden (ohne Provider-Config)

`analyze` ruft Peekaboos eigene KI auf. `PEEKABOO_AI_PROVIDERS` ist nicht konfiguriert → Tool schlägt fehl.

**Stattdessen:** `screencapture -x /tmp/s.png` + `Read`-Tool → schnellster Weg. Oder Peekaboo `image` + `format: "data"` für App-spezifische Captures.

---

## Accessibility API — UI ohne Screenshot lesen (~50ms)

macOS Accessibility API gibt den kompletten UI-Baum jeder App als strukturierten Text. Kein Screenshot, kein Bild, kein MCP. Direkt via osascript oder Python.

### Wer ist frontmost / was läuft?

```bash
osascript -e 'tell application "System Events" to name of first application process whose frontmost is true'
```

### Fenster-Titel einer App

```bash
osascript -e 'tell application "System Events" to tell process "Safari" to get name of every window'
```

### Buttons, Felder, Zustand lesen

```bash
# Alle Buttons in Fenster 1
osascript -e 'tell application "System Events" to tell process "AppName" to get name of every button of window 1'

# Text-Feld-Wert (z.B. Suchfeld)
osascript -e 'tell application "System Events" to tell process "AppName" to get value of text field 1 of window 1'

# Alle Text-Felder + Werte
osascript -e 'tell application "System Events" to tell process "AppName" to get value of every text field of window 1'

# Checkbox-Status
osascript -e 'tell application "System Events" to tell process "AppName" to get value of checkbox 1 of window 1'

# Popup-Button / Dropdown aktueller Wert
osascript -e 'tell application "System Events" to tell process "AppName" to get value of pop up button 1 of window 1'

# Element existiert?
osascript -e 'tell application "System Events" to tell process "AppName" to exists button "OK" of window 1'
```

### Vollständiger UI-Baum dumpen

```bash
# Gesamter Inhalt von Fenster 1 (rekursiv alle Elemente)
osascript -e 'tell application "System Events" to tell process "AppName" to get entire contents of window 1'
```

Oder via Python für strukturiertere Ausgabe:

```python
import subprocess, sys

def dump_ui(app_name, max_chars=3000):
    script = f'''
tell application "System Events"
    tell process "{app_name}"
        set out to ""
        try
            set elems to entire contents of window 1
            repeat with e in elems
                try
                    set r to role of e
                    set t to ""
                    try
                        set t to title of e
                    end try
                    set v to ""
                    try
                        set v to value of e
                    end try
                    set out to out & r & ": " & t & " | " & v & "\\n"
                end try
            end repeat
        end try
        return out
    end tell
end tell
'''
    r = subprocess.run(['osascript', '-e', script], capture_output=True, text=True, timeout=10)
    return r.stdout[:max_chars]

print(dump_ui("Safari"))
```

```bash
/opt/homebrew/bin/python3 -c "
import subprocess
script = '''tell application \"System Events\" to tell process \"Safari\" to get entire contents of window 1'''
r = subprocess.run(['osascript','-e',script], capture_output=True, text=True)
print(r.stdout[:2000])
"
```

### App-spezifische Shortcuts

```bash
# Safari: aktuelle URL
osascript -e 'tell application "Safari" to get URL of current tab of window 1'

# Safari: Seitentitel
osascript -e 'tell application "Safari" to get name of current tab of window 1'

# Safari: alle offenen Tabs
osascript -e 'tell application "Safari" to get {URL, name} of every tab of window 1'

# Finder: aktueller Ordner
osascript -e 'tell application "Finder" to get POSIX path of (target of front window as alias)'

# Finder: selektierte Dateien
osascript -e 'tell application "Finder" to get POSIX path of (selection as alias)'

# Terminal: aktuelles Verzeichnis des frontmost Tabs
osascript -e 'tell application "Terminal" to get custom title of selected tab of window 1'

# Mail: selektierte Nachricht
osascript -e 'tell application "Mail" to get subject of first message of selection'

# System Settings: aktuelle Seite
osascript -e 'tell application "System Events" to tell process "System Preferences" to get name of current pane'
```

### UI-Element per Accessibility klicken (ohne Koordinaten)

```bash
# Button per Name klicken — zuverlässiger als Koordinaten
osascript -e 'tell application "System Events" to tell process "AppName" to click button "OK" of window 1'

# Menü-Item — immer per Name, nie per Koordinate
osascript -e 'tell application "System Events" to tell process "Safari" to click menu item "Neues Fenster" of menu "Ablage" of menu bar 1'

# Text-Feld fokussieren + Inhalt setzen
osascript -e 'tell application "System Events" to tell process "AppName"
    set focused of text field 1 of window 1 to true
    set value of text field 1 of window 1 to "neuer Text"
end tell'

# Checkbox toggling
osascript -e 'tell application "System Events" to tell process "AppName" to click checkbox 1 of window 1'

# Dropdown-Wert setzen
osascript -e 'tell application "System Events" to tell process "AppName"
    click pop up button 1 of window 1
    click menu item "Option B" of menu 1 of pop up button 1 of window 1
end tell'
```

### AX-Rollen (UI-Element-Typen)

| Rolle | Bedeutung |
|-------|-----------|
| `AXWindow` | Fenster |
| `AXButton` | Button |
| `AXTextField` | Einzeiliges Textfeld |
| `AXTextArea` | Mehrzeiliges Textfeld |
| `AXStaticText` | Label / nicht-editierbarer Text |
| `AXCheckBox` | Checkbox |
| `AXRadioButton` | Radio-Button |
| `AXPopUpButton` | Dropdown |
| `AXComboBox` | Combo-Box |
| `AXSlider` | Slider |
| `AXTable` | Tabelle |
| `AXRow` | Tabellenzeile |
| `AXScrollArea` | Scrollbarer Bereich |
| `AXToolbar` | Toolbar |
| `AXMenuBar` | Menüleiste |
| `AXMenuItem` | Menüpunkt |
| `AXImage` | Bild (kein Text auslesbar) |
| `AXGroup` | Container/Gruppe |

---

## Workflow-Pattern: Aufgaben automatisieren

### Accessibility-First (schnellstes Pattern — kein Screenshot)

```
1. osascript: get name of every button of window 1   → UI-Zustand lesen (~50ms)
2. [Modell entscheidet welcher Button/Feld]
3. osascript: click button "OK" of window 1           → direkt per Name, keine Koordinaten
4. osascript: get value of text field 1 of window 1  → Ergebnis verifizieren (~50ms)
```

Gesamtzeit: ~150ms. Kein Bild, kein Capture.

### Native Vision Fast Path (wenn visuelle Inhalte nötig)

```
1. screencapture -x /tmp/s.png                  → Screenshot (~250ms, kein MCP)
2. Read /tmp/s.png                               → Modell sieht Bild direkt (base64 inline)
3. [Modell analysiert UI, nennt Koordinaten]
4. osascript: click at {x, y}                   → click/type/hotkey
5. screencapture -x /tmp/s.png → Read           → Ergebnis verifizieren
6. rm /tmp/s.png                                 → Cleanup
```

### App-Fenster spezifisch (Peekaboo image — Hintergrund oder gezieltes Fenster)

```
1. list  item_type="running_applications"        → prüfen ob App läuft
2. image app_target="AppName" format="data"      → Fenster-Screenshot inline (~500ms)
3. [Modell analysiert UI]                        → Koordinaten ermitteln
4. osascript: click at {abs_x, abs_y}            → Aktion ausführen
5. image app_target="AppName" format="data"      → Ergebnis verifizieren
```

### Koordinaten: Screenshot → absolut → osascript

**Bei `screencapture` (Vollbild):** Koordinaten aus dem Bild sind direkt absolute Bildschirmkoordinaten — keine Umrechnung nötig.

**Bei Peekaboo `image` (App-Fenster):** Screenshots sind fenster-relativ (0,0 = obere linke Ecke des Fensters). Umrechnung:

```
abs_x = bounds.x + screenshot_rel_x
abs_y = bounds.y + screenshot_rel_y
```

Workflow:
```
1. list  app="Safari"  include_window_details=["bounds"]
   → bounds: { x: 200, y: 100, width: 1200, height: 800 }

2. image  app_target="Safari"  format="data"
   → Modell: "OK-Button ist bei (950, 650) im Screenshot"

3. abs_x = 200 + 950 = 1150
   abs_y = 100 + 650 = 750

4. osascript -e 'tell app "System Events" to click at {1150, 750}'
```

**Retina (dieser Mac):** Beide Tools liefern logische Punkte. Keine Skalierung nötig — 1:1 für osascript.

**Negative y-Koordinaten** sind normal bei Monitoren über dem Hauptmonitor.

---

## Wichtige Regeln

- **Accessibility zuerst** — UI-State lesen via osascript, kein Screenshot wenn vermeidbar
- **Screenshot ist letztes Mittel** — nur wenn visuelle/custom-gerenderte Inhalte nötig
- **Browser immer Playwright** — DOM-basiert, kein Bild, viel schneller
- **`list` vor Peekaboo image** — App-Status + Bounds holen
- **`capture_focus: "background"`** wenn kein Fokuswechsel stören soll
- **Vision abhängig vom Modell** — Bild- und Videoanalyse nur verwenden, wenn die konfigurierte Qwen-Code-Modellroute sie unterstützt
- **PPTX/DOCX nicht per computer-use öffnen** — Office-Skills nutzen

---

## Grenzen

| Feature | Status |
|---------|--------|
| UI-Text/Buttons/Felder lesen | ✅ osascript Accessibility (~50ms) |
| Browser automatisieren | ✅ Playwright (kein Screenshot) |
| Vollbild-Screenshot | ✅ `screencapture` + Read (~250ms) |
| App-Fenster-Screenshot | ✅ Peekaboo `image` (~500ms) |
| App/Fenster-Liste + Bounds | ✅ Peekaboo `list` |
| Per Name klicken | ✅ osascript `click button "OK"` |
| Per Koordinate klicken | ✅ osascript `click at {x, y}` |
| Tippen / Tastatur | ✅ osascript `keystroke` |
| Bilder/Charts lesen | ✅ screencapture + Read (Vision) |
| Custom-gerenderte UI | ✅ screencapture + Read (Vision) |
| Video aufnehmen + analysieren | ✅ `screencapture -v -V <sec>` + Read (.mov) |
| Audio aufnehmen (mit Video) | ✅ `screencapture -v -g` (Mikrofon, nur als Teil von Video) |
| Audio standalone | ❌ Model versteht kein Audio-only |

---

## osascript — Aktionen ausführen

```bash
# Absolut klicken (globale Koordinaten)
osascript -e 'tell application "System Events" to click at {1150, 750}'

# App aktivieren (in Vordergrund bringen)
osascript -e 'tell application "Safari" to activate'

# Menüpunkt klicken (zuverlässiger als Koordinaten bei Menüs)
osascript -e 'tell application "System Events" to tell process "Safari" to click menu item "Neues Fenster" of menu "Ablage" of menu bar 1'

# Tastenkürzel
osascript -e 'tell application "System Events" to keystroke "s" using {command down}'
osascript -e 'tell application "System Events" to key code 36'  # Return/Enter

# Text eingeben (fokussiertes Feld)
osascript -e 'tell application "System Events" to keystroke "Hallo Welt"'

# Doppelklick
osascript -e 'tell application "System Events" to double click at {500, 300}'

# Rechtsklick
osascript -e 'tell application "System Events" to right click at {500, 300}'

# Scroll
osascript -e 'tell application "System Events" to scroll down by 5'
```

**Key Codes nützlich:** 36=Return, 51=Delete, 53=Escape, 48=Tab, 49=Space, 123-126=Pfeiltasten

---

## Schnellreferenz

| Ziel | Methode | Speed |
|------|---------|-------|
| **UI-Zustand lesen (Buttons/Felder)** | `osascript: get value/name of...` | ~50ms |
| **Button per Name klicken** | `osascript: click button "OK" of window 1` | ~30ms |
| **Safari URL lesen** | `osascript: tell application "Safari" to get URL of current tab of window 1` | ~50ms |
| **UI-Baum einer App** | `osascript: get entire contents of window 1` | ~100ms |
| **Browser (alles)** | Playwright snapshot + actions | ~100ms |
| **Vollbild sehen** | `screencapture -x /tmp/s.png` → `Read /tmp/s.png` | ~250ms |
| **Monitor 1 sehen** | `screencapture -x -D 1 /tmp/s.png` → `Read` | ~250ms |
| **Fenster per ID** | `screencapture -x -l <windowID> /tmp/w.png` → `Read` (windowID aus Peekaboo list) | ~250ms |
| App-Fenster (Hintergrund) | Peekaboo `image` → `capture_focus: "background"` | ~500ms |
| Apps auflisten | Peekaboo `list` → `item_type: "running_applications"` | ~100ms |
| Fenster + Bounds | Peekaboo `list` → `app: "Safari", include_window_details: ["bounds"]` | ~100ms |
| Koordinaten-Klick | `osascript -e 'tell app "System Events" to click at {x, y}'` | ~30ms |
| Tastenkürzel | `osascript -e 'tell app "System Events" to keystroke "s" using {command down}'` | ~30ms |
| **Video aufnehmen (5s)** | `screencapture -x -v -V 5 /tmp/r.mov` → `Read /tmp/r.mov` | ~5s+ |
| **Video + Audio** | `screencapture -x -v -V 5 -g /tmp/r.mov` → `Read` | ~5s+ |
| Permissions prüfen | Peekaboo `list` → `item_type: "server_status"` | - |
| `analyze`-Tool | NICHT verwenden - kein AI-Provider konfiguriert | - |
