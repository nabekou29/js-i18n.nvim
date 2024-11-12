Output js-i18n.mp4

Require nvim

Set Shell zsh
Set FontSize 16
Set Width 1200
Set Height 600
Set Padding 8
Set TypingSpeed 0.2

Hide

Type@0 "nvim -u config.lua projects/i18next/concept.jsx" Enter

Sleep 10 # load lazy.nvim
# Type q # lazy.nvim がエラーになるので閉じる

Sleep 1

Show

Sleep 2.5

Type ":8" Enter Sleep 0.5
Type "14l" Sleep 0.5
Ctrl+k

Type ":I18nSetLang ja" Sleep 0.5 Enter
Sleep 2
Type ":I18nSetLang en" Sleep 0.5 Enter
Sleep 3
Ctrl+k

Type "jK"
Sleep 2.5
Ctrl+k

Type "o" Sleep 0.5
Tab
Type "<p>" Sleep 0.5
Type '{t("' Sleep 0.5
Type 'd' Sleep 0.5
Down@0.5 3
Enter
Sleep 3

Hide

Type ":q!" Enter
