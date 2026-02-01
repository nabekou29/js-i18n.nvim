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

--- Show vim.ui.input to edit a translation value and save it.
--- @param lang string
--- @param key string
local function prompt_edit_translation(lang, key)
  execute_command(
    "i18n.getTranslationValue",
    { { lang = lang, key = key } },
    function(val_err, val_result)
      local current_value = ""
      if not val_err and val_result and val_result.value then
        current_value = val_result.value
      end
      vim.schedule(function()
        vim.ui.input({
          prompt = ("[%s] %s: "):format(lang, key),
          default = current_value,
        }, function(input)
          if input == nil then
            return
          end
          execute_command("i18n.editTranslation", {
            { lang = lang, key = key, value = input },
          }, function(edit_err)
            if edit_err then
              vim.schedule(function()
                vim.notify(
                  "[js-i18n] Failed to edit translation: " .. tostring(edit_err),
                  vim.log.levels.ERROR
                )
              end)
            end
          end)
        end)
      end)
    end
  )
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
    capabilities = {
      experimental = {
        i18nEditTranslationCodeAction = true,
      },
    },
    handlers = {
      ["i18n/decorationsChanged"] = function()
        virt_text.refresh_all()
      end,
    },
  }
  vim.lsp.enable("js_i18n")

  -- Client-side LSP command handler
  vim.lsp.commands["i18n.executeClientEditTranslation"] = function(command)
    local args = command.arguments and command.arguments[1]
    if args and args.lang and args.key then
      prompt_edit_translation(args.lang, args.key)
    end
  end

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

    -- Get key at cursor position
    local uri = vim.uri_from_bufnr(0)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local position = { line = cursor[1] - 1, character = cursor[2] }

    execute_command(
      "i18n.getKeyAtPosition",
      { { uri = uri, position = position } },
      function(err, key_result)
        if err or not key_result or not key_result.key then
          vim.schedule(function()
            vim.notify("[js-i18n] No translation key found at cursor.", vim.log.levels.WARN)
          end)
          return
        end

        if lang then
          prompt_edit_translation(lang, key_result.key)
        else
          execute_command("i18n.getCurrentLanguage", {}, function(lang_err, lang_result)
            if lang_err or not lang_result or not lang_result.language then
              vim.schedule(function()
                vim.notify(
                  "[js-i18n] No current language set. Use :I18nSetLang first.",
                  vim.log.levels.WARN
                )
              end)
              return
            end
            prompt_edit_translation(lang_result.language, key_result.key)
          end)
        end
      end
    )
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
    execute_command(
      "i18n.getKeyAtPosition",
      { { uri = uri, position = position } },
      function(err, result)
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
      end
    )
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
