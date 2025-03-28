<div align="center">
  <b>English</b> | <a href="./README-ja.md">日本語(原文|Original)</a>
</div>

<br />

_⚠︎ This file is translated and updated by ChatGPT based on the original text._

<br />

# 🌐 js-i18n.nvim

[![GitHub Release](https://img.shields.io/github/release/nabekou29/js-i18n.nvim?style=flat)](https://github.com/nabekou29/js-i18n.nvim/releases/latest)
[![tests](https://github.com/nabekou29/js-i18n.nvim/actions/workflows/test.yaml/badge.svg)](https://github.com/nabekou29/js-i18n.nvim/actions/workflows/test.yaml)

js-i18n.nvim is a Neovim plugin that supports JavaScript i18n libraries.

<div>
  <video src="https://github.com/user-attachments/assets/abcd728d-42d1-46d2-8d18-072102b1cf71" type="video/mp4" />
</div>

## 🚧 Status

> [!WARNING]
> This plugin is still under development and is optimized for the developer's use cases.

## ✨ Features

- Display translations as virtual text
- Edit translations (via command or code action)
- Show error when a translation for the key is not found
- Jump to definition of translation resources
- Display translations for each language on hover
- Key completion
- Support for monorepos
- Support for multiple libraries (i18next, react-i18next, next-intl)

### Supported Libraries

#### [i18next](https://www.i18next.com/), [react-i18next](https://react.i18next.com/)

![i18next-screenshot](https://github.com/user-attachments/assets/349f5242-f717-4af9-9790-623ddad0492f)

#### [next-intl](https://next-intl-docs.vercel.app/)

![next-intl-screenshot](https://github.com/user-attachments/assets/e6873336-5161-40b1-9bcc-c845ca750860)

## ✅ Requirements

- Neovim 0.10.0 or higher (not tested with versions below 0.10.0)
- [jq](https://stedolan.github.io/jq/)
  Used for editing translation texts.

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "nabekou29/js-i18n.nvim",
  dependencies = {
    "neovim/nvim-lspconfig",
    "nvim-treesitter/nvim-treesitter",
    "nvim-lua/plenary.nvim",
  },
  event = { "BufReadPre", "BufNewFile" },
  opts = {}
}
```

## 📚 Usage

### Commands

- `:I18nSetLang [lang]` - Sets the language. The set language is used for virtual text display and definition jumps.

- `:I18nEditTranslation [lang]` - Edits the translation at the cursor position. If there is no matching translation for the key, a new translation is added.  
  If `lang` is omitted, the currently displayed language is used.

- `:I18nVirtualTextEnable` - Enables the display of virtual text.

- `:I18nVirtualTextDisable` - Disables the display of virtual text.

- `:I18nVirtualTextToggle` - Toggles the display of virtual text.

- `:I18nDiagnosticEnable` - Enables the display of diagnostic information.

- `:I18nDiagnosticDisable` - Disables the display of diagnostic information.

- `:I18nDiagnosticToggle` - Toggles the display of diagnostic information.

## ⚙️ Configuration

The default settings are as follows. For omitted parts, refer to [config.lua](./lua/js-i18n/config.lua).

```lua
{
  primary_language = {}, -- The default language to display (initial setting for displaying virtual text, etc.)
  translation_source = { "**/{locales,messages}/*.json" }, -- Pattern for translation resources
  respect_gitignore = true, -- Whether to respect .gitignore when retrieving translation resources and implementation files. Setting to false may improve performance.
  detect_language = ..., -- Function to detect the language. By default, a function that detects the language heuristically from the file name is used.
  key_separator = ".", -- Key separator
  virt_text = {
    enabled = true, -- Enable virtual text display
    format = ..., -- Format function for virtual text
    conceal_key = false, -- Hide keys and display only translations
    fallback = false, -- Fallback if the selected virtual text cannot be displayed
    max_length = 0, -- Maximum length of virtual text. 0 means unlimited.
    max_width = 0, -- Maximum width of virtual text. 0 means unlimited. (`max_length` takes precedence.)
  },
  diagnostic = {
    enabled = true, -- Enable the display of diagnostic information
    severity = vim.diagnostic.severity.WARN, -- Severity level of diagnostic information
  },
}
```

## ⬆️ Roadmap

- Enhanced support for libraries
  - Namespace support
- Extract the Language Server implementation into a separate project
