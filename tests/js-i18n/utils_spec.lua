local utils = require("js-i18n.utils")

describe("js-i18n.utils", function()
  describe("utf_truncate", function()
    -- stylua: ignore start
    local tests = {
      { str = "abcde",     max = 5, ellipsis = "",    expected = "abcde" },
      { str = "abcde",     max = 5, ellipsis = "…",   expected = "abcde" },
      { str = "abcdef",    max = 5, ellipsis = "…",   expected = "abcd…" },
      { str = "abcdef",    max = 5, ellipsis = "...", expected = "ab..." },
      { str = "abcあいう", max = 5, ellipsis = "…",   expected = "abcあ…" },
      { str = "abcあいう", max = 6, ellipsis = "…",   expected = "abcあいう" },
    }
    -- stylua: ignore end

    for _, test in ipairs(tests) do
      it(
        string.format(
          "should return %q when truncating %q to %d characters (ellipsis: %q)",
          test.expected,
          test.str,
          test.max,
          test.ellipsis
        ),
        function()
          assert.are.equal(test.expected, utils.utf_truncate(test.str, test.max, test.ellipsis))
        end
      )
    end
  end)

  describe("truncate_display_width", function()
    -- stylua: ignore start
    local tests = {
      { str = "abcde",      max = 5, ellipsis = "",    expected = "abcde" },
      { str = "abcde",      max = 5, ellipsis = "…",   expected = "abcde" },
      { str = "abcdef",     max = 5, ellipsis = "…",   expected = "abcd…" },
      { str = "abcdef",     max = 5, ellipsis = "...", expected = "ab..." },
      { str = "abcあいう",  max = 5, ellipsis = "…",   expected = "abc…" },
      { str = "abcあいう",  max = 6, ellipsis = "…",   expected = "abcあ…" },
      { str = "あいうえお", max = 5, ellipsis = "...", expected = "あ..." },
      { str = "あいうえお", max = 6, ellipsis = "...", expected = "あ..." },
      { str = "あいうえお", max = 7, ellipsis = "...", expected = "あい..." },
    }
    -- stylua: ignore end

    for _, test in ipairs(tests) do
      it(
        string.format(
          "should return %q when truncating %q to %d display width (ellipsis: %q)",
          test.expected,
          test.str,
          test.max,
          test.ellipsis
        ),
        function()
          assert.are.equal(
            test.expected,
            utils.truncate_display_width(test.str, test.max, test.ellipsis)
          )
        end
      )
    end
  end)
end)
