[日本語版 README (原文 | Original)](./README-ja.md)

This file is translated by ChatGPT based on the original text.

# js-i18n.nvim

js-i18n.nvim is a Neovim plugin for the JavaScript library i18next.

> [!WARNING]
> This plugin is still under development and is optimized for the developer's use cases.

## Requirements

- Neovim 0.10.0 or higher (not tested with versions below 0.10.0)
- [jq](https://stedolan.github.io/jq/)
  Used for editing translation texts.

## Installation

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

## Features

- [x] Display translations as virtual text
  - [x] (Experimental) Hide keys and display only translations
- [x] Edit translations
- [x] Support for monorepos
- LSP Support
  - [x] Jump to definition of translation resources
  - [x] Key completion
  - [x] Display translations for each language on hover
- Library Support
  - [x] i18next
  - [x] react-i18next
- Translation resource formats
  - [x] JSON
  - [ ] YAML

Advanced usage of i18next and react-i18next is not yet supported.

## Usage

### Commands

- `:I18nSetLang [lang]`

  Sets the language. The set language is used for virtual text display and definition jumps.

- `:I18nVirtualTextEnable`

  Enables the display of virtual text.

- `:I18nVirtualTextDisable`

  Disables the display of virtual text.

- `:I18nVirtualTextToggle`

  Toggles the display of virtual text.

- `:I18nEditTranslation [lang]`

  Edits the translation at the cursor position. If there is no matching translation for the key, a new translation is added.  
  If `lang` is omitted, the currently displayed language is used.

## Configuration

The default settings are as follows. For omitted parts, refer to [config.lua](./lua/js-i18n/config.lua).

```lua
{
  primary_language = {}, -- The default language to display (initial setting for displaying virtual text, etc.)
  translation_source = { "**/locales/*/translation.json" }, -- Pattern for translation resources
  detect_language = ..., -- Function to detect the language.
  key_separator = ".", -- Key separator
  virt_text = {
    enabled = true, -- Enable virtual text display
    conceal_key = false, -- Hide keys and display only translations
    fallback = false, -- Fallback if the selected virtual text cannot be displayed
    max_length = 0, -- Maximum length of virtual text. 0 means unlimited.
    max_width = 0, -- Maximum width of virtual text. 0 means unlimited. (`max_length` takes precedence.)
  },
}
```
