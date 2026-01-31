local c = require("js-i18n.config")
local virt_text = require("js-i18n.virt_text")

local M = {}

--- Get the js_i18n LSP client for the current buffer.
--- @return vim.lsp.Client?
local function get_client()
  local clients = vim.lsp.get_clients({ name = "js_i18n" })
  return clients[1]
end

--- Execute a command on the language server.
--- @param command string
--- @param arguments? any[]
--- @param callback? fun(err: any, result: any)
local function execute_command(command, arguments, callback)
  local client = get_client()
  if not client then
    vim.notify("[js-i18n] Language server is not running.", vim.log.levels.WARN)
    return
  end

  client:request("workspace/executeCommand", {
    command = command,
    arguments = arguments or {},
  }, callback or function() end)
end

--- @param opts? table
M.setup = function(opts)
  c.setup(opts)

  local cmd = c.config.server.cmd
  if vim.fn.executable(cmd[1]) ~= 1 then
    vim.notify_once(
      "[js-i18n] Language server not found: "
        .. cmd[1]
        .. "\nInstall with: npm install -g js-i18n-language-server",
      vim.log.levels.WARN
    )
    return
  end

  -- Highlight group
  vim.api.nvim_set_hl(0, "@i18n.translation", { link = "Comment", default = true })

  -- LSP server configuration (Neovim 0.11+)
  vim.lsp.config["js_i18n"] = {
    cmd = cmd,
    filetypes = {
      "javascript",
      "typescript",
      "javascriptreact",
      "typescriptreact",
      "json",
    },
    root_markers = { "package.json", ".git" },
    settings = c.build_server_settings(c.config.server),
  }
  vim.lsp.enable("js_i18n")

  -- Virtual text autocmds
  local group = vim.api.nvim_create_augroup("js-i18n", { clear = true })

  vim.api.nvim_create_autocmd("LspProgress", {
    group = group,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client or client.name ~= "js_i18n" then
        return
      end
      local value = ev.data.params and ev.data.params.value
      if value and value.kind == "end" then
        virt_text.refresh_all()
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    pattern = "*.{ts,js,tsx,jsx}",
    group = group,
    callback = function(ev)
      virt_text.request_decorations_debounced(ev.buf)
    end,
  })

  -- User commands
  vim.api.nvim_create_user_command("I18nSetLang", function(cmd_opts)
    local lang = cmd_opts.args
    if lang == "" then
      lang = nil
    end
    execute_command("i18n.setCurrentLanguage", { { language = lang } }, function()
      vim.schedule(function()
        virt_text.refresh_all()
      end)
    end)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("I18nEditTranslation", function(cmd_opts)
    local lang = cmd_opts.args
    if lang == "" then
      lang = nil
    end
    local key = nil -- server determines from cursor position via code action
    execute_command("i18n.editTranslation", { lang, key })
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("I18nVirtualTextEnable", function()
    c.config.virt_text.enabled = true
    virt_text.refresh_all()
  end, {})

  vim.api.nvim_create_user_command("I18nVirtualTextDisable", function()
    c.config.virt_text.enabled = false
    virt_text.clear_all_extmarks()
  end, {})

  vim.api.nvim_create_user_command("I18nVirtualTextToggle", function()
    c.config.virt_text.enabled = not c.config.virt_text.enabled
    if c.config.virt_text.enabled then
      virt_text.refresh_all()
    else
      virt_text.clear_all_extmarks()
    end
  end, {})

  vim.api.nvim_create_user_command("I18nCopyKey", function()
    local uri = vim.uri_from_bufnr(0)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local position = { line = cursor[1] - 1, character = cursor[2] }
    execute_command("i18n.getKeyAtPosition", { { uri = uri, position = position } }, function(err, result)
      if err then
        vim.schedule(function()
          vim.notify("[js-i18n] Failed to get key: " .. tostring(err), vim.log.levels.ERROR)
        end)
        return
      end
      vim.schedule(function()
        if result and result.key then
          vim.fn.setreg("+", result.key)
          vim.notify("[js-i18n] Copied: " .. result.key, vim.log.levels.INFO)
        else
          vim.notify("[js-i18n] No translation key found at cursor.", vim.log.levels.WARN)
        end
      end)
    end)
  end, {})

  vim.api.nvim_create_user_command("I18nDeleteUnusedKeys", function()
    local uri = vim.uri_from_bufnr(0)
    execute_command("i18n.deleteUnusedKeys", { { uri = uri } }, function(err, result)
      if err then
        vim.schedule(function()
          vim.notify(
            "[js-i18n] Failed to delete unused keys: " .. tostring(err),
            vim.log.levels.ERROR
          )
        end)
        return
      end
      if result then
        vim.schedule(function()
          vim.notify(
            "[js-i18n] Deleted " .. (result.deletedCount or 0) .. " unused key(s).",
            vim.log.levels.INFO
          )
        end)
      end
    end)
  end, {})
end

return M
