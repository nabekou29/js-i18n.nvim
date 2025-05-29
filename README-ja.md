<div align="center">
    <a href="./README.md">English</a> | <b>日本語(原文|Original)</b>
</div>

# 🌐 js-i18n.nvim

[![GitHub Release](https://img.shields.io/github/release/nabekou29/js-i18n.nvim?style=flat)](https://github.com/nabekou29/js-i18n.nvim/releases/latest)
[![tests](https://github.com/nabekou29/js-i18n.nvim/actions/workflows/test.yaml/badge.svg)](https://github.com/nabekou29/js-i18n.nvim/actions/workflows/test.yaml)

js-i18n.nvim は、JavaScript の i18n ライブラリをサポートする Neovim プラグインです。

<div>
  <video src="https://github.com/user-attachments/assets/abcd728d-42d1-46d2-8d18-072102b1cf71" type="video/mp4" />
</div>

## 🚧 ステータス

> [!WARNING]
> このプラグインはまだ開発中であり、開発者の利用ケースに最適化しています。

## ✨ 機能

- 翻訳をバーチャルテキストとして表示
- 翻訳の編集 (コマンド or コードアクション)
- 翻訳が不足している場合のエラー表示
- 定義ジャンプ
- ホバーによる翻訳の表示
- キーの補完
- モノレポ のサポート
- いくつかのライブラリのサポート (i18next, react-i18next, next-intl)

### サポートしているライブラリ

#### [i18next](https://www.i18next.com/), [react-i18next](https://react.i18next.com/)

![i18next-screenshot](https://github.com/user-attachments/assets/349f5242-f717-4af9-9790-623ddad0492f)

#### [next-intl](https://next-intl-docs.vercel.app/)

![next-intl-screenshot](https://github.com/user-attachments/assets/e6873336-5161-40b1-9bcc-c845ca750860)

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

## 📚 使い方

### コマンド

- `:I18nSetLang [lang]` - 言語を設定します。設定された言語はバーチャルテキストの表示や定義ジャンプに使用されます。

- `:I18nEditTranslation [lang]` - カーソルがある位置の翻訳を編集します。キーにマッチする翻訳がない場合は、新しい翻訳を追加します。  
  `lang` を省略した場合は、現在表示されている言語を使用します。

- `:I18nVirtualTextEnable` - バーチャルテキストの表示を有効にします。

- `:I18nVirtualTextDisable` - バーチャルテキストの表示を無効にします。

- `:I18nVirtualTextToggle` - バーチャルテキストの表示を切り替えます。

- `:I18nDiagnosticEnable` - 診断情報の表示を有効にします。

- `:I18nDiagnosticDisable` - 診断情報の表示を無効にします。

- `:I18nDiagnosticToggle` - 診断情報の表示を切り替えます。

- `:I18nCopyKey` - JSON ファイルで実行することで、カーソルがある位置のキーをクリップボードにコピーします。

## ⚙️ 設定

デフォルトの設定は以下の通りです。
完全な設定の一覧は [config.lua](./lua/js-i18n/config.lua) を参照してください。

```lua
{
  primary_language = {}, -- 優先表示する言語（バーチャルテキストなどの表示に使用する言語の初期設定）
  translation_source = { "**/{locales,messages}/*.json" }, -- 翻訳リソースのパターン
  respect_gitignore = true, -- 翻訳リソースや実装ファイルを取得する際に .gitignore を尊重するかどうか。false にするど動作が速くなることがあります。
  detect_language = ..., -- 言語を検出する関数。デフォルトではファイル名からヒューリスティックに検出する関数が使用されます。
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

### フラット化されたJSONの扱い方

フラット化されたJSON（例: `{ "some.deeply.nested.key": "value" }`）を使用している場合は、`key_separator` を通常使用しない文字に設定することで対応できます。

```lua
{
  key_separator = "?", -- または "__no_separate__" など、キーに含まれない文字
}
```

これにより、ドット区切りのキーがそのまま1つのキーとして扱われるようになります。

## ⬆️ ロードマップ

- ライブラリサポートの強化
  - namespace のサポート
- Language Server の実装を別プロジェクトに切り出す
