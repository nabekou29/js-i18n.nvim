;; useTranslations 関数呼び出し
(variable_declarator
  name: (identifier) @i18n.t_func_name
  value:
    (call_expression
      function: (identifier) @use_translations (#eq? @use_translations "useTranslations")
      arguments: (arguments
        [
          (string (string_fragment) @i18n.key_prefix)
          (undefined)
        ]?
      )
    )
) @i18n.get_t

;; t 関数呼び出し
(call_expression
  function: [
    (identifier)
    (member_expression)
  ] @i18n.t_func_name
  arguments: (arguments
    (string
      (string_fragment) @i18n.key
    ) @i18n.key_arg
  )
) @i18n.call_t
