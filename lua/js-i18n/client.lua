local translation_source = require("js-i18n.translation-source")
local virt_text = require("js-i18n.virt_text")
local c = require("js-i18n.config")
local utils = require("js-i18n.utils")

--- ワークスペース内の TypeScript/JavaScript ファイルのバッファ番号を取得する
local function get_workspace_bufs(workspace_dir)
  local bufs = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local ptn = vim.fn.glob2regpat("*.{ts,js,tsx,jsx}")
    if filename:sub(1, #workspace_dir) == workspace_dir and vim.fn.match(filename, ptn) > 0 then
      table.insert(bufs, bufnr)
    end
  end
  return bufs
end

--- @class I18n.Client
--- @field current_language string|nil 選択中の言語
--- @field enabled_virt_text boolean バーチャルテキストの有効化
--- @field t_source_by_workspace table<string, I18n.TranslationSource> ワークスペースごとに翻訳ソースを管理する（モノレポ対応）
local Client = {}
Client.__index = Client

function Client.new()
  local self = setmetatable({}, Client)

  self.current_language = nil
  self.enabled_virt_text = c.config.virt_text.enabled
  self.t_source_by_workspace = {}

  return self
end

--- 対象のバッファで使用すべき言語を取得する
--- @param bufnr number バッファ番号
function Client:get_language(bufnr)
  local workspace_dir = utils.get_workspace_root(bufnr)
  local ws_t_source = self.t_source_by_workspace[workspace_dir]
  return utils.get_language(
    self.current_language,
    c.config.primary_language,
    ws_t_source:get_available_languages()
  )
end

--- 対象のバッファでバーチャルテキストを更新する
--- @param bufnr number バッファ番号
function Client:update_virt_text(bufnr)
  if not self.enabled_virt_text then
    virt_text.clear_extmarks(bufnr)
    return
  end
  local workspace_dir = utils.get_workspace_root(bufnr)
  local ws_t_source = self.t_source_by_workspace[workspace_dir]
  virt_text.set_extmark(bufnr, self:get_language(bufnr), ws_t_source)
end

--- すべてのバッファでバーチャルテキストを更新する
function Client:update_virt_text_all_bufs()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local ptn = vim.fn.glob2regpat("*.{ts,js,tsx,jsx}")
    if vim.fn.match(filename, ptn) > 0 then
      self:update_virt_text(bufnr)
    end
  end
end

--- JavaScript/TypeScript ファイルの更新時の処理
--- @param bufnr number バッファ番号
function Client:update_js_file_handler(bufnr)
  local workspace_dir = utils.get_workspace_root(bufnr)

  -- ワークスペースが登録されていない場合は、翻訳リソースの監視を開始する
  -- 翻訳リソースの読み込み後にバーチャルテキストを設定する
  if self.t_source_by_workspace[workspace_dir] == nil then
    self.t_source_by_workspace[workspace_dir] = translation_source.TranslationSource.new({
      workspace_dir = workspace_dir,
      -- 翻訳リソース更新時の処理
      on_update = function()
        for _, bufnr in ipairs(get_workspace_bufs(workspace_dir)) do
          self:update_virt_text(bufnr)
        end
      end,
    })
    self.t_source_by_workspace[workspace_dir]:start_watch()

  -- ワークスペースが登録されている場合は、バーチャルテキストの更新を行う
  else
    self:update_virt_text(bufnr)
  end
end

--- 言語を変更する
--- @param lang string 言語
function Client:change_language(lang)
  self.current_language = lang
  self:update_virt_text_all_bufs()
end

--- バーチャルテキストの有効化
function Client:enable_virt_text()
  self.enabled_virt_text = true
  self:update_virt_text_all_bufs()
end

--- バーチャルテキストの無効化
function Client:disable_virt_text()
  self.enabled_virt_text = false
  self:update_virt_text_all_bufs()
end

--- バーチャルテキストの有効化/無効化を切り替える
function Client:toggle_virt_text()
  self.enabled_virt_text = not self.enabled_virt_text
  self:update_virt_text_all_bufs()
end

return Client
