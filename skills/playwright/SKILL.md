---
name: playwright
description: "Use this skill whenever a task requires browser automation: navigating websites, filling forms, clicking buttons, scraping content, reading console output or network traffic, automating login flows, or taking screenshots of web pages. Triggers: any URL, any mention of 'website', 'browser', 'click this button', 'fill out the form', 'log in to', 'scrape', 'download from web', 'check what the page shows'. Works with Chromium (default) and Edge (system-installed). Does NOT control native desktop apps - use computer-use skill for those."
license: MIT
---

# Playwright MCP - Browser Automation

## Setup

| Component | Detail |
|-----------|--------|
| MCP Server | `@playwright/mcp@latest` via npx |
| Config | `~/.qwen/settings.json` - trust: true, all tools enabled |
| Default Browser | Chromium (already installed, 528 MB cached) |
| Edge | `/Applications/Microsoft Edge.app` - system-installed, usable |
| Safari | Not supported by Playwright |
| Mode | Accessibility snapshot (ARIA tree) - no screenshots needed for interaction |

---

## Core Concept: Snapshots, not Screenshots

Playwright MCP uses the **accessibility tree** (ARIA), not pixel coordinates. Workflow:

1. `browser_navigate` - go to URL
2. `browser_snapshot` - get ARIA tree (text representation of all interactive elements)
3. Read snapshot - find element by label, role, or ref ID
4. Act on element using ref ID from snapshot
5. `browser_snapshot` again to verify result

No coordinate math needed. Elements are referenced by their semantic identity.

---

## Tool Reference

### Navigation

```
browser_navigate(url)                       # navigate to URL
browser_navigate_back()                     # browser back
browser_navigate_forward()                  # browser forward
```

### Reading Page State

```
browser_snapshot()                          # ARIA accessibility tree - always call first
browser_screenshot()                        # pixel screenshot (PNG, for visual confirmation)
browser_console_messages()                  # JS console output
browser_network_requests()                  # HTTP requests made by the page
```

### Interaction (requires ref from browser_snapshot)

```
browser_click(element, ref)                 # click element
browser_type(element, ref, text)            # type into focused element
browser_fill(element, ref, value)           # fill input field (clears first)
browser_select_option(element, ref, values) # dropdown selection
browser_check(element, ref)                 # check checkbox
browser_uncheck(element, ref)              # uncheck checkbox
browser_hover(element, ref)                 # hover over element
browser_press_key(key)                      # keyboard: "Enter", "Tab", "Escape", "ArrowDown"
browser_drag(startElement, startRef, endElement, endRef)  # drag and drop
browser_file_upload(paths)                  # upload file(s)
```

### Waiting

```
browser_wait_for(time?, text?, textGone?, url?)   # wait for condition
  # time: milliseconds to wait
  # text: wait until this text appears on page
  # textGone: wait until this text disappears
  # url: wait until URL matches
```

### Tabs

```
browser_tab_list()                          # list all open tabs
browser_tab_new(url?)                       # open new tab (optionally navigate)
browser_tab_select(index)                   # switch to tab by index
browser_tab_close(index?)                   # close tab (current if no index)
```

### JavaScript

```
browser_evaluate(function)                  # run arbitrary JS in page context
  # Example: "() => document.title"
  # Example: "() => window.localStorage.getItem('token')"
```

### Utilities

```
browser_resize(width, height)               # resize browser window
browser_pdf_save(filename)                  # save current page as PDF
browser_install(browser?)                   # install browser (chromium/firefox/webkit/msedge)
browser_close()                             # close browser
```

---

## Standard Workflow

```
1. browser_navigate("https://example.com")
2. browser_snapshot()                        <- read ARIA tree, find element refs
3. browser_click(element="Login", ref="...")  <- use ref from snapshot
4. browser_fill(element="Email", ref="...", value="user@example.com")
5. browser_fill(element="Password", ref="...", value="secret")
6. browser_press_key("Enter")
7. browser_wait_for(text="Dashboard")        <- confirm success
8. browser_snapshot()                        <- verify new state
```

---

## Reading Snapshot Output

`browser_snapshot` returns an ARIA tree. Example output:
```
- document
  - main
    - form
      - textbox "Email address" [ref=e1]
      - textbox "Password" [ref=e2]
      - button "Sign in" [ref=e3]
      - link "Forgot password?" [ref=e4]
```

Use the `ref` value in subsequent action calls. The `element` parameter is the human-readable label (for logging), `ref` is what Playwright uses to find the element.

---

## Using Edge Instead of Chromium

Edge is system-installed. To use it, pass the browser argument when starting:

```json
// In settings.json args (if you want Edge as default):
"args": ["@playwright/mcp@latest", "--browser", "msedge"]
```

Or dynamically: call `browser_install(browser="msedge")` to prepare, then the MCP server picks it up.

For one-off Edge use: the default Chromium works for almost all sites. Only switch to Edge if the site explicitly requires it (e.g., O365 with Conditional Access).

---

## Common Patterns

### Scrape content

```
browser_navigate("https://example.com/data")
browser_snapshot()           # read all text content from ARIA tree
# Or for raw HTML:
browser_evaluate("() => document.body.innerText")
```

### Login flow

```
browser_navigate("https://app.example.com/login")
browser_snapshot()           # find form refs
browser_fill(element="Username", ref="...", value="user")
browser_fill(element="Password", ref="...", value="pass")
browser_click(element="Login button", ref="...")
browser_wait_for(url="https://app.example.com/dashboard")
```

### Read network traffic (API responses, auth tokens)

```
browser_navigate("https://app.example.com")
# trigger the action that makes API calls
browser_network_requests()   # see all requests + response headers
```

### Execute JS (read localStorage, cookies, DOM state)

```
browser_evaluate("() => JSON.parse(localStorage.getItem('session'))")
browser_evaluate("() => document.cookie")
browser_evaluate("() => [...document.querySelectorAll('h2')].map(h=>h.textContent)")
```

### Multi-tab

```
browser_tab_new("https://site-b.com")   # open second tab
browser_tab_list()                       # see all tabs with indices
browser_tab_select(0)                    # switch back to first tab
```

---

## Playwright vs Peekaboo

| Task | Use |
|------|-----|
| Interact with a website | **Playwright** |
| Scrape web content | **Playwright** |
| Read browser console / network | **Playwright** |
| Control Finder, Mail, TextEdit | **Peekaboo + osascript** |
| Read screen of any desktop app | **Peekaboo** |
| Verify visual output in browser | Both (Playwright screenshot or Peekaboo) |

---

## Limitations

| Feature | Status |
|---------|--------|
| Chromium | Installed, ready |
| Edge | System-installed, usable via channel |
| Firefox | Not installed (run `browser_install(browser="firefox")` if needed) |
| Safari / WebKit | Limited macOS support only via WebKit engine |
| File downloads | Possible but path handling needs care |
| Browser extensions | Not supported in automation mode |
| Captcha solving | Not supported |
| Desktop apps (non-browser) | Use computer-use skill instead |
