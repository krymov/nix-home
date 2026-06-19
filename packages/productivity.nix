# Productivity and personal tools.
{ pkgs }:

with pkgs; [
  # Task & time management
  taskwarrior3
  timewarrior
  gcalcli

  # Finance
  beancount
  fava
  beanquery
  bean-add
  beanprice

  # Documentation
  pandoc
  hugo
  typst
  glow               # markdown previewer

  # Email (accounts/config managed in .dotfiles, not here)
  aerc
  himalaya           # pimalaya email CLI

  # Cooking
  cook-cli

  # Other
  basalt
]
