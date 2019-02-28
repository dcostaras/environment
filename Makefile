all: \
	.targets/hosts \
	.targets/brew-commands \
	.targets/brew-apps \
	.targets/spacemacs

.targets/c-headers:
	sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
	touch $@

.targets/fonts:
	brew tap caskroom/fonts && brew cask install font-source-code-pro
	touch $@

.targets/spacemacs: .targets/emacs-app .targets/fonts
	git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
	cd ~/.emacs.d && git checkout develop
	touch $@

.targets/emacs-app: .targets/brew-commands .targets/c-headers
	echo 'export PATH="/usr/local/opt/texinfo/bin:$$PATH"' >> ~/.bash_profile
	git clone git://git.savannah.gnu.org/emacs.git ~/src/emacs
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
	xargs brew install <$<
	touch $@

.targets/brew-apps: brew-apps.dat | .targets
	xargs brew cask install <$<
	touch $@

.targets:
	mkdir .targets
