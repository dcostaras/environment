define to-file
	printf '%b\n' "$$(cat $1)" > $2
endef

all: \
	.targets/hosts \
	.targets/brew-commands \
	.targets/brew-apps \
	.targets/git \
	.targets/spacemacs \
	.targets/bash \
	.targets/java8 \
	.targets/wireguard \
	| .targets

.targets/c-headers:
	sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
	touch $@

# TODO: install brew rule

.targets/casks/fonts:
	brew tap caskroom/fonts
	touch $@

.targets/fonts: fonts/cask.dat .targets/casks/fonts
	xargs brew cask install <$<
	touch $@

.targets/git: git/
	$(call to-file,git/config,~/.gitconfig)
	touch $@

.targets/spacemacs-src:
	git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d

.targets/spacemacs: .targets/spacemacs-src .targets/emacs-app .targets/fonts
	cd ~/.emacs.d && git checkout develop
	touch $@

.targets/emacs-src:
	git clone git://git.savannah.gnu.org/emacs.git ~/src/emacs
	touch $@

.targets/emacs-app: | .targets/brew-commands .targets/c-headers
	echo 'export PATH="/usr/local/opt/texinfo/bin:$$PATH"' >> ~/.bash_profile
	cd ~/src/emacs && make configure
	cd ~/src/emacs && ./configure --with-ns
	cd ~/src/emacs && make install
	cp -R ~/src/emacs/nextstep/Emacs.app /Applications/Emacs.app
	touch $@

.targets/hosts: | .targets/brew-commands
	git clone git@github.com:StevenBlack/hosts.git ~/src/hosts
	pip3 install lxml bs4
	cd ~/src/hosts && python3 updateHostsFile.py --auto --replace --extensions gambling porn fakenews social
	touch $@

.targets/cellar-cask:
	echo 'export PATH="/usr/local/opt/texinfo/bin:$PATH"' >> ~/.bash_profile

.targets/brew-commands: brew-commands.dat | .targets
	brew update || brew update
	brew upgrade
	xargs brew install <$<
	touch $@

.targets/bash: | .targets/brew-commands
	echo '/usr/local/bin/bash' | sudo tee -a /etc/shells > /dev/null
	chsh -s /usr/local/bin/bash
	touch $@

.targets/java8:
	brew tap caskroom/versions
	brew cask install java8
	touch $@

.targets/brew-apps: brew-apps.dat | .targets
	xargs brew cask install <$<
	touch $@

.targets/wireguard: | .targets/brew-commands
	mkdir -p ~/.config/wireguard
	cd ~/.config/wireguard && wg genkey | tee privatekey | wg pubkey > publickey
	cd ~/.config/wireguard && sudo chmod -R og-rwx ~/.config/wireguard/*
	touch $@

.targets: targets
	xargs mkdir -p <$<
