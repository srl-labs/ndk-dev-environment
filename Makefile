APPNAME = demo-app

LABFILE = dev.clab.yml
BIN_DIR = $$(pwd)/build
BINARY = $$(pwd)/build/$(APPNAME)

# abs path of a dir that hosts makefile
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# when make is called with `make cleanup=1 some-target` the CLEANUP var will be set to `--cleanup`
# this is used in clab destroy commands to remove the clab-dev lab directory 
CLEANUP=
ifdef cleanup
	CLEANUP := --cleanup
endif

init:
	mkdir -p yang logs build lab app

	sed 's/{{ndkappname}}/${APPNAME}/g' ./.gen/agent-config.yml.tpl > ${APPNAME}.yml
	sed 's/{{ndkappname}}/${APPNAME}/g' ./.gen/agent.yang.tpl > yang/${APPNAME}.yang
	sed 's/{{ndkappname}}/${APPNAME}/g' ./.gen/dev.clab.yml.tpl > lab/dev.clab.yml
	sed 's/{{ndkappname}}/${APPNAME}/g' ./.gen/nfpm.yml.tpl > nfpm.yml
	
	sed 's/{{ndkappname}}/${APPNAME}/g' ./.gen/go.mod.tpl > go.mod
	sed 's/{{ndkappname}}/${APPNAME}/g' ./.gen/main.go.tpl > main.go

	sed -i 's/demo-app/${APPNAME}/g' Makefile

	cp .gen/.gitignore .

	go mod tidy

build-app:
	mkdir -p $(BIN_DIR)
	go build -o $(BINARY) -ldflags="-s -w" main.go

destroy-lab:
	cd lab; \
	clab des -t $(LABFILE) $(CLEANUP); \
	rm -f .*.clab.* \
	rm -rf ../logs/*

deploy-lab:
	mkdir -p logs/srl1
	cd lab; \
	clab dep -t $(LABFILE)

redeploy-lab: destroy-lab deploy-lab create-app-symlink

redeploy-all: build-app redeploy-lab create-app-symlink

# build an app and restart app_mgr without redeploying the lab
build-restart: build-app restart-app

show-app-status:
	cd lab; \
	clab exec -t $(LABFILE) --label clab-node-name=srl1 --cmd 'sr_cli "show system application $(APPNAME)"'

reload-app_mgr:
	cd lab; \
	clab exec -t $(LABFILE) --label clab-node-name=srl1 --cmd 'sr_cli "tools system app-management application app_mgr reload"'

restart-app:
	cd lab; \
	clab exec -t $(LABFILE) --label clab-node-name=srl1 --cmd 'sr_cli "tools system app-management application $(APPNAME) restart"'

create-app-symlink:
	cd lab; \
	clab exec -t $(LABFILE) --label clab-node-name=srl1 --cmd 'sudo ln -s /tmp/build/$(APPNAME) /usr/local/bin/$(APPNAME)'

compress-bin:
	rm -f build/compressed
	docker run --rm -w /stage -v $$(pwd):/stage gruebel/upx:latest --best --lzma -o build/compressed build/$(APPNAME)
	mv build/compressed build/$(APPNAME)

rpm:
	docker run --rm -v $$(pwd):/tmp -w /tmp goreleaser/nfpm package \
	--config /tmp/nfpm.yml \
	--target /tmp/build \
	--packager rpm

clean: destroy-lab remove-files .gitignore

remove-files:
	rm -rf logs build app lab yang *.yml *.go go.mod go.sum .gitignore

# create dev .gitignore
.ONESHELL:
.gitignore:
	cat <<- EOF > $@
	/*
	!.gitignore
	!.gen
	!LICENSE
	!Makefile
	!README.md
	EOF
