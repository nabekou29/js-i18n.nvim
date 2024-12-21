local async = require("plenary.async")

local analyzer = require("js-i18n.analyzer")
local c = require("js-i18n.config")
local translation_source = require("js-i18n.translation_source")
local utils = require("js-i18n.utils")
local virt_text = require("js-i18n.virt_text")

local async_ui = {
  input = function(...)
    return async.wrap(vim.ui.input, 2)(...)
  end,
  select = function(...)
    return async.wrap(vim.ui.select, 3)(...)
  end,
}

if _TEST then
  async_ui = _test_async_ui or async_ui
end

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
--- @field t_source_by_workspace table<string, I18n.TranslationSource> ワークスペースごとに翻訳ソースを管理する（モノレポ対応）
local Client = {}
Client.__index = Client

function Client.new()
  local self = setmetatable({}, Client)

  self.current_language = nil
  self.t_source_by_workspace = {}

  return self
end

--- 対象のバッファで使用すべき言語を取得する
--- @param bufnr number バッファ番号
function Client:get_language(bufnr)
  local workspace_dir = utils.get_workspace_root(bufnr)
  local ws_t_source = self.t_source_by_workspace[workspace_dir]
  if ws_t_source == nil then
    return utils.get_language(self.current_language, c.config.primary_language, {})
  else
    return utils.get_language(
      self.current_language,
      c.config.primary_language,
      ws_t_source:get_available_languages()
    )
  end
end

--- 対象のバッファでバーチャルテキストを更新する
--- @param bufnr number バッファ番号
function Client:update_virt_text(bufnr)
  if not c.config.virt_text.enabled then
    virt_text.clear_extmarks(bufnr)
    return
  end
  local workspace_dir = utils.get_workspace_root(bufnr)
  local ws_t_source = self.t_source_by_workspace[workspace_dir]
  if ws_t_source == nil then
    return
  end
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
        vim.api.nvim_exec_autocmds("User", {
          pattern = "js_i18n/translation_source_updated",
          data = {},
        })
      end,
    })
    self.t_source_by_workspace[workspace_dir]:start_watch()

  -- ワークスペースが登録されている場合は、バーチャルテキストの更新を行う
  else
    self:update_virt_text(bufnr)
  end
end

--- 言語を変更する
--- @param lang? string 言語
function Client:change_language(lang)
  async.void(function()
    local bufnr = vim.api.nvim_get_current_buf()
    local workspace_dir = utils.get_workspace_root(bufnr)
    local ws_t_source = self.t_source_by_workspace[workspace_dir]

    -- 言語が指定されていない場合は、現在表示している言語を取得
    if not lang or #lang == 0 then
      if ws_t_source == nil then
        vim.notify("Translation source not found", vim.log.levels.ERROR)
        return
      end

      local selected = async_ui.select(ws_t_source:get_available_languages(), {
        prompt = "Select language: ",
      })
      lang = selected
    end

    self.current_language = lang
    self:update_virt_text_all_bufs()
  end)()
end

--- バーチャルテキストの有効化
function Client:enable_virt_text()
  c.config.virt_text.enabled = true
  self:update_virt_text_all_bufs()
end

--- バーチャルテキストの無効化
function Client:disable_virt_text()
  c.config.virt_text.enabled = false
  self:update_virt_text_all_bufs()
end

--- バーチャルテキストの有効化/無効化を切り替える
function Client:toggle_virt_text()
  c.config.virt_text.enabled = not c.config.virt_text.enabled
  self:update_virt_text_all_bufs()
end

--- diagnostic の有効化
function Client:enable_diagnostic()
  c.config.diagnostic.enabled = true
  vim.api.nvim_exec_autocmds("User", {
    pattern = "js_i18n/diagnostics_enabled_on",
    data = {},
  })
end

--- diagnostic の無効化
function Client:disable_diagnostic()
  c.config.diagnostic.enabled = false
  vim.api.nvim_exec_autocmds("User", {
    pattern = "js_i18n/diagnostics_enabled_off",
    data = {},
  })
end

--- diagnostic の有効化/無効化を切り替える
function Client:toggle_diagnostic()
  c.config.diagnostic.enabled = not c.config.diagnostic.enabled
  vim.api.nvim_exec_autocmds("User", {
    pattern = "js_i18n/diagnostics_enabled_toggle",
    data = {},
  })
end

--- 文言の編集
--- @param lang? string 言語
--- @param key? string キー
function Client:edit_translation(lang, key)
  async.void(function()
    local bufnr = vim.api.nvim_get_current_buf()

    -- 言語が指定されていない場合は、現在表示している言語を取得
    if not lang or #lang == 0 then
      lang = self:get_language(bufnr)
    end

    local function get_key()
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local position = { line = row - 1, character = col }

      local ok, t_call = analyzer.check_cursor_in_t_argument(bufnr, position)
      if not ok or not t_call then
        return
      end
      return t_call.key
    end

    -- キーを取得
    local key = key or get_key()
    if not key then
      vim.notify("Key not found", vim.log.levels.ERROR)
      return
    end
    local split_key = vim.split(key, c.config.key_separator, { plain = true })

    local workspace_dir = utils.get_workspace_root(bufnr)
    local ws_t_source = self.t_source_by_workspace[workspace_dir]
    if ws_t_source == nil then
      vim.notify("Translation source not found", vim.log.levels.ERROR)
      return
    end

    local namespace = nil

    if c.config.namespace_separator ~= nil then
      local split_first_key =
        vim.split(split_key[1], c.config.namespace_separator, { plain = true })
      namespace = split_first_key[1]
      split_key[1] = split_first_key[2]
    end

    -- キーに一致する文言があれば編集、なければ追加
    local old_translation, file = ws_t_source:get_translation(lang, split_key, nil, namespace)
    if not file then
      local sources = ws_t_source:get_translation_source_by_lang(lang)

      local all_files = vim.tbl_keys(sources)

      local files = {}

      local i = 1
      for _, file in pairs(all_files) do
        if namespace == nil or string.find(file, namespace .. ".json") then
          files[i] = file
          i = i + 1
        end
      end

      -- カレントディレクトリからの相対パスに変換
      files = vim.tbl_map(function(f)
        return vim.fn.fnamemodify(f, ":.")
      end, files)

      -- 文言ファイルが複数ある場合は、選択させる
      if #files > 1 then
        local selected = async_ui.select(files, {
          prompt = "Select translation file: ",
        })
        file = selected
      else
        file = files[1]
      end
    end

    if not file then
      return
    end

    local old_translation = old_translation and utils.escape_translation_text(old_translation) or ""
    local translation = old_translation
    if old_translation then
      local input = async_ui.input({
        prompt = "Edit translation: ",
        default = old_translation,
      })
      translation = input
    else
      local input = async_ui.input({
        prompt = "Add translation: ",
      })
      translation = input
    end

    if not translation or translation == old_translation then
      return
    end

    translation_source.update_translation(file, split_key, translation)
  end)()
end

--- カーソル上のキーを取得する
function Client:get_key_on_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local position = { line = row - 1, character = col }

  local keys = analyzer.get_key_at_cursor(bufnr, position)
  if not keys then
    return
  end
  return vim.fn.join(keys, c.config.key_separator)
end

return Client
