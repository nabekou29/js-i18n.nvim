;; useTranslation 関数呼び出し
(variable_declarator
  name: (object_pattern
    [
      (pair_pattern
        key: (property_identifier) @use_translation_t (#eq? @use_translation_t "t")
        value: (identifier) @i18n.t_func_name
      )
      (shorthand_property_identifier_pattern) @i18n.t_func_name
    ]
    )
  value:
    (call_expression
      function: (identifier) @use_translation (#eq? @use_translation "useTranslation")
      arguments: (arguments
        [
          (string (string_fragment) @i18n.namespace)
          (array)
          (undefined)
        ]?
        (object
          (pair
            key: (property_identifier) @key_prefix_key (#eq? @key_prefix_key "keyPrefix")
            value: (string (string_fragment) @i18n.key_prefix)
          )?
        )?
      )
    )
) @i18n.get_t

;; Translation コンポーネント
(jsx_element
  open_tag: (jsx_opening_element
    name: (identifier) @translation (#eq? @translation "Translation")
    attribute: (jsx_attribute
      (property_identifier) @key_prefix_attr (#eq? @key_prefix_attr "keyPrefix")
      [
        (string (string_fragment) @i18n.key_prefix) @i18n.key_prefix_arg
        (jsx_expression
          (string (string_fragment) @i18n.key_prefix) @i18n.key_prefix_arg
        )
      ]
    )?
  )
  (jsx_expression
    [
      (arrow_function
        parameters: (formal_parameters (_) @i18n.t_func_name)
      )
      (function_expression
        parameters: (formal_parameters (_) @i18n.t_func_name)
      )
    ]
  )
) @i18n.get_t

;; Trans コンポーネント
(
  jsx_self_closing_element
    name: (identifier) @trans (#eq? @trans "Trans")
    attribute: (jsx_attribute
      (property_identifier) @i18n_key (#eq? @i18n_key "i18nKey")
      [
       (string (string_fragment) @i18n.key) @i18n.key_arg
       (jsx_expression
         (string (string_fragment) @i18n.key) @i18n.key_arg
       )
      ]
    )
    attribute: (jsx_attribute
      (property_identifier) @attr_t (#eq? @attr_t "t")
      (jsx_expression
        (identifier) @i18n.t_func_name
      )
    ) 
) @i18n.call_t
(
  jsx_opening_element
    name: (identifier) @trans (#eq? @trans "Trans")
    attribute: (jsx_attribute
      (property_identifier) @i18n_key (#eq? @i18n_key "i18nKey")
      [
       (string (string_fragment) @i18n.key) @i18n.key_arg
       (jsx_expression
         (string (string_fragment) @i18n.key) @i18n.key_arg
       )
      ]
    )
    attribute: (jsx_attribute
      (property_identifier) @attr_t (#eq? @attr_t "t")
      (jsx_expression
        (identifier) @i18n.t_func_name
      )
    ) 
) @i18n.call_t
