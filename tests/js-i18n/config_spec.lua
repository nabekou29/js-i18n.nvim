local config = require("js-i18n.config")

describe("js-i18n.config", function()
  describe("setup", function()
    it("should set default config when no options are given", function()
      config.setup({})
      assert.are.equal(true, config.config.virt_text.enabled)
      assert.are.equal(false, config.config.virt_text.conceal_key)
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
      assert.are.equal("**/locales/*.json", opts.server.translation_files.file_pattern)
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
        cmd = { "js-i18n-language-server", "--stdio" },
        key_separator = "-",
        namespace_separator = ":",
        primary_languages = { "ja" },
        translation_files = { file_pattern = "**/locales/*.json" },
        virtual_text = { max_length = 50 },
        diagnostics = { unused_keys = true },
        indexing = { num_threads = 4 },
      })
      assert.are.equal("-", settings.keySeparator)
      assert.are.equal(":", settings.namespaceSeparator)
      assert.are.same({ "ja" }, settings.primaryLanguages)
      assert.are.equal("**/locales/*.json", settings.translationFiles.filePattern)
      assert.are.equal(50, settings.virtualText.maxLength)
      assert.are.equal(true, settings.diagnostics.unusedKeys)
      assert.are.equal(4, settings.indexing.numThreads)
    end)

    it("should omit nil fields", function()
      local settings = config.build_server_settings({
        cmd = { "js-i18n-language-server", "--stdio" },
      })
      assert.is_nil(settings.keySeparator)
      assert.is_nil(settings.translationFiles)
      assert.is_nil(settings.primaryLanguages)
    end)
  end)
end)
