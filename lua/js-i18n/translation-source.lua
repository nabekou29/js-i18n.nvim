local c = require("js-i18n.config")
local Path = require("plenary.path")
local scan = require("plenary.scandir")
local async = require("plenary.async")

local M = {}

--- 文言ファイルの一覧を取得する
--- @param dir string ディレクトリ
--- @return string[]
function M.get_translation_files(dir)
  local result = {}
  for _, pattern in ipairs(c.config.translation_source) do
    vim.print("pattern: " .. pattern)
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

---- TranslationSource

--- 翻訳リソースの管理をするクラス
--- @class I18n.TranslationSource
--- @field translations table<string, table<string, table>> 言語とファイルごとの翻訳リソース. 形式: { [lang: string]: { [file_name: string]: JSON } }
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

  self.translations = {}
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

    local handler = vim.uv.new_fs_poll()
    table.insert(self.watch_handlers, handler)
    vim.uv.fs_poll_start(handler, file, interval, function(err, _)
      if err then
        vim.notify_once("Error watching translation file: " .. err, vim.log.levels.ERROR)
        return
      end

      ---@diagnostic disable-next-line: redefined-local
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

--- 文言ファイルの監視を停止する
function TranslationSource:stop_watch()
  for _, handler in ipairs(self.watch_handlers) do
    ---@diagnostic disable-next-line: undefined-field
    vim.uv.fs_poll_stop(handler)
  end
  self.watch_handles = {}
end

--- 文言ファイルの読み取り
--- @param file string ファイルパス
--- @param callback fun(err: string | nil, json: table | nil) コールバック
function TranslationSource:read_translation_file(file, callback)
  local path = Path:new(file)

  if not path:exists() then
    vim.schedule(function()
      callback("File not found", nil)
    end)
    return
  end

  local json, err = path:read()
  if err or not json then
    vim.schedule(function()
      callback("Cloud not read file" .. err, nil)
    end)
  end

  vim.schedule(function()
    local ok, result = pcall(vim.fn.json_decode, json)
    if not ok then
      callback("Cloud not decode json:" .. result, nil)
    else
      callback(nil, result)
    end
  end)
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
    if self.translations[lang] == nil then
      self.translations[lang] = {}
    end
    self.translations[lang][file] = json

    if callback then
      callback()
    end
  end)
end

--- 文言の取得
--- @param lang string 言語
--- @param key string | string[] キー
--- @return any|string|nil
function TranslationSource:get_translation(lang, key)
  if self.translations[lang] == nil then
    return nil
  end

  --- @type string[]
  local key_array = {}
  if type(key) == "string" then
    key_array = { key }
  else
    key_array = key
  end

  for _, json in pairs(self.translations[lang]) do
    local text = vim.tbl_get(json, unpack(key_array))
    if text then
      return text
    end
  end
end

--- 利用可能な言語の一覧を取得する
--- @return string[]
function TranslationSource:get_available_languages()
  return vim.fn.sort(vim.tbl_keys(self.translations))
end

M.TranslationSource = TranslationSource

return M
