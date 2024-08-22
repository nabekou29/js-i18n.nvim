;; useTranslations 関数呼び出し
(call_expression
  function: (identifier) @use_translations (#eq? @use_translations "useTranslations")
  arguments: (arguments
    [
      (string (string_fragment) @i18n.key_prefix)
      (undefined)
    ]?
  )
) @i18n.get_t

;; t 関数呼び出し
(call_expression
  function: [
    (identifier)
    (member_expression)
  ] @t_func (#match? @t_func "^t(\.rich|\.markup|\.raw)?$")
  arguments: (arguments
    (string
      (string_fragment) @i18n.key
    ) @i18n.key_arg
  )
) @i18n.call_t
