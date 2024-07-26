local translation_source = require("js-i18n.translation-source")
local virt_text = require("js-i18n.virt_text")
local c = require("js-i18n.config")
local utils = require("js-i18n.utils")
local lsp_utils = require("js-i18n.lsp.utils")

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
  if not self.enabled_virt_text then
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

--- 文言の編集
--- @param lang? string 言語
function Client:edit_translation(lang)
  -- 現在のバッファとカーソルの位置を取得
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local position = { line = row - 1, character = col }

  -- 言語が指定されていない場合は、現在表示している言語を取得
  if not lang or #lang == 0 then
    lang = self:get_language(bufnr)
  end

  -- カーソル位置が t 関数の引数内にあるか確認
  local ok, key_node = lsp_utils.check_cursor_in_t_argument(bufnr, position)
  if not ok or not key_node then
    vim.notify("Key not found", vim.log.levels.ERROR)
    return
  end
  -- キーを取得
  local key = vim.treesitter.get_node_text(key_node, bufnr)
  local split_key = vim.split(key, c.config.key_separator, { plain = true })

  local workspace_dir = utils.get_workspace_root(bufnr)
  local ws_t_source = self.t_source_by_workspace[workspace_dir]
  if ws_t_source == nil then
    vim.notify("Translation source not found", vim.log.levels.ERROR)
    return
  end

  -- キーに一致する文言があれば編集、なければ追加
  local old_translation, file = ws_t_source:get_translation(lang, split_key)
  local is_success = nil
  if not file then
    local sources = ws_t_source:get_translation_source_by_lang(lang)
    local files = vim.tbl_keys(sources)
    -- 文言ファイルが複数ある場合は、選択させる
    if #files > 1 then
      vim.ui.select(files, {
        prompt = "Select translation file: ",
      }, function(selected)
        file = selected
      end)
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
    vim.ui.input({
      prompt = "Edit translation: ",
      default = utils.escape_translation_text(old_translation),
    }, function(input)
      translation = input
      is_success = translation_source.update_translation(file, split_key, translation)
    end)
  else
    vim.ui.input({
      prompt = "Add translation: ",
    }, function(input)
      translation = input
      is_success = translation_source.update_translation(file, split_key, translation)
    end)
  end

  if not translation or translation == old_translation then
    return
  end

  vim.print("")
  if not is_success then
    vim.notify("Failed to update translation", vim.log.levels.ERROR)
  end
  -- translation_source.update_translation(file, split_key, translation)
end

return Client
