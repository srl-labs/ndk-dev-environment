name: "{{ getenv "APPNAME" }}" # agent's name
arch: "amd64" # architecture you are using
version: "v0.1.0" # version of this rpm package
maintainer: "John Doe <john@doe.com>"
description: "{{ getenv "APPNAME" }} NDK agent" # description of a package
vendor: "JD Corp" # optional information about the creator of the package
license: "BSD-3-Clause"
contents: # contents to add to the package
  - src: "./{{ getenv "APPNAME" }}/"    # local path of agent Python source
    dst: "/opt/{{ getenv "APPNAME" }}/" # destination path of agent sources

  - src: "./{{ getenv "APPNAME" }}.yml" # local path of agent yml
    dst: "/etc/opt/srlinux/appmgr/{{ getenv "APPNAME" }}.yml" # destination path of agent yml
