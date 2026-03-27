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

  # Cooking
  cook-cli

  # Other
  basalt
]
