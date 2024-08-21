Output screenshot.mp4

Require nvim

Set Shell zsh
Set FontSize 16
Set Width 1200
Set Height 600
Set Padding 8
Set TypingSpeed 0.2

Type@0 "nvim -u config.lua projects/i18next/screenshot.js" Enter

Sleep 5 # load lazy.nvim
# Type q # lazy.nvim がエラーになるので閉じる

Type@0 ":set cmdheight=0" Enter


Type@0 ":e projects/i18next/screenshot.js" Enter
Sleep 1

Screenshot i18next-screenshot.png

Type@0 ":e projects/next-intl/screenshot.js" Enter
Sleep 1

Screenshot next-intl-screenshot.png

Sleep 1

Type ":q!" Enter
