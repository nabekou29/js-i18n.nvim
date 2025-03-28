local Path = require("plenary.path")
local scan = require("plenary.scandir")

local analyzer = require("js-i18n.analyzer")
local c = require("js-i18n.config")
local utils = require("js-i18n.utils")

local M = {}

--- @class I18n.Ref
--- @field key string
--- @field uri string
--- @field range lsp.Range

--- 翻訳の参照テーブル
--- @class I18n.ReferenceTable
--- @field workspace_dir string ワークスペースディレクトリ
--- @field _ref_table table<string, table<string, I18n.Ref[]>>
--- @field _ref_processing table<string, boolean>
--- @field config I18n.ReferenceTableConfig
local ReferenceTable = {}
ReferenceTable.__index = ReferenceTable

--- 設定
--- @class I18n.ReferenceTableConfig
--- @field workspace_dir string ワークスペースディレクトリ

--- @return I18n.ReferenceTable
function ReferenceTable.new(config)
  local self = setmetatable({}, ReferenceTable)

  self._ref_table = {}
  self._ref_processing = {}
  self.config = config
  return self
end

function ReferenceTable:load_all()
  scan.scan_dir(self.config.workspace_dir, {
    search_pattern = function(entry)
      if entry:match("node_modules") then
        return false
      end
      return entry:match("%.jsx?$") or entry:match("%.tsx?$")
    end,
    respect_gitignore = c.config.respect_gitignore,
    on_insert = function(path)
      self:load_path(path)
    end,
  })
end

function ReferenceTable:load_path(path, content)
  if path == nil or path == "" then
    return
  end
  local lib = utils.detect_library(self.config.workspace_dir)

  vim.schedule(function()
    local ft = vim.filetype.match({ filename = path }) or "typescriptreact"
    local lang = (function()
      if ft == "typescript" then
        return "typescript"
      elseif ft == "typescriptreact" then
        return "tsx"
      elseif ft == "javascript" then
        return "javascript"
      elseif ft == "javascriptreact" then
        return "javascript"
      end
      return nil
    end)()
    if lang == nil then
      return
    end
    content = content or Path:new(path):read()

    self._ref_processing[path] = true
    local result = analyzer.find_call_t_expressions(content, lib, lang)
    self._ref_table[path] = vim
      .iter(result)
      :map(function(t_call)
        local row_start, col_start, row_end, col_end = t_call.node:range()
        return {
          key = t_call.key,
          uri = vim.uri_from_fname(path),
          range = {
            start = { line = row_start, character = col_start },
            ["end"] = { line = row_end, character = col_end },
          },
        }
      end)
      :totable()

    self._ref_processing[path] = false
  end)
end

function ReferenceTable:wait_processed()
  local timeout = 10000
  local interval = 50
  local timeout_cnt = timeout / interval

  for _ = 1, timeout_cnt do
    local processing = false
    for _, v in pairs(self._ref_processing) do
      if v then
        processing = true
        break
      end
    end
    if not processing then
      return
    end
    vim.wait(interval)
  end

  vim.notify("Timeout: ReferenceTable:wait_processed", vim.log.levels.ERROR)
end

function ReferenceTable:is_processing(path)
  return self._ref_processing[path] ~= nil and not self._ref_processing[path]
end

--- キーから参照を検索する
--- @param key string キー
--- @return I18n.Ref[]
function ReferenceTable:find_by_key(key)
  self:wait_processed()
  local result = {}
  for _, refs in pairs(self._ref_table) do
    for _, ref in ipairs(refs) do
      if ref.key == key then
        table.insert(result, ref)
      end
    end
  end
  return result
end

M.ReferenceTable = ReferenceTable

return M
