<div align="center">
    <a href="./README.md">English</a> | <b>日本語(原文|Orginal)</b>
</div>

# 🌐 js-i18n.nvim

[![GitHub Release](https://img.shields.io/github/release/nabekou29/js-i18n.nvim?style=flat)](https://github.com/nabekou29/js-i18n.nvim/releases/latest)
[![tests](https://github.com/nabekou29/js-i18n.nvim/actions/workflows/test.yaml/badge.svg)](https://github.com/nabekou29/js-i18n.nvim/actions/workflows/test.yaml)

js-i18n.nvim は、JavaScript のライブラリである i18next のための Neovim プラグインです。

<div>
  <video src="https://github.com/user-attachments/assets/abcd728d-42d1-46d2-8d18-072102b1cf71" type="video/mp4" />
</div>

## ✨ 機能

- 翻訳をバーチャルテキストとして表示
- 翻訳の編集
- 翻訳が不足している場合のエラー表示
- 定義ジャンプ
- ホバーによる翻訳の表示
- キーの補完
- モノレポ のサポート

## 🚧 ステータス

> [!WARNING]
> このプラグインはまだ開発中であり、開発者の利用ケースに最適化しています。

## ✅ 必須条件

- Neovim 0.10.0 以上 (0.10.0 未満では動作確認していません)
- [jq](https://stedolan.github.io/jq/)
  翻訳文言の編集に使用します。

## 📦 インストール

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

## ⚙️ 設定

---

## 機能

- [x] 翻訳をバーチャルテキストとして表示
  - [x] (実験的) キーを隠して翻訳のみを表示する
- [x] 翻訳の編集
- [x] モノレポ のサポート
- LSP のサポート
  - [x] 翻訳リソースへの定義ジャンプ
  - [x] キーの補完
  - [x] ホバーによる各言語の翻訳の表示
  - [x] キーに対応する翻訳が見つからない場合にエラーを表示
- ライブラリのサポート
  - [x] i18next
  - [x] react-i18next
- 翻訳リソースの形式
  - [x] JSON
  - [ ] YAML

i18next, react-i18next の高度な利用については、まだサポートしていません。

## 使い方

### コマンド

- `:I18nSetLang [lang]`

  言語を設定します。設定された言語はバーチャルテキストの表示や定義ジャンプに使用されます。

- `:I18nEditTranslation [lang]`

  カーソルがある位置の翻訳を編集します。キーにマッチする翻訳がない場合は、新しい翻訳を追加します。  
  `lang` を省略した場合は、現在表示されている言語を使用します。

- `:I18nVirtualTextEnable`

  バーチャルテキストの表示を有効にします。

- `:I18nVirtualTextDisable`

  バーチャルテキストの表示を無効にします。

- `:I18nVirtualTextToggle`

  バーチャルテキストの表示を切り替えます。

- `:I18nDiagnosticEnable`

  診断情報の表示を有効にします。

- `:I18nDiagnosticDisable`

  診断情報の表示を無効にします。

- `:I18nDiagnosticToggle`

  診断情報の表示を切り替えます。

## ⚙️ 設定

デフォルトの設定は以下の通りです。
省略されている箇所については、[config.lua](./lua/js-i18n/config.lua) を参照してください。

```lua
{
  primary_language = {}, -- 優先表示する言語（バーチャルテキストなどの表示に使用する言語の初期設定）
  translation_source = { "**/locales/*/translation.json" }, -- 翻訳リソースのパターン
  detect_language = ..., -- 言語を検出する関数。
  key_separator = ".", -- キーのセパレータ
  virt_text = {
    enabled = true, -- バーチャルテキストの表示を有効にする
    format = ..., -- バーチャルテキストのフォーマット関数
    conceal_key = false, -- キーを隠して翻訳のみを表示する
    fallback = false, -- 選択中のバーチャルテキストが表示できない場合に
    max_length = 0, -- バーチャルテキストの最大長。0の場合は無制限。
    max_width = 0, -- バーチャルテキストの最大幅。0の場合は無制限。(`max_length` が優先されます。)
  },
    diagnostic = {
    enabled = true, -- 診断情報の表示を有効にする
    severity = vim.diagnostic.severity.WARN, -- 診断情報の重要度
  },
}
```
