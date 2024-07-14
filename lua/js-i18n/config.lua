local utils = require("js-i18n.utils")

local M = {}

--- ファイルパスから言語を検出する
--- @param path string ファイルパス
local function default_detect_language(path)
  local abs_path = vim.fn.fnamemodify(path, ":p")
  local split = vim.split(abs_path, "/")
  local lang = split[#split - 1]
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
  end

  return prefix .. text .. suffix
end

--- @class I18n.Config
--- @field primary_language string[] 優先表示する言語
--- @field translation_source string[] 翻訳ソースのパターン
--- @field detect_language fun(path: string): string ファイルパスから言語を検出する関数
--- @field key_separator string キーのセパレータ
--- @field virt_text I18n.VirtTextConfig バーチャルテキストの設定

--- @class I18n.VirtTextConfig
--- @field enabled boolean バーチャルテキストを有効にするかどうか
--- @field format fun(text: string, opts: I18n.VirtText.FormatOpts): string|string[][] バーチャルテキストのフォーマット関数
--- @field max_length number バーチャルテキストの最大長 (0 の場合は無制限)
--- @field conceal_key boolean キーを隠すかどうか
--- @field fallback boolean 選択中の言語にキーが存在しない場合に他の言語を表示するかどうか

--- デフォルト設定
--- @type I18n.Config
local default_config = {
  primary_language = {},
  translation_source = { "**/locales/**/*.json" },
  detect_language = default_detect_language,
  key_separator = ".",
  virt_text = {
    enabled = true,
    format = default_virt_text_format,
    conceal_key = false,
    fallback = false,
    max_length = 0,
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
