;; useTranslation 関数呼び出し
(
  (call_expression
    function: (identifier) @use_translation
    arguments: (arguments
      (string (string_fragment) @i18n.namespace)
      (object
        (pair
          key: (property_identifier) @key_prefix_key (#eq? @key_prefix_key "keyPrefix")
          value: (string (string_fragment) @i18n.key_prefix)
        )?
      )?
    )
  ) @i18n.get_t
  (#eq? @use_translation "useTranslation")
)

;; t 関数呼び出し
  (call_expression
    function: [
      (identifier)
      (member_expression)
    ] @t_func (#match? @t_func "^(i18next\.)?t$")
    arguments: (arguments
      (string
        (string_fragment) @i18n.key
      )
    )
  ) @i18n.call_t
