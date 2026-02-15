local config = require("js-i18n.config")

describe("js-i18n.config", function()
  describe("setup", function()
    it("should set default config when no options are given", function()
      config.setup({})
      assert.are.equal(true, config.config.virt_text.enabled)
      assert.are.equal(false, config.config.virt_text.conceal_key)
      assert.are.equal(0, config.config.virt_text.max_length)
      assert.are.equal(0, config.config.virt_text.max_width)
      assert.are.equal("js-i18n-language-server", config.config.server.cmd[1])
    end)

    it("should merge user options with defaults", function()
      config.setup({
        virt_text = { conceal_key = true },
        server = { key_separator = "-" },
      })
      assert.are.equal(true, config.config.virt_text.conceal_key)
      assert.are.equal(true, config.config.virt_text.enabled)
      assert.are.equal("-", config.config.server.key_separator)
    end)
  end)

  describe("migrate_config", function()
    it("should migrate primary_language to server.primary_languages", function()
      local opts = config.migrate_config({ primary_language = { "ja", "en" } })
      assert.is_nil(opts.primary_language)
      assert.are.same({ "ja", "en" }, opts.server.primary_languages)
    end)

    it("should migrate translation_source to server.translation_files", function()
      local opts = config.migrate_config({ translation_source = { "**/locales/*.json" } })
      assert.is_nil(opts.translation_source)
      assert.are.same({ "**/locales/*.json" }, opts.server.translation_files.include_patterns)
    end)

    it("should migrate key_separator to server.key_separator", function()
      local opts = config.migrate_config({ key_separator = "-" })
      assert.is_nil(opts.key_separator)
      assert.are.equal("-", opts.server.key_separator)
    end)

    it("should migrate namespace_separator to server.namespace_separator", function()
      local opts = config.migrate_config({ namespace_separator = ":" })
      assert.is_nil(opts.namespace_separator)
      assert.are.equal(":", opts.server.namespace_separator)
    end)

    it("should remove deprecated keys", function()
      local opts = config.migrate_config({
        detect_language = function() end,
        libraries = {},
        respect_gitignore = true,
        diagnostic = { enabled = true },
      })
      assert.is_nil(opts.detect_language)
      assert.is_nil(opts.libraries)
      assert.is_nil(opts.respect_gitignore)
      assert.is_nil(opts.diagnostic)
    end)
  end)

  describe("build_server_settings", function()
    it("should convert snake_case to camelCase", function()
      local settings = config.build_server_settings({
        cmd = { "js-i18n-language-server" },
        key_separator = "-",
        namespace_separator = ":",
        primary_languages = { "ja" },
        translation_files = {
          include_patterns = { "**/locales/*.json" },
          exclude_patterns = { "**/node_modules/**" },
        },
        include_patterns = { "**/*.{ts,tsx}" },
        exclude_patterns = { "node_modules/**" },
        diagnostics = {
          missing_translation = {
            enabled = false,
            severity = "error",
            required_languages = { "en", "ja" },
          },
          unused_translation = {
            enabled = true,
            severity = "hint",
            ignore_patterns = { "debug.*" },
          },
        },
        indexing = { num_threads = 4 },
      })
      assert.are.equal("-", settings.keySeparator)
      assert.are.equal(":", settings.namespaceSeparator)
      assert.are.same({ "ja" }, settings.primaryLanguages)
      assert.are.same({ "**/locales/*.json" }, settings.translationFiles.includePatterns)
      assert.are.same({ "**/node_modules/**" }, settings.translationFiles.excludePatterns)
      assert.are.same({ "**/*.{ts,tsx}" }, settings.includePatterns)
      assert.are.same({ "node_modules/**" }, settings.excludePatterns)
      assert.are.equal(false, settings.diagnostics.missingTranslation.enabled)
      assert.are.equal("error", settings.diagnostics.missingTranslation.severity)
      assert.are.same({ "en", "ja" }, settings.diagnostics.missingTranslation.requiredLanguages)
      assert.are.equal(true, settings.diagnostics.unusedTranslation.enabled)
      assert.are.equal("hint", settings.diagnostics.unusedTranslation.severity)
      assert.are.same({ "debug.*" }, settings.diagnostics.unusedTranslation.ignorePatterns)
      assert.are.equal(4, settings.indexing.numThreads)
    end)

    it("should omit nil fields", function()
      local settings = config.build_server_settings({
        cmd = { "js-i18n-language-server" },
      })
      assert.is_nil(settings.keySeparator)
      assert.is_nil(settings.translationFiles)
      assert.is_nil(settings.primaryLanguages)
      assert.is_nil(settings.includePatterns)
      assert.is_nil(settings.excludePatterns)
      assert.is_nil(settings.diagnostics)
    end)
  end)
end)
