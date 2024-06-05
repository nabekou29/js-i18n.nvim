local M = {}

--- @class I18n.Config
--- @field primary_language string[] 優先表示する言語
--- @field virt_text? I18n.VirtTextConfig バーチャルテキストの設定

--- @class I18n.VirtTextConfig
--- @field enabled boolean バーチャルテキストを有効にするかどうか
--- @field max_length number バーチャルテキストの最大長 (0 の場合は無制限)
--- @field conceal_key boolean キーを隠すかどうか
--- @field fallback boolean 選択中の言語にキーが存在しない場合に他の言語を表示するかどうか

--- デフォルト設定
--- @type I18n.Config
local default_config = {
  primary_language = {},
  virt_text = {
    enabled = true,
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
