This repo provides a cookie-cutter experience for setting up a Go-based [NDK](https://learn.srlinux.dev/ndk/intro/) development environment. Read more about the approach at [learn.srlinux.dev](https://learn.srlinux.dev/ndk/guide/env/go/).

## Quickstart
Create an empty directory, change into it and execute:

```
curl -L https://github.com/srl-labs/ndk-dev-environment/archive/refs/heads/go.tar.gz | \
    tar -xz --strip-components=1
```

This command will download the contents of the `go` branch.

Initialize the NDK project providing the desired app name:

```
make APPNAME=my-cool-app
```

Now you have all the components of an NDK app generated.

Build the lab and deploy the demo application:

```
make redeploy-all
```

The app named `my-cool-app` is now running on `srl1` you can explore the log of the app by reading the log file:

```
tail -f logs/srl1/stdout/my-cool-app.log
```

Do modifications to your app and re-build the app with:

```
make build-restart
```

## Atom editor integration
For integration with Atom.io, you can use the [build](https://atom.io/packages/build) package:
1. Follow the instructions to install it:
```
apm install build
```
(you may need to restart Atom afterwards to complete installation)

2. Create a .atom-build.yml file in the top-level of your Atom project directory ( e.g. ~/Projects/ ):
```
cat > .atom-build.yml << EOF
cmd: /usr/bin/make
name: "Redeploy SR Linux NDK Go app"
args:
  - redeploy-all
cwd: "{FILE_ACTIVE_PATH}"
EOF
```

From now on, if you have e.g. your app main.go file open, you can press \<F7\> and it will be launched!
