;; getFixedT 関数呼び出し
(call_expression
  function: [
    (identifier)
    (member_expression)
  ] @get_fixed_t_func (#match? @get_fixed_t_func "getFixedT$")
  ;; 1: lang, 2: ns, 3: keyPrefix
  arguments: (arguments
    (
      [
        (string (string_fragment))
        (undefined)
        (null)
      ]
    )?
    (
      [
        (string (string_fragment) @i18n.namespace)
        (undefined)
        (null)
      ]
    )?
    (
      [
        (string (string_fragment) @i18n.key_prefix)
        (undefined)
        (null)
      ]
    )?
  )
) @i18n.get_t


;; t 関数呼び出し
(call_expression
  function: [
    (identifier)
    (member_expression)
  ] @t_func (#match? @t_func "^(i18next\.)?t$")
  arguments: (arguments
    (string
      (string_fragment) @i18n.key
    ) @i18n.key_arg
  )
) @i18n.call_t
