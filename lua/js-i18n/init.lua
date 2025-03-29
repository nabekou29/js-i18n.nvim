local Client = require("js-i18n.client")
local c = require("js-i18n.config")

local i18n = {}

--- コマンド用の言語の補完関数を取得する
--- @param translation_sources I18n.TranslationSource[]
--- @return fun(string, string, number): string[]
local function get_completion_available_languages(translation_sources)
  return function(arg_lead, _cmd_line, _cursor_pos)
    local matches = {}

    local available_languages = {}
    for _, source in ipairs(translation_sources) do
      for _, lang in ipairs(source:get_available_languages()) do
        available_languages[lang] = true
      end
    end

    for lang, _ in pairs(available_languages) do
      if lang:match(arg_lead) then
        table.insert(matches, lang)
      end
    end
    return matches
  end
end

--- @type I18n.Client
i18n.client = nil

--- setup
--- @param opts I18n.Config
i18n.setup = function(opts)
  local hl = vim.api.nvim_set_hl

  hl(0, "@i18n.translation", { link = "Comment" })

  local group = vim.api.nvim_create_augroup("js-i18n", {})
  -- 設定の初期化
  c.setup(opts)

  i18n.client = Client.new()

  -- ファイルの変更などがあれば、バーチャルテキストを更新する
  vim.api.nvim_create_autocmd({
    "BufEnter",
    "TextChanged",
    "TextChangedI",
    "TextChangedP",
  }, {
    pattern = "*.{ts,js,tsx,jsx}",
    group = group,
    callback = function(ev)
      local bufnr = ev.buf
      i18n.client:update_js_file_handler(bufnr)
    end,
  })
  local lspconfig = require("lspconfig")
  local lsp_configs = require("lspconfig.configs")

  if not lsp_configs.i18n_lsp then
    lsp_configs.i18n_lsp = {
      default_config = {
        --- @param dispatchers vim.lsp.rpc.Dispatchers
        --- @return vim.lsp.rpc.PublicClient
        cmd = function(dispatchers)
          return require("js-i18n.lsp").create_rpc(dispatchers, i18n.client)
        end,
        filetypes = {
          "javascript",
          "typescript",
          "javascriptreact",
          "typescriptreact",
          "javascript.jsx",
          "typescript.tsx",
          "json",
        },
        single_file_support = true,
      },
    }
  end
  lspconfig.i18n_lsp.setup({
    handlers = {
      ["workspace/executeCommand"] = function(_err, _result, ctx)
        if ctx.params.command == "i18n.editTranslation" then
          local lang = ctx.params.arguments[1]
          local key = ctx.params.arguments[2]
          i18n.client:edit_translation(lang, key)
        end
      end,
    },
  })

  --- 言語の変更
  vim.api.nvim_create_user_command("I18nSetLang", function(opts)
    local lang = opts.args
    i18n.client:change_language(lang)
  end, {
    nargs = "?",
    complete = function(...)
      return get_completion_available_languages(vim.tbl_values(i18n.client.t_source_by_workspace))(
        ...
      )
    end,
  })
  --- バーチャルテキストの有効化
  vim.api.nvim_create_user_command("I18nVirtualTextEnable", function(_)
    i18n.client:enable_virt_text()
  end, {})
  --- バーチャルテキストの無効化
  vim.api.nvim_create_user_command("I18nVirtualTextDisable", function(_)
    i18n.client:disable_virt_text()
  end, {})
  --- バーチャルテキストの有効化/無効化を切り替える
  vim.api.nvim_create_user_command("I18nVirtualTextToggle", function(_)
    i18n.client:toggle_virt_text()
  end, {})

  --- diagnostic の有効化
  vim.api.nvim_create_user_command("I18nDiagnosticEnable", function(_)
    i18n.client:enable_diagnostic()
  end, {})
  --- diagnostic の無効化
  vim.api.nvim_create_user_command("I18nDiagnosticDisable", function(_)
    i18n.client:disable_diagnostic()
  end, {})
  --- diagnostic の有効化/無効化を切り替える
  vim.api.nvim_create_user_command("I18nDiagnosticToggle", function(_)
    i18n.client:toggle_diagnostic()
  end, {})

  --- 文言の編集
  vim.api.nvim_create_user_command("I18nEditTranslation", function(opts)
    local lang = opts.args
    i18n.client:edit_translation(lang)
  end, {
    nargs = "?",
    complete = function(...)
      return get_completion_available_languages(vim.tbl_values(i18n.client.t_source_by_workspace))(
        ...
      )
    end,
  })

  -- カーソル上のキーを取得する
  vim.api.nvim_create_user_command("I18nCopyKey", function(_)
    local key = i18n.client:get_key_on_cursor()
    if key == nil or key == "" then
      vim.notify("No key found", vim.log.levels.ERROR)
      return
    end
    vim.fn.setreg("*", key)
  end, {})
end

return i18n
