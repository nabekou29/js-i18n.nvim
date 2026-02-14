local utils = require("js-i18n.utils")

describe("js-i18n.utils", function()
  describe("utf_truncate", function()
    -- stylua: ignore start
    local tests = {
      { str = "abcde",      max = 5, ellipsis = "",    expected = "abcde" },
      { str = "abcde",      max = 5, ellipsis = "…",   expected = "abcde" },
      { str = "abcdef",     max = 5, ellipsis = "…",   expected = "abcd…" },
      { str = "abcdef",     max = 5, ellipsis = "...", expected = "ab..." },
      { str = "あいうえお", max = 5, ellipsis = "",    expected = "あいうえお" },
      { str = "あいうえお", max = 5, ellipsis = "…",   expected = "あいうえお" },
      { str = "あいうえお", max = 3, ellipsis = "…",   expected = "あい…" },
      { str = "あいうえお", max = 3, ellipsis = "...", expected = "..." },
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

  describe("parse_version", function()
    it("should parse a valid semver string", function()
      local v = utils.parse_version("1.2.3")
      assert.are.same({ major = 1, minor = 2, patch = 3 }, v)
    end)

    it("should parse version with leading zeros", function()
      local v = utils.parse_version("0.4.0")
      assert.are.same({ major = 0, minor = 4, patch = 0 }, v)
    end)

    it("should ignore pre-release suffix", function()
      local v = utils.parse_version("1.2.3-beta.1")
      assert.are.same({ major = 1, minor = 2, patch = 3 }, v)
    end)

    it("should return nil for invalid version string", function()
      assert.is_nil(utils.parse_version("invalid"))
      assert.is_nil(utils.parse_version("1.2"))
      assert.is_nil(utils.parse_version(""))
    end)
  end)

  describe("compare_versions", function()
    it("should return 0 for equal versions", function()
      assert.are.equal(0, utils.compare_versions("1.2.3", "1.2.3"))
    end)

    it("should return -1 when first version is older", function()
      assert.are.equal(-1, utils.compare_versions("0.3.9", "0.4.0"))
      assert.are.equal(-1, utils.compare_versions("0.4.2", "0.4.3"))
      assert.are.equal(-1, utils.compare_versions("0.4.3", "1.0.0"))
    end)

    it("should return 1 when first version is newer", function()
      assert.are.equal(1, utils.compare_versions("0.4.0", "0.3.9"))
      assert.are.equal(1, utils.compare_versions("1.0.0", "0.9.9"))
    end)

    it("should return 0 for invalid versions", function()
      assert.are.equal(0, utils.compare_versions("invalid", "1.0.0"))
      assert.are.equal(0, utils.compare_versions("1.0.0", "invalid"))
    end)
  end)

  describe("escape_translation_text", function()
    it("should escape newlines", function()
      assert.are.equal("hello\\nworld", utils.escape_translation_text("hello\nworld"))
    end)

    it("should escape tabs", function()
      assert.are.equal("hello\\tworld", utils.escape_translation_text("hello\tworld"))
    end)

    it("should escape carriage returns", function()
      assert.are.equal("hello\\rworld", utils.escape_translation_text("hello\rworld"))
    end)

    it("should escape double quotes", function()
      assert.are.equal('hello\\"world', utils.escape_translation_text('hello"world'))
    end)
  end)
end)
