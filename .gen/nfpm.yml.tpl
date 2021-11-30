name: "{{ndkappname}}" # name of the go package
arch: "amd64" # architecture you are using
version: "v0.1.0" # version of this rpm package
maintainer: "John Doe <john@doe.com>"
description: "{{ndkappname}} NDK agent" # description of a package
vendor: "JD Corp" # optional information about the creator of the package
license: "BSD-3-Clause"
contents: # contents to add to the package
  - src: "./build/{{ndkappname}}" # local path of agent binary
    dst: "/usr/local/bin/{{ndkappname}}" # destination path of agent binary

  - src: "./yang" # local path of agent's YANG directory
    dst: "/opt/{{ndkappname}}/yang" # destination path of agent YANG

  - src: "./{{ndkappname}}.yml" # local path of agent yml
    dst: "/etc/opt/srlinux/appmgr/" # destination path of agent yml
