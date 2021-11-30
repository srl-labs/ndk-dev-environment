# {{ndkappname}} agent configuration file
{{ndkappname}}:
  path: /usr/local/bin
  launch-command: /usr/local/bin/{{ndkappname}}
  yang-modules:
    names: ["{{ndkappname}}"]
    source-directories:
      - "/opt/{{ndkappname}}/yang"
