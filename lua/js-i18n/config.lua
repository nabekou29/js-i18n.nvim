local utils = require("js-i18n.utils")

local M = {}

M.SERVER_NAME = "js_i18n"
M.MINIMUM_SERVER_VERSION = "0.5.0"

--- @class I18n.VirtText.FormatOpts
--- @field key string
--- @field value string
--- @field conceal_key boolean
--- @field max_length number
--- @field max_width number

--- @class I18n.VirtTextConfig
--- @field enabled boolean
--- @field format fun(text: string, opts: I18n.VirtText.FormatOpts): string|string[][]
--- @field conceal_key boolean
--- @field max_length number
--- @field max_width number

--- @alias I18n.Severity "error" | "warning" | "information" | "hint"

--- @class I18n.TranslationFilesConfig
--- @field include_patterns? string[]
--- @field exclude_patterns? string[]

--- @class I18n.MissingTranslationConfig
--- @field enabled? boolean
--- @field severity? I18n.Severity
--- @field required_languages? string[]
--- @field optional_languages? string[]

--- @class I18n.UnusedTranslationConfig
--- @field enabled? boolean
--- @field severity? I18n.Severity
--- @field ignore_patterns? string[]

--- @class I18n.DiagnosticsConfig
--- @field missing_translation? I18n.MissingTranslationConfig
--- @field unused_translation? I18n.UnusedTranslationConfig

--- @class I18n.IndexingConfig
--- @field num_threads? number

--- @class I18n.ServerConfig
--- @field cmd string[]
--- @field translation_files? I18n.TranslationFilesConfig
--- @field include_patterns? string[]
--- @field exclude_patterns? string[]
--- @field key_separator? string
--- @field namespace_separator? string
--- @field default_namespace? string
--- @field primary_languages? string[]
--- @field diagnostics? I18n.DiagnosticsConfig
--- @field indexing? I18n.IndexingConfig

--- @class I18n.Config
--- @field virt_text I18n.VirtTextConfig
--- @field server I18n.ServerConfig

--- @param text string
--- @param opts I18n.VirtText.FormatOpts
--- @return string
local function default_virt_text_format(text, opts)
  text = utils.escape_translation_text(text)
  if opts.max_length > 0 then
    text = utils.utf_truncate(text, opts.max_length, "...")
  elseif opts.max_width > 0 then
    text = utils.truncate_display_width(text, opts.max_width, "...")
  end
  if opts.conceal_key then
    return " " .. text .. " "
  end
  return " : " .. text
end

--- @type I18n.Config
local default_config = {
  virt_text = {
    enabled = true,
    format = default_virt_text_format,
    conceal_key = false,
    max_length = 0,
    max_width = 0,
  },
  server = {
    cmd = { "js-i18n-language-server" },
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
    settings.translationFiles = {}
    if server_config.translation_files.include_patterns then
      settings.translationFiles.includePatterns = server_config.translation_files.include_patterns
    end
    if server_config.translation_files.exclude_patterns then
      settings.translationFiles.excludePatterns = server_config.translation_files.exclude_patterns
    end
  end
  if server_config.include_patterns then
    settings.includePatterns = server_config.include_patterns
  end
  if server_config.exclude_patterns then
    settings.excludePatterns = server_config.exclude_patterns
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
  if server_config.diagnostics then
    settings.diagnostics = {}

    local mt = server_config.diagnostics.missing_translation
    if mt then
      settings.diagnostics.missingTranslation = {}
      if mt.enabled ~= nil then
        settings.diagnostics.missingTranslation.enabled = mt.enabled
      end
      if mt.severity then
        settings.diagnostics.missingTranslation.severity = mt.severity
      end
      if mt.required_languages then
        settings.diagnostics.missingTranslation.requiredLanguages = mt.required_languages
      end
      if mt.optional_languages then
        settings.diagnostics.missingTranslation.optionalLanguages = mt.optional_languages
      end
    end

    local ut = server_config.diagnostics.unused_translation
    if ut then
      settings.diagnostics.unusedTranslation = {}
      if ut.enabled ~= nil then
        settings.diagnostics.unusedTranslation.enabled = ut.enabled
      end
      if ut.severity then
        settings.diagnostics.unusedTranslation.severity = ut.severity
      end
      if ut.ignore_patterns then
        settings.diagnostics.unusedTranslation.ignorePatterns = ut.ignore_patterns
      end
    end
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
    opts.server.translation_files = { include_patterns = { opts.translation_source[1] } }
    opts.translation_source = nil
    table.insert(warnings, "translation_source -> server.translation_files.include_patterns")
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

  for _, key in ipairs({ "detect_language", "libraries", "respect_gitignore", "diagnostic" }) do
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
