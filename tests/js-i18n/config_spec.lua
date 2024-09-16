local config = require("js-i18n.config")

describe("js-i18n.config", function()
  describe("default_detect_language", function()
    local tests = {
      { path = "/path/to/locals/en/trans.json", expected = "en" },
      { path = "/path/to/locals/ja/trans.json", expected = "ja" },
      { path = "/path/to/locals/hoge/trans.json", expected = "unknown" },

      -- Test cases to verify that it is sufficient for the languagee name to be included somewhere.
      { path = "/path/to/locals/sub/en.json", expected = "en" },
      { path = "/path/to/en/locals/trans.json", expected = "en" },
      { path = "/path/to/locals/en-trans.json", expected = "unknown" },

      -- Test cases for language names with any case and separating characters.
      { path = "/path/to/locals/en-us/trans.json", expected = "en-us" },
      { path = "/path/to/locals/en_us/trans.json", expected = "en_us" },
      { path = "/path/to/locals/en-US/trans.json", expected = "en-US" },

      -- Test cases where the last match is returned when multiple locale names are included.
      { path = "/path/to/locals/en/ja.json", expected = "ja" },
    }

    for _, test in ipairs(tests) do
      it(
        string.format("should return %q when detecting language from %q", test.expected, test.path),
        function()
          assert.are.equal(test.expected, config.default_detect_language(test.path))
        end
      )
    end
  end)
end)
