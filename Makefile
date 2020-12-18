SHELL := /bin/bash

define to-file
	printf '%b\n' "$$(cat $1)" > $2
endef


all: \
	hosts \
    .targets/brew \
	.targets/git \
	.targets/wireguard \
	gitconfig \
	| .targets

.targets/c-headers:
	sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
	touch $@

gitconfig: ~/.gitconfig
~/.gitconfig: git/config
	$(call to-file,git/config,~/.gitconfig)

# .targets/spacemacs-src:
# 	git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
# 	touch $@

# .targets/spacemacs: .targets/spacemacs-src .targets/emacs-app | .targets/fonts
# 	cd ~/.emacs.d.spacemacs && git checkout develop
# 	touch $@

# .targets/emacs-src:
# 	git clone git://git.savannah.gnu.org/emacs.git ~/src/emacs
# 	touch $@

# .targets/emacs-app: | .targets/brew/commands .targets/c-headers
# 	echo 'export PATH="/usr/local/opt/texinfo/bin:$$PATH"' >> ~/.bash_profile
# 	cd ~/src/emacs && make configure
# 	cd ~/src/emacs && ./configure --with-ns
# 	cd ~/src/emacs && make install
# 	cp -R ~/src/emacs/nextstep/Emacs.app /Applications/Emacs.app
# 	touch $@

# .PHONY: .targets/emacs-init
# .targets/emacs-init: emacs-init/emacs.init.org
# 	emacs --nw --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "$<")'
# 	emacs --batch -l org --eval "(org-babel-tangle-file \"$1\")"
# 	touch $@

hosts: .targets/hosts-update .targets/hosts-install

.targets/hosts-dependencies:
	python3 -m pip install lxml --user
	python3 -m pip install bs4 --user

.targets/hosts-update: .targets/hosts-install .targets/hosts-dependencies
	cd ~/src/hosts && python3 updateHostsFile.py --auto --replace --extensions gambling porn fakenews social

.targets/hosts-install: | .targets/brew/commands
	git clone git@github.com:StevenBlack/hosts.git ~/src/hosts
	pip3 install lxml bs4
	cd ~/src/hosts && python3 updateHostsFile.py --auto --replace --extensions gambling porn fakenews social
	touch $@

# TODO: install brew rule

.targets/cellar-cask:
	echo 'export PATH="/usr/local/opt/texinfo/bin:$PATH"' >> ~/.bash_profile

.targets/brew: \
    .targets/brew/taps \
    .targets/brew/upgrade \
    .targets/brew/fonts \
    .targets/brew/apps

.targets/brew/upgrade:
	brew update || brew update
	brew upgrade
	brew upgrade --cask

.targets/brew/commands: brew/commands.dat .targets/brew/upgrade .targets/brew/taps | .targets
	xargs brew install <$<
	touch $@

.targets/brew/fonts: fonts/cask.dat .targets/brew/upgrade | .targets
	xargs brew cask install <$<
	touch $@

.targets/brew/apps: brew/apps.dat .targets/brew/upgrade | .targets
	xargs brew cask install <$<
	touch $@

.targets/brew/taps: brew/taps.dat .targets/brew/upgrade | .targets
	xargs -0 -n 1 brew tap < <(tr \\n \\0 <$<)
	touch $@

.targets/bash: | .targets/brew/commands
	echo '/usr/local/bin/bash' | sudo tee -a /etc/shells > /dev/null
	chsh -s /usr/local/bin/bash
	touch $@

.targets/wireguard: | .targets/brew-commands
	mkdir -p ~/.config/wireguard
	cd ~/.config/wireguard && wg genkey | tee privatekey | wg pubkey > publickey
	cd ~/.config/wireguard && sudo chmod -R og-rwx ~/.config/wireguard/*
	touch $@

.targets:
	mkdir -p targets/brew
	touch $@
