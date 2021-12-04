# {{ getenv "APPNAME" }} agent configuration file
# for a complete list of parameters check https://learn.srlinux.dev/ndk/guide/agent/#configuration-file
{{ getenv "APPNAME" }}:
  path: /usr/local/bin
  launch-command: /usr/local/bin/{{ getenv "APPNAME" }}
  yang-modules:
    names: ["{{ getenv "APPNAME" }}"]
    source-directories:
      - "/opt/{{ getenv "APPNAME" }}/yang"
