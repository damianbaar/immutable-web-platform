# this is a tiny helper to escape values from ini to toml format
{lib}:
file:
let
  credentials = builtins.readFile file;
  stringArr = lib.splitString "\n" credentials;

  escapeValue = y:
    let
      name = lib.lists.head y;
      value = lib.lists.last y;
    in
      ''${name}="${value}"'';

  convertTitle = y:
    (lib.strings.concatStringsSep "." 
      (lib.strings.splitString " " y));

  breakValues = x:
    let
      values = lib.splitString " = " x;
      isTitle = lib.hasPrefix "[" x;
    in
      if (lib.length values) > 1 
        then (escapeValue values)
      else if(isTitle)
        then (convertTitle x)
        else x;

  escaped = lib.concatStrings (lib.intersperse "\n" (builtins.map breakValues stringArr));
in 
  fromTOML escaped