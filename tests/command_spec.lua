local helper = require("tests.helper")

describe("Commands", function()
  local i18n

  setup(function()
    helper.setup()
  end)

  teardown(function()
    helper.teardown()
  end)

  before_each(function()
    helper.clean_plugin()
    i18n = require("js-i18n")
  end)

  describe("I18nSetLang", function()
    --- @type test.Project
    local project = nil
    before_each(function()
      project = helper.use_project("i18next")
      vim.cmd("e " .. project.path .. "/index.js")
    end)

    after_each(function()
      vim.cmd("bd!")
    end)

    it("should set the language passed as an argument", function()
      -- Act
      vim.cmd("I18nSetLang ja")

      -- Assert
      assert.are.equal("ja", i18n.client.current_language)
    end)

    it("should interactively set the language if no argument is specified", function()
      -- Arrange
      local select = stub(_G._test_async_ui, "select", "ja")

      -- Act
      vim.cmd("I18nSetLang")

      -- Assert
      assert.stub(select).called(1)
      assert.are.equal("ja", i18n.client.current_language)
    end)
  end)

  describe("I18nEditTranslation", function()
    --- @type test.Project
    local project = nil
    before_each(function()
      project = helper.use_project("i18next")
      vim.cmd("e " .. project.path .. "/index.js")
    end)

    after_each(function()
      vim.cmd("bd!")
    end)

    -- stylua: ignore start
    local tests = {
      { t_func = "t",         key = "exists-key",   cursor = { 1, 3 },  input = "new_trans", expected = { ["exists-key"] = "new_trans" } },
      { t_func = "t",         key = "new-key",      cursor = { 1, 3 },  input = "new_trans", expected = { ["new-key"] = "new_trans" } },
      { t_func = "t",         key = "nested.key",   cursor = { 1, 3 },  input = "new_trans", expected = { ["nested"] = { ["key"] = "new_trans" } } },
      { t_func = "t",         key = "special-char", cursor = { 1, 3 },  input = " -'\\\"\n", expected = { ["special-char"] = " -'\"\n" } },
      { t_func = "i18next.t", key = "exists-key",   cursor = { 1, 10 }, input = "new_trans", expected = { ["exists-key"] = "new_trans" } },
    }
    -- stylua: ignore end

    for _, test in ipairs(tests) do
      local word = test.t_func .. '("' .. test.key .. '")'

      it("should be able to edit the translation (" .. word .. ")", function()
        -- Arrange
        local input = stub(_G._test_async_ui, "input", test.input)

        local bufnr = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { word })
        vim.api.nvim_win_set_cursor(0, test.cursor)

        -- Act
        vim.cmd("I18nEditTranslation ja")

        -- Assert
        assert.stub(input).called(1)

        local translations =
          vim.fn.json_decode(vim.fn.readfile(project.path .. "/locales/ja/translation.json"))
        assert.are_same(translations, vim.tbl_deep_extend("force", translations, test.expected))
      end)
    end
  end)
end)
