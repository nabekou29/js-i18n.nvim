local Path = require("plenary.path")
local scan = require("plenary.scandir")

local analyzer = require("js-i18n.analyzer")
local utils = require("js-i18n.utils")

local M = {}

--- 翻訳の参照テーブル
--- @class I18n.ReferenceTable
--- @field workspace_dir string ワークスペースディレクトリ
--- @field _ref_table table<string, table<string, FindTExpressionResultItem[]>>
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
    on_insert = function(path)
      self:load_path(path)
    end,
  })
end

function ReferenceTable:load_path(path)
  if path == nil or path == "" then
    return
  end
  local lib = utils.detect_library(self.config.workspace_dir)

  self._ref_processing[path] = true
  vim.schedule(function()
    local lang = vim.filetype.match({ filename = path }) or "typescriptreact"
    local content = Path:new(path):read()

    local result = analyzer.find_call_t_expressions_(content, lang, lib)
    self._ref_table[path] = result

    self._ref_processing[path] = false
  end)
end

function ReferenceTable:wait_processed()
  while true do
    local processing = false
    for _, v in pairs(self._ref_processing) do
      if v then
        processing = true
        break
      end
    end
    if not processing then
      break
    end
    vim.wait(100)
  end
end

--- @class ReferenceTable__find_by_key_result
--- @field path string
--- @field t_call FindTExpressionResultItem

--- キーから参照を検索する
--- @param key string キー
--- @return ReferenceTable__find_by_key_result[]
function ReferenceTable:find_by_key(key)
  local result = {}
  for path, t_calls in pairs(self._ref_table) do
    for _, t_call in ipairs(t_calls) do
      if t_call.key == key then
        table.insert(result, {
          path = path,
          t_call = t_call,
        })
      end
    end
  end
  return result
end

M.ReferenceTable = ReferenceTable

return M
