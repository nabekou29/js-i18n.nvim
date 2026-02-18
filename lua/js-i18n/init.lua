local c = require("js-i18n.config")
local utils = require("js-i18n.utils")
local virt_text = require("js-i18n.virt_text")

local M = {}

local SERVER_NAME = c.SERVER_NAME
local MINIMUM_SERVER_VERSION = c.MINIMUM_SERVER_VERSION

--- Execute a command on the language server.
--- @param command string
--- @param arguments? any[]
--- @param callback? fun(err: any, result: any)
local function execute_command(command, arguments, callback)
  local client = vim.lsp.get_clients({ name = SERVER_NAME, bufnr = 0 })[1]
  if not client then
    vim.notify("[js-i18n] Language server is not running.", vim.log.levels.WARN)
    return
  end
  client:request("workspace/executeCommand", {
    command = command,
    arguments = arguments or {},
  }, callback or function() end)
end

--- Get the translation key at the current cursor position.
--- @param callback fun(key: string)
local function get_key_at_cursor(callback)
  local uri = vim.uri_from_bufnr(0)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local position = { line = cursor[1] - 1, character = cursor[2] }
  execute_command(
    "i18n.getKeyAtPosition",
    { { uri = uri, position = position } },
    function(err, result)
      if err or not result or not result.key then
        vim.schedule(function()
          vim.notify("[js-i18n] No translation key found at cursor.", vim.log.levels.WARN)
        end)
        return
      end
      callback(result.key)
    end
  )
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

--- Resolve lang, falling back to getCurrentLanguage from the server.
--- @param lang? string
--- @param callback fun(lang: string)
local function resolve_language(lang, callback)
  if lang then
    callback(lang)
    return
  end
  execute_command("i18n.getCurrentLanguage", {}, function(err, result)
    if err or not result or not result.language then
      vim.schedule(function()
        vim.notify(
          "[js-i18n] No current language set. Use :I18nSetLang first.",
          vim.log.levels.WARN
        )
      end)
      return
    end
    callback(result.language)
  end)
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
  vim.lsp.config[SERVER_NAME] = {
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
    on_init = function(_, initialize_result)
      local server_info = initialize_result and initialize_result.serverInfo
      local server_version = server_info and server_info.version
      if server_version and utils.compare_versions(server_version, MINIMUM_SERVER_VERSION) < 0 then
        vim.notify_once(
          ("[js-i18n] Server version %s is too old (minimum: %s).\nRun: npm install -g js-i18n-language-server"):format(
            server_version,
            MINIMUM_SERVER_VERSION
          ),
          vim.log.levels.WARN
        )
      end
    end,
  }
  vim.lsp.enable(SERVER_NAME)

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
      if not client or client.name ~= SERVER_NAME then
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
    local lang = cmd_opts.args ~= "" and cmd_opts.args or nil
    if lang then
      execute_command("i18n.setCurrentLanguage", { { language = lang } })
    else
      execute_command("i18n.getAvailableLanguages", {}, function(err, result)
        if err or not result or not result.languages or #result.languages == 0 then
          vim.schedule(function()
            vim.notify("[js-i18n] No languages available.", vim.log.levels.WARN)
          end)
          return
        end
        vim.schedule(function()
          vim.ui.select(result.languages, { prompt = "Select language:" }, function(selected)
            if selected then
              execute_command("i18n.setCurrentLanguage", { { language = selected } })
            end
          end)
        end)
      end)
    end
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("I18nEditTranslation", function(cmd_opts)
    local lang = cmd_opts.args ~= "" and cmd_opts.args or nil
    get_key_at_cursor(function(key)
      resolve_language(lang, function(resolved_lang)
        prompt_edit_translation(resolved_lang, key)
      end)
    end)
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
    get_key_at_cursor(function(key)
      vim.schedule(function()
        vim.fn.setreg("+", key)
        vim.notify("[js-i18n] Copied: " .. key, vim.log.levels.INFO)
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
