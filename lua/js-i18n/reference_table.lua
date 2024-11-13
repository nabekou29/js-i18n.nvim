--- 翻訳の参照テーブル
--- @class I18n.ReferenceTable
--- @field _ref_table table<string, table<string, FindTExpressionResultItem[]>>
---
local ReferenceTable = {}
ReferenceTable.__index = ReferenceTable

--- @return I18n.ReferenceTable
function ReferenceTable.new()
  local self = setmetatable({}, ReferenceTable)

  self._ref_table = {}
  return self
end
