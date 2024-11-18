local M = {}

--- @type vim.lsp.rpc.Dispatchers
M.dispatchers = nil

--- @type table<string, I18n.ReferenceTable>
M.ref_table_by_workspace = {}

return M
