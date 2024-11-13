local Path = require("plenary.path")
local scan = require("plenary.scandir")

local analyzer = require("js-i18n.analyzer")
local c = require("js-i18n.config")
local utils = require("js-i18n.utils")

--- ハンドラ
--- @param params lsp.ReferenceParams
--- @param client I18n.Client
--- @return string | nil error
--- @return lsp.Location[] | nil result
local function handler(params, client)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)

  local workspace_dir = utils.get_workspace_root(bufnr)
  local keys = analyzer.get_key_at_cursor(bufnr, params.position)

  if not keys or #keys == 0 then
    return nil, {}
  end

  local key = table.concat(keys, c.config.key_separator)

  -- OPTIMIZE: 試しに、全てのファイルを走査する方式で実装してみる

  --- @type lsp.Location[]
  local result = {}
  scan.scan_dir(workspace_dir, {
    search_pattern = function(entry)
      return entry:match("%.jsx?$") or entry:match("%.tsx?$")
    end,
    on_insert = function(path)
      local bufnr = vim.api.nvim_create_buf(false, true)
      local content = Path:new(path):read()
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, "\n"))
      vim.api.nvim_buf_set_option(
        bufnr,
        "filetype",
        vim.filetype.match({ filename = path }) or "typescriptreact"
      )

      local t_calls = analyzer.find_call_t_expressions(bufnr)
      for _, t_call in ipairs(t_calls) do
        if t_call.key == key then
          local row_start, col_start, row_end, col_end = t_call.node:range()
          table.insert(result, {
            uri = vim.uri_from_fname(path),
            range = {
              start = { line = row_start, character = col_start },
              ["end"] = { line = row_end, character = col_end },
            },
          })
        end
      end

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end,
  })

  return nil, result
end

--- @type I18n.lsp.ProtocolModule
local M = {
  handler = handler,
}
return M
