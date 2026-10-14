# EllesmereUI-Reputation_Bar_Advanced_Text_Format

<img width="1395" height="1137" alt="{FB0F188C-088F-4A1E-9B04-34B1B8837651}" src="https://github.com/user-attachments/assets/1ba97e74-211b-4d99-9f2c-c287df57d2bd" />

A small add-on for **EllesmereUI** that adds a **Text Format** option to the Action Bars reputation bar. By default EllesmereUI only shows a percentage for your tracked faction. With this add-on the bar can show your current and maximum reputation, how much is left until the bar is full, or all of these at once.

```
Kirin Tor: 1400 / 12000 (10600 left) 11.7% [Friendly]
```

The add-on is **standalone**. It does not modify any EllesmereUI file, so it keeps working after you update EllesmereUI.

## Features

- Five text formats for the reputation bar:

  | Format | Example |
  | --- | --- |
  | Percent (default) | `Kirin Tor: 12% [Friendly]` |
  | Current / Max | `Kirin Tor: 1400 / 12000 [Friendly]` |
  | Remaining | `Kirin Tor: 10600 left [Friendly]` |
  | Current / Max % | `Kirin Tor: 1400 / 12000  11.7% [Friendly]` |
  | Current / Max (Left) % | `Kirin Tor: 1400 / 12000 (10600 left) 11.7% [Friendly]` |

- A **Show Standing** toggle that adds or removes the `[Friendly]` part.
- If the text doesn't fit the bar, the add-on first drops the faction name and standing, then shows only the percentage.
- Works with paragon, renown and friendship factions, because it uses the values EllesmereUI has already calculated for the bar.
- Settings are saved in your EllesmereUI profile, so they follow profile switches, imports and exports.
- The options appear in the normal EllesmereUI settings window, and the settings search finds them.

## Requirements

- **EllesmereUI** with the **EllesmereUI Action Bars** module enabled
- EllesmereUI's own reputation bar, which means **Use Blizzard's Rep Bars** must be turned off

Tested on WoW Forever (Interface 16001) with EllesmereUI v9.5.4. The `.toc` also lists the retail interface versions that EllesmereUI supports.

## Installation

1. Download this repository, or the latest release zip.
2. Copy the `EllesmereUI_RepText` folder into your AddOns folder, for example:
   ```
   World of Warcraft\_classic_beta_\Interface\AddOns\EllesmereUI_RepText
   ```
   The folder must contain `EllesmereUI_RepText.toc` directly inside it, not in a nested subfolder.
3. Restart the game or type `/reload`.
4. Check that **EllesmereUI Rep Text** is enabled in the AddOns list on the character screen.

## Usage

Open the EllesmereUI settings and go to **Action Bars → Menu, Bags & Rep Bars**. Under the **Reputation Bar** section you'll find a new row:

- **Text Format:** pick one of the five formats.
- **Show Standing:** show or hide the `[Standing]` suffix.

Changes apply right away. You don't need to reload.

### Slash commands

You can also change the settings without opening the settings window:

| Command | Effect |
| --- | --- |
| `/reptext pct` | Percent |
| `/reptext curmax` | Current / Max |
| `/reptext remaining` | Remaining |
| `/reptext curmaxpct` | Current / Max % |
| `/reptext full` | Current / Max (Left) % |
| `/reptext standing` | Toggle Show Standing |
| `/reptext` | Show the current settings and the list of commands |

## How it works

The add-on doesn't patch EllesmereUI. It attaches at runtime instead:

- **Bar text:** when EllesmereUI updates the reputation bar, it stores the resolved values (current, maximum and standing) on the bar frame and then sets the text. The add-on hooks the bar's `SetText` and rewrites the text in the format you chose. When the format is *Percent* with standing shown, it leaves EllesmereUI's original text untouched.
- **Options:** EllesmereUI's settings load on demand. Once they load, the add-on wraps the builder for the *Menu, Bags & Rep Bars* page and inserts its row below the Reputation Bar section. If a future EllesmereUI version reorganises that page, the row goes to the bottom of the page under its own **REPUTATION TEXT** header. The `/reptext` command always works either way.

The settings are stored as `repTextFormat` and `repShowStanding` in EllesmereUI's reputation bar profile settings.

## Compatibility notes

- If **Use Blizzard's Rep Bars** is on, the options are greyed out, because EllesmereUI doesn't build its own bar in that case.
- A future EllesmereUI update can only break the add-on if it renames the internal reputation bar fields that the add-on hooks into. If that happens, please open an issue and include the EllesmereUI version.

## Files

```
EllesmereUI_RepText/
├── EllesmereUI_RepText.toc   add-on manifest
├── RepText.lua               bar text hook and /reptext
└── RepText_Options.lua       settings row in the EllesmereUI options window
```

## Credits

- EllesmereUI by Ellesmere. This add-on is an unofficial extension and is not affiliated with EllesmereUI.
