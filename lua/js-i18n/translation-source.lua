local Path = require("plenary.path")
local async = require("plenary.async")
local scan = require("plenary.scandir")
local utils = require("js-i18n.utils")

local c = require("js-i18n.config")

local M = {}

--- 文言ファイルの一覧を取得する
--- @param dir string ディレクトリ
--- @return string[]
function M.get_translation_files(dir)
  local result = {}
  for _, pattern in ipairs(c.config.translation_source) do
    local regexp = vim.regex(vim.fn.glob2regpat(pattern))
    scan.scan_dir(dir, {
      search_pattern = "%.json$",
      on_insert = function(path)
        local match_s = regexp:match_str(path)
        if match_s then
          table.insert(result, path)
        end
      end,
    })
  end
  return result
end

--- 文言の更新
--- @param file string ファイルパス
--- @param key string[] キー
--- @param text string 文言
function M.update_translation(file, key, text)
  -- jq コマンドを使って json ファイルを追加 or 更新する
  local key_str = vim
    .iter(key)
    :map(function(k)
      return string.format('"%s"', k)
    end)
    :join(".")

  -- text に ' が含まれている場合はエスケープする
  text = text:gsub("'", "'\"'\"'")

  local cmd = string.format(
    "jq '.%s = \"%s\"' %s > %s.tmp && mv %s.tmp %s",
    key_str,
    text,
    file,
    file,
    file,
    file
  )

  local output = vim.fn.system(cmd)
  if output ~= "" and vim.v.shell_error ~= 0 then
    vim.notify("Error updating translation: " .. output, vim.log.levels.ERROR)
    -- tmp ファイルが残っているため削除
    vim.fn.delete(file .. ".tmp")
  end
end

---- TranslationSource

--- 翻訳リソースの管理をするクラス
--- @class I18n.TranslationSource
--- @field _translations table<string, table<string, table>> 言語とファイルごとの翻訳リソース. 形式: { [lang: string]: { [file_name: string]: JSON } }
--- @field watch_handlers unknown[] ファイル監視ハンドラ
--- @field config I18n.TranslationSourceConfig 設定
local TranslationSource = {}
TranslationSource.__index = TranslationSource

--- 設定
--- @class I18n.TranslationSourceConfig
--- @field workspace_dir string ワークスペースディレクトリ
--- @field on_update? fun() 翻訳リソース更新時のコールバック

--- コンストラクタ
--- @param config I18n.TranslationSourceConfig
--- @return I18n.TranslationSource
function TranslationSource.new(config)
  local self = setmetatable({}, TranslationSource)

  self._translations = {}
  self.watch_handlers = {}
  self.config = config
  return self
end

--- 文言ファイルの監視を開始する
--- @param callback? fun() 初回読み取り完了時のコールバック
function TranslationSource:start_watch(callback)
  local files = M.get_translation_files(self.config.workspace_dir)

  local interval = 1000
  local initial_update_functions = {}
  for _, file in ipairs(files) do
    -- 開始時に読み込む
    table.insert(initial_update_functions, function()
      async.wrap(TranslationSource.update_translation, 3)(self, file)
    end)

    local handler, err = vim.uv.new_fs_poll()
    if err or handler == nil then
      vim.notify_once("Error creating fs_poll: " .. err, vim.log.levels.ERROR)
      return
    end

    table.insert(self.watch_handlers, handler)
    vim.uv.fs_poll_start(handler, file, interval, function(err, _)
      if err then
        vim.notify_once("Error watching translation file: " .. err, vim.log.levels.ERROR)
        return
      end

      self:update_translation(file, function(err)
        if err then
          vim.notify_once("Error updating translation file: " .. err, vim.log.levels.ERROR)
          return
        end
        if self.config.on_update then
          self.config.on_update()
        end
      end)
    end)
  end

  -- 初回読み込みの完了を待ってからコールバックを実行
  async.run(function()
    async.util.join(initial_update_functions)
  end, function()
    if self.config.on_update then
      self.config.on_update()
    end
    if callback then
      callback()
    end
  end)
end

--- 特定言語の翻訳リソースを取得する
--- @param lang string 言語
--- @param namespace string?
--- @return table<string, table>
function TranslationSource:get_translation_source_by_lang(lang, namespace)
  local translations = self._translations[lang] or {}
  local filtered_translations = {}

  if namespace then
    for file, content in pairs(translations) do
      if file == namespace .. ".json" then
        filtered_translations[file] = content
      end
    end
  else
    filtered_translations = translations
  end

  return filtered_translations
end

--- 文言ファイルの監視を停止する
function TranslationSource:stop_watch()
  for _, handler in ipairs(self.watch_handlers) do
    vim.uv.fs_poll_stop(handler)
  end
  self.watch_handles = {}
end

--- 文言ファイルの読み取り
--- @param file string ファイルパス
--- @param callback fun(err: string | nil, json: table | nil) コールバック
function TranslationSource:read_translation_file(file, callback)
  if vim.in_fast_event() then
    vim.schedule(function()
      self:read_translation_file(file, callback)
    end)
    return
  end

  local path = Path:new(file)

  if not path:exists() then
    callback("File not found", nil)
    return
  end

  local json, err = path:read()
  if err or not json then
    callback("Cloud not read file" .. err, nil)
    return
  end

  local ok, result = pcall(vim.fn.json_decode, json)
  if not ok then
    callback("Cloud not decode json:" .. result, nil)
  else
    callback(nil, result)
  end
end

--- 文言ファイルの更新
--- @param file string ファイルパス
--- @param callback? fun(err: string | nil) コールバック
function TranslationSource:update_translation(file, callback)
  self:read_translation_file(file, function(err, json)
    if err then
      if callback then
        callback("Error reading translation file: " .. err)
      end
      return
    end

    local lang = c.config.detect_language(file)
    if self._translations[lang] == nil then
      self._translations[lang] = {}
    end
    self._translations[lang][file] = json

    if callback then
      callback()
    end
  end)
end

--- 文言の取得
--- @param lang string 言語
--- @param key string[] キー
--- @param library? string ライブラリ
--- @param namespace? string
--- @return any|string|nil translation 文言
--- @return string|nil file 文言リソース
function TranslationSource:get_translation(lang, key, library, namespace)
  for file, json in pairs(self:get_translation_source_by_lang(lang, namespace)) do
    local text = vim.tbl_get(json, unpack(key))
    if text then
      return text, file
    end

    if library == utils.Library.I18Next then
      for _, suffix in ipairs(c.config.libraries.i18next.plural_suffixes) do
        local key_with_suffix = { unpack(key) }
        key_with_suffix[#key_with_suffix] = key_with_suffix[#key_with_suffix] .. suffix
        text = vim.tbl_get(json, unpack(key_with_suffix))
        if text then
          return text, file
        end
      end
    end
  end
end

--- 利用可能な言語の一覧を取得する
--- @return string[]
function TranslationSource:get_available_languages()
  return vim.fn.sort(vim.tbl_keys(self._translations))
end

M.TranslationSource = TranslationSource

return M
