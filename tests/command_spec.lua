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
    vim.cmd("Lazy reload js-i18n.nvim")
    i18n = require("js-i18n")
  end)

  describe("I18nSetLang", function()
    local project = nil
    before_each(function()
      project = helper.use_project("i18next")
      -- 適当なファイルを開く
      vim.cmd("e " .. project.path .. "/index.js")
    end)

    after_each(function()
      -- ファイルを閉じる
      vim.cmd("bd!")
    end)

    -- 引数に渡された言語を設定できること
    it("should set the language passed as an argument", function()
      -- Act
      vim.cmd("I18nSetLang ja")

      -- Assert
      assert.are.equal("ja", i18n.client.current_language)
    end)

    -- 引数が未指定の場合はインタラクティブに言語を設定できること
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
      -- 適当なファイルを開く
      vim.cmd("e " .. project.path .. "/index.js")
    end)

    after_each(function()
      -- ファイルを閉じる
      vim.cmd("bd!")
    end)

    -- カーソル位置のキーに対して文言を更新できること
    it("should update the text for the key at the cursor position", function()
      -- Arrange
      local input = stub(_G._test_async_ui, "input", "_new_translation")

      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "t('exists-key')" })
      vim.api.nvim_win_set_cursor(0, { 1, 3 })

      -- Act
      vim.cmd("I18nEditTranslation ja")

      -- Assert
      assert.stub(input).called(1)
      local translations =
        vim.fn.json_decode(vim.fn.readfile(project.path .. "/locales/ja/translation.json"))
      assert.are.equal(translations["exists-key"], "_new_translation")
    end)
  end)
end)
