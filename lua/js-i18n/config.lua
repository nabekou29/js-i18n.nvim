local langs = require("js-i18n.lang_name_list")
local utils = require("js-i18n.utils")

local M = {}

local function normalize_lang(locale)
  return locale:lower():gsub("-", "_")
end

local LangSet = {}
for _, l in ipairs(langs) do
  LangSet[normalize_lang(l)] = true
end

--- Detect language from file path heuristically
--- @param path string File path
function M.default_detect_language(path)
  local abs_path = vim.fn.fnamemodify(path, ":p")
  local split = vim.split(abs_path, "[/.]")

  local lang = "unknown"

  for _, part in ipairs(vim.fn.reverse(split)) do
    if LangSet[normalize_lang(part)] then
      lang = part
      break
    end
  end

  return lang
end

--- バーチャルテキストのフォーマット関数
--- @param text string
--- @param opts I18n.VirtText.FormatOpts
--- @return string|string[][]
local function default_virt_text_format(text, opts)
  local prefix = ""
  local suffix = ""
  if not opts.config.virt_text.conceal_key then
    prefix = " : "
  end

  text = utils.escape_translation_text(text)
  if opts.config.virt_text.max_length > 0 then
    text = utils.utf_truncate(text, opts.config.virt_text.max_length, "...")
  elseif opts.config.virt_text.max_width > 0 then
    text = utils.truncate_display_width(text, opts.config.virt_text.max_width, "...")
  end

  return prefix .. text .. suffix
end

--- @class I18n.Config
--- @field primary_language string[] 優先表示する言語
--- @field translation_source string[] 翻訳ソースのパターン
--- @field respect_gitignore boolean .gitignore を尊重するかどうか
--- @field detect_language fun(path: string): string ファイルパスから言語を検出する関数
--- @field namespace_separator string?
--- @field key_separator string キーのセパレータ
--- @field virt_text I18n.VirtTextConfig バーチャルテキストの設定
--- @field diagnostic I18n.Diagnostic 診断の設定
--- @field libraries table<string, table> ライブラリごとの設定

--- @class I18n.VirtTextConfig
--- @field enabled boolean バーチャルテキストを有効にするかどうか
--- @field format fun(text: string, opts: I18n.VirtText.FormatOpts): string|string[][] バーチャルテキストのフォーマット関数
--- @field max_length number バーチャルテキストの最大長 (0 の場合は無制限)
--- @field max_width number バーチャルテキストの最大幅 (0 の場合は無制限)
--- @field conceal_key boolean キーを隠すかどうか
--- @field fallback boolean 選択中の言語にキーが存在しない場合に他の言語を表示するかどうか

--- @class I18n.Diagnostic
--- @field enabled boolean diagnostics を有効にするかどうか
--- @field severity number 診断の重要度

--- デフォルト設定
--- @type I18n.Config
local default_config = {
  primary_language = {},
  translation_source = { "**/{locales,messages}/*.json" },
  detect_language = M.default_detect_language,
  namespace_separator = nil,
  key_separator = ".",
  respect_gitignore = true,
  virt_text = {
    enabled = true,
    format = default_virt_text_format,
    conceal_key = false,
    fallback = false,
    max_length = 0,
    max_width = 0,
  },
  diagnostic = {
    enabled = true,
    severity = vim.diagnostic.severity.WARN,
  },
  libraries = {
    -- Config for i18next, react-i18next, next-i18next
    i18next = {
      plural_suffixes = {
        "_ordinal_other",
        "_ordinal_many",
        "_ordinal_few",
        "_ordinal_two",
        "_ordinal_one",
        "_ordinal_zero",
        "_other",
        "_many",
        "_few",
        "_two",
        "_one",
        "_zero",
      },
    },
  },
}

--- 設定
--- @type I18n.Config
---@diagnostic disable-next-line: missing-fields
M.config = {}
setmetatable(M.config, {
  -- セットアップが終わっていない場合はエラーを出す
  __index = function(_, key)
    error("Config is not set up yet. (key: " .. key .. ")")
  end,
})

--- 設定のセットアップ
--- ユーザーの設定とデフォルト設定をマージする
--- @param user_config I18n.Config ユーザーの設定
function M.setup(user_config)
  local config = vim.tbl_deep_extend("force", default_config, user_config or {})
  M.config = config
end

return M
