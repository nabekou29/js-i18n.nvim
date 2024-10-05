local helper = require("tests.helper")

local analyzer = require("js-i18n.analyzer")

--- test helper

--- @param get_project function(): test.Project
--- @param file string
--- @param assertion function(result: FindTExpressionResultItem[], utils: table)
local function test_analyze_file(get_project, file, assertion)
  it("should find 't' function calls in " .. file, function()
    -- Arrange
    local project = get_project()
    vim.cmd("e " .. project.path .. "/test_analyzer/" .. file)

    -- Act
    local result = analyzer.find_call_t_expressions(0)

    local assert_item = function(idx, exp)
      local item = result[idx]

      local function assert_key_value(key)
        -- stylua: ignore start
        assert(
          exp[key] == item[key],
          string.format("result[%d].%s to be equal.\nPassed:\n(%s) %s\nExpected:\n(%s) %s",
            idx, key, type(item[key]), item[key], type(exp[key]), exp[key])
        )
        -- stylua: ignore end
      end
      assert_key_value("key")
      assert_key_value("key_prefix")
      assert_key_value("key_arg")
    end

    local assert_items = function(exp_list)
      assert.are.equal(#exp_list, #result)
      for idx, exp in ipairs(exp_list) do
        assert_item(idx, exp)
      end
    end

    -- Assert
    assertion(result, {
      assert_item = assert_item,
      assert_items = assert_items,
    })
  end)
end

--- @param get_project function(): test.Project
--- @param text string
--- @param expected boolean
local function test_find_t_call(get_project, text, expected)
  local assertion = expected and "should" or "should NOT"
  it(assertion .. " find 't' function calls in `" .. text .. "`", function()
    -- Arrange
    local project = get_project()
    vim.cmd("e " .. project.path .. "/index.js")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(text, "\n"))

    -- Act
    local result = analyzer.find_call_t_expressions(0)

    -- Assert
    assert.are.equal(expected and 1 or 0, #result)
  end)
end

describe("analyzer.find_call_t_expressions", function()
  describe("when using 'i18next'", function()
    --- @type test.Project
    local project = nil
    before_each(function()
      project = helper.use_project("i18next")
    end)

    after_each(function()
      vim.cmd("bufdo bd!")
    end)

    local function get_project()
      return project
    end

    -- Each file types
    test_analyze_file(get_project, "lang_javascript.js", function(_, utils)
      utils.assert_items({
        { key = "key", key_prefix = "", key_arg = "key" },
      })
    end)
    test_analyze_file(get_project, "lang_typescript.ts", function(_, utils)
      utils.assert_items({
        { key = "key", key_prefix = "", key_arg = "key" },
      })
    end)
    test_analyze_file(get_project, "lang_jsx.jsx", function(_, utils)
      utils.assert_items({
        { key = "key", key_prefix = "", key_arg = "key" },
      })
    end)
    test_analyze_file(get_project, "lang_tsx.tsx", function(_, utils)
      utils.assert_items({
        { key = "key", key_prefix = "", key_arg = "key" },
      })
    end)

    test_analyze_file(get_project, "key_prefix.js", function(_, utils)
      -- see: tests/projects/i18next/test_analyzer/key_prefix.js
      utils.assert_items({
        -- stylua: ignore start
        { key = "no-prefix-key-1",         key_prefix = "",         key_arg = "no-prefix-key-1" },
        { key = "prefix-1.prefix-1-key-1", key_prefix = "prefix-1", key_arg = "prefix-1-key-1" },
        { key = "prefix-2.prefix-2-key-1", key_prefix = "prefix-2", key_arg = "prefix-2-key-1" },
        { key = "prefix-1.prefix-1-key-2", key_prefix = "prefix-1", key_arg = "prefix-1-key-2" },
        { key = "no-prefix-key-2",         key_prefix = "",         key_arg = "no-prefix-key-2" },
        -- stylua: ignore end
      })
    end)

    test_analyze_file(get_project, "key_prefix.jsx", function(_, utils)
      -- see: tests/projects/i18next/test_analyzer/key_prefix.jsx
      utils.assert_items({
        -- stylua: ignore start
        { key = "no-prefix-key-1",                 key_prefix = "",             key_arg = "no-prefix-key-1" },
        { key = "prefix-1.prefix-1-key-1",         key_prefix = "prefix-1",     key_arg = "prefix-1-key-1" },
        { key = "no-prefix-key-2",                 key_prefix = "",             key_arg = "no-prefix-key-2" },
        { key = "prefix-2.prefix-2-key-1",         key_prefix = "prefix-2",     key_arg = "prefix-2-key-1" },
        { key = "prefix-1.prefix-1-key-2",         key_prefix = "prefix-1",     key_arg = "prefix-1-key-2" },
        { key = "tsl-prefix-1.tsl-prefix-1-key-1", key_prefix = "tsl-prefix-1", key_arg = "tsl-prefix-1-key-1" },
        -- stylua: ignore end
      })
    end)

    -- These should be found
    local tests = {
      { text = "t('key')" },
      { text = "t('key', { count: 1 })" },
      { text = "i18next.t('key')" },
      { text = "t(\n'key'\n)" },
      { text = "<Trans i18nKey='key' t={t} />" },
      { text = "<Trans i18nKey={'key'} t={t} />" },
      { text = "<Trans i18nKey={'key'} t={t}></Trans>" },
    }

    for _, test in ipairs(tests) do
      test_find_t_call(get_project, test.text, true)
    end

    -- These should not be found
    local tests = {
      { text = "t(variable)" },
      { text = "tt('key')" },
      { text = "<Trans i18nKey='does.not.hove.t-attr' />" },
      { text = "<Trans i18nKey={variable} t={t} />" },
    }
    for _, test in ipairs(tests) do
      test_find_t_call(get_project, test.text, false)
    end

    it("should find \"t\" function calls in \"t('key1', { value: t('key2') })\"", function()
      -- Arrange
      vim.cmd("e " .. project.path .. "/index.js")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "t('key1', { value: t('key2') })" })

      -- Act
      local result = analyzer.find_call_t_expressions(0)

      -- Assert
      assert.are.equal(2, #result)
      assert.are.same("key1", result[1].key)
      assert.are.same("key2", result[2].key)
    end)
  end)

  describe("when using 'next-intl'", function()
    --- @type test.Project
    local project = nil
    before_each(function()
      project = helper.use_project("next-intl")
    end)

    after_each(function()
      vim.cmd("bufdo bd!")
    end)

    local function get_project()
      return project
    end

    -- Each file types
    test_analyze_file(get_project, "lang_jsx.jsx", function(_, utils)
      utils.assert_items({
        { key = "key", key_prefix = "", key_arg = "key" },
      })
    end)
    test_analyze_file(get_project, "lang_tsx.tsx", function(_, utils)
      utils.assert_items({
        { key = "key", key_prefix = "", key_arg = "key" },
      })
    end)

    test_analyze_file(get_project, "key_prefix.jsx", function(_, utils)
      -- see: tests/projects/next-intl/test_analyzer/key_prefix.jsx
      utils.assert_items({
        -- stylua: ignore start
        { key = "no-prefix-key-1",         key_prefix = "",          key_arg = "no-prefix-key-1" },
        { key = "prefix-1.prefix-1-key-1", key_prefix = "prefix-1",  key_arg = "prefix-1-key-1" },
        { key = "no-prefix-key-2",         key_prefix = "",          key_arg = "no-prefix-key-2" },
        { key = "prefix-2.prefix-2-key-1", key_prefix = "prefix-2",  key_arg = "prefix-2-key-1" },
        { key = "prefix-1.prefix-1-key-2", key_prefix = "prefix-1",  key_arg = "prefix-1-key-2" },
        -- stylua: ignore end
      })
    end)

    -- These should be found
    local tests = {
      { text = "t('key')" },
      { text = "t('key', { count: 1 })" },
      { text = "t(\n'key'\n)" },
      { text = "t.rich('key', { guidelines: (chunks) => <a href=\"/guidelines\">{chunks}</a> })" },
      { text = "t.markup('markup', { important: (chunks) => `<b>${chunks}</b>` })" },
      { text = "t.raw('key')" },
    }
    for _, test in ipairs(tests) do
      test_find_t_call(get_project, test.text, true)
    end

    -- These should not be found
    local tests = {
      { text = "t(variable)" },
      { text = "t('ke' + 'y')" },
      { text = "t(`key`)" },
      { text = "t.hoge('key')" },
    }
    for _, test in ipairs(tests) do
      test_find_t_call(get_project, test.text, false)
    end
  end)
end)
