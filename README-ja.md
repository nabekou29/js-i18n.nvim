# js-i18n.nvim

js-i18n.nvim は、JavaScript のライブラリである i18next のための Neovim プラグインです。

> [!WARNING]
> このプラグインはまだ開発中であり、開発者の利用ケースに最適化しています。

## インストール

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

## 機能

- [x] 翻訳をバーチャルテキストとして表示
  - [x] (実験的) キーを隠して翻訳のみを表示する
- [ ] 翻訳の編集
- [x] モノレポ のサポート
- LSP のサポート
  - [x] 翻訳リソースへの定義ジャンプ
  - [x] キーの補完
  - [x] ホバーによる各言語の翻訳の表示
- ライブラリのサポート
  - [x] i18next
  - [x] react-i18next
- 翻訳リソースの形式
  - [x] JSON
  - [ ] YAML

i18next, react-i18next の高度な利用については、まだサポートしていません。

## 使い方

### コマンド

- `:I18nSetLang {lang}`
  言語を設定します。設定された言語はバーチャルテキストの表示や定義ジャンプに使用されます。
- `:I18nVirtualTextEnable`
  バーチャルテキストの表示を有効にします。
- `:I18nVirtualTextDisable`
  バーチャルテキストの表示を無効にします。
- `:I18nVirtualTextToggle`
  バーチャルテキストの表示を切り替えます。

## 設定

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
    conceal_key = false, -- キーを隠して翻訳のみを表示する
    fallback = false, -- 選択中のバーチャルテキストが表示できない場合に
    max_length = 0, -- バーチャルテキストの最大長。0の場合は無制限。
  },
}
```
