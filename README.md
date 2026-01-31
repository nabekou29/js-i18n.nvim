<div align="center">
  <b>English</b> | <a href="./README-ja.md">日本語(原文|Original)</a>
</div>

<br />

# 🌐 js-i18n.nvim

[![GitHub Release](https://img.shields.io/github/release/nabekou29/js-i18n.nvim?style=flat)](https://github.com/nabekou29/js-i18n.nvim/releases/latest)
[![tests](https://github.com/nabekou29/js-i18n.nvim/actions/workflows/test.yaml/badge.svg)](https://github.com/nabekou29/js-i18n.nvim/actions/workflows/test.yaml)

js-i18n.nvim is a Neovim plugin powered by [js-i18n-language-server](https://github.com/nabekou29/js-i18n-language-server) that supports JavaScript/TypeScript i18n libraries.

<div>
  <video src="https://github.com/user-attachments/assets/abcd728d-42d1-46d2-8d18-072102b1cf71" type="video/mp4" />
</div>

## ✨ Features

- Display translations as virtual text
- Edit translations (via command or code action)
- Show error when a translation for the key is not found
- Detect unused translation keys
- Jump to definition of translation resources
- Display translations for each language on hover
- Key completion
- Find references
- Support for multiple libraries (i18next, react-i18next, next-intl)

### Supported Libraries

#### [i18next](https://www.i18next.com/), [react-i18next](https://react.i18next.com/)

![i18next-screenshot](https://github.com/user-attachments/assets/349f5242-f717-4af9-9790-623ddad0492f)

#### [next-intl](https://next-intl-docs.vercel.app/)

![next-intl-screenshot](https://github.com/user-attachments/assets/e6873336-5161-40b1-9bcc-c845ca750860)

## ✅ Requirements

- Neovim >= 0.11
- [js-i18n-language-server](https://github.com/nabekou29/js-i18n-language-server)

  ```sh
  npm install -g js-i18n-language-server
  ```

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "nabekou29/js-i18n.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {},
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

- `:I18nDeleteUnusedKeys` - Deletes unused translation keys from the current JSON file.

## ⚙️ Configuration

The default settings are as follows. For the complete list, refer to [config.lua](./lua/js-i18n/config.lua).

```lua
{
  -- Client-side (Neovim-specific) settings
  virt_text = {
    enabled = true,        -- Enable virtual text display
    format = ...,          -- Format function for virtual text
    conceal_key = false,   -- Hide keys and display only translations
    max_width = 0,         -- Maximum display width of virtual text. 0 means unlimited.
  },

  -- Server settings
  -- Can also be configured via .js-i18n.json file (which takes priority)
  server = {
    cmd = { "js-i18n-language-server", "--stdio" },  -- Server command
    translation_files = { file_pattern = "**/{locales,messages}/**/*.json" },
    key_separator = ".",
    namespace_separator = nil,
    default_namespace = nil,
    primary_languages = nil,
    required_languages = nil,
    optional_languages = nil,
    virtual_text = { max_length = 30 },
    diagnostics = { unused_keys = true },
  },
}
```

For server-side configuration details, see the [js-i18n-language-server configuration docs](https://github.com/nabekou29/js-i18n-language-server/blob/main/docs/configuration.md).

### Handling Flattened JSON

When using flattened JSON (e.g., `{ "some.deeply.nested.key": "value" }`), you can handle it by setting `key_separator` to a character that is not normally used.

```lua
{
  server = {
    key_separator = "?",  -- or "__no_separate__", or any character not included in your keys
  },
}
```

This will treat dot-separated keys as a single key instead of nested keys.

## ⬆️ Migration from v0.x

v1.0 has been rewritten to use the external [js-i18n-language-server](https://github.com/nabekou29/js-i18n-language-server).

### Key Changes

- **Dependencies**: `nvim-lspconfig`, `nvim-treesitter`, `plenary.nvim`, and `jq` are no longer required
- **Requirements**: `js-i18n-language-server` must be installed
- **Neovim version**: 0.11 or higher is required
- **Configuration**: Server-related settings have moved into the `server` table

Deprecated config keys are automatically converted and a warning is displayed.

```lua
-- v0.x
{
  primary_language = { "ja" },
  translation_source = { "**/locales/*.json" },
  key_separator = ".",
}

-- v1.0
{
  server = {
    primary_languages = { "ja" },
    translation_files = { file_pattern = "**/locales/*.json" },
    key_separator = ".",
  },
}
```
