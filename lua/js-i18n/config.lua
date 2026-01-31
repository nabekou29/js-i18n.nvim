local utils = require("js-i18n.utils")

local M = {}

--- @class I18n.VirtText.FormatOpts
--- @field key string
--- @field value string

--- @class I18n.VirtTextConfig
--- @field enabled boolean
--- @field format fun(text: string, opts: I18n.VirtText.FormatOpts): string|string[][]
--- @field conceal_key boolean
--- @field max_width number

--- @class I18n.DiagnosticConfig
--- @field enabled boolean
--- @field severity integer

--- @class I18n.ServerConfig
--- @field cmd string[]
--- @field translation_files? { file_pattern: string }
--- @field key_separator? string
--- @field namespace_separator? string
--- @field default_namespace? string
--- @field primary_languages? string[]
--- @field required_languages? string[]
--- @field optional_languages? string[]
--- @field virtual_text? { max_length: number }
--- @field diagnostics? { unused_keys: boolean }
--- @field indexing? { num_threads: number? }

--- @class I18n.Config
--- @field virt_text I18n.VirtTextConfig
--- @field diagnostic I18n.DiagnosticConfig
--- @field server I18n.ServerConfig

--- @param text string
--- @param _opts I18n.VirtText.FormatOpts
--- @return string
local function default_virt_text_format(text, _opts)
  text = utils.escape_translation_text(text)
  return " : " .. text
end

--- @type I18n.Config
local default_config = {
  virt_text = {
    enabled = true,
    format = default_virt_text_format,
    conceal_key = false,
    max_width = 0,
  },
  diagnostic = {
    enabled = true,
    severity = vim.diagnostic.severity.WARN,
  },
  server = {
    cmd = { "js-i18n-language-server", "--stdio" },
  },
}

--- @type I18n.Config
---@diagnostic disable-next-line: missing-fields
M.config = {}
setmetatable(M.config, {
  __index = function(_, key)
    error("Config is not set up yet. (key: " .. key .. ")")
  end,
})

--- Convert snake_case server config to camelCase I18nSettings for the language server.
--- @param server_config I18n.ServerConfig
--- @return table
function M.build_server_settings(server_config)
  local settings = {}

  if server_config.translation_files then
    settings.translationFiles = { filePattern = server_config.translation_files.file_pattern }
  end
  if server_config.key_separator then
    settings.keySeparator = server_config.key_separator
  end
  if server_config.namespace_separator then
    settings.namespaceSeparator = server_config.namespace_separator
  end
  if server_config.default_namespace then
    settings.defaultNamespace = server_config.default_namespace
  end
  if server_config.primary_languages then
    settings.primaryLanguages = server_config.primary_languages
  end
  if server_config.required_languages then
    settings.requiredLanguages = server_config.required_languages
  end
  if server_config.optional_languages then
    settings.optionalLanguages = server_config.optional_languages
  end
  if server_config.virtual_text then
    settings.virtualText = { maxLength = server_config.virtual_text.max_length }
  end
  if server_config.diagnostics then
    settings.diagnostics = { unusedKeys = server_config.diagnostics.unused_keys }
  end
  if server_config.indexing then
    settings.indexing = { numThreads = server_config.indexing.num_threads }
  end

  return settings
end

--- Migrate deprecated config keys to the new schema.
--- @param opts table
--- @return table
function M.migrate_config(opts)
  local warnings = {}

  if opts.primary_language then
    opts.server = opts.server or {}
    opts.server.primary_languages = opts.primary_language
    opts.primary_language = nil
    table.insert(warnings, "primary_language -> server.primary_languages")
  end
  if opts.translation_source then
    opts.server = opts.server or {}
    opts.server.translation_files = { file_pattern = opts.translation_source[1] }
    opts.translation_source = nil
    table.insert(warnings, "translation_source -> server.translation_files.file_pattern")
  end
  if opts.key_separator and not (opts.server and opts.server.key_separator) then
    opts.server = opts.server or {}
    opts.server.key_separator = opts.key_separator
    opts.key_separator = nil
    table.insert(warnings, "key_separator -> server.key_separator")
  end
  if opts.namespace_separator and not (opts.server and opts.server.namespace_separator) then
    opts.server = opts.server or {}
    opts.server.namespace_separator = opts.namespace_separator
    opts.namespace_separator = nil
    table.insert(warnings, "namespace_separator -> server.namespace_separator")
  end

  for _, key in ipairs({ "detect_language", "libraries", "respect_gitignore" }) do
    if opts[key] ~= nil then
      opts[key] = nil
      table.insert(warnings, key .. " has been removed (now handled by the server)")
    end
  end

  if #warnings > 0 then
    vim.notify(
      "[js-i18n] Deprecated config keys detected. Please update your configuration:\n  "
        .. table.concat(warnings, "\n  "),
      vim.log.levels.WARN
    )
  end

  return opts
end

--- @param user_config? table
function M.setup(user_config)
  local opts = M.migrate_config(user_config or {})
  M.config = vim.tbl_deep_extend("force", default_config, opts)
end

return M
