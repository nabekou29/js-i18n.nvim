local M = {}

--- @param client I18n.Client
function M.setup(client)
  local group = vim.api.nvim_create_augroup("js-i18n-lsp", {})

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "js_i18n/translation_source_updated",
    callback = function()
      vim.schedule(function()
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          local uri = vim.uri_from_bufnr(bufnr)
          require("js-i18n.lsp.checker").check(client, uri)
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "js_i18n/diagnostics_enabled_*",
    callback = function()
      vim.schedule(function()
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          local uri = vim.uri_from_bufnr(bufnr)
          require("js-i18n.lsp.checker").check(client, uri)
        end
      end)
    end,
  })
end

return M
