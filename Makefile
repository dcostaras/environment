define to-file
	printf '%b\n' "$$(cat $1)" > $2
endef

define git-clone
	[ -d $2/.git ] || git clone $1 $2
	(cd $2; git pull $1)
endef

all: \
	.targets/hosts \
        brew \
	.targets/git \
#	.targets/spacemacs \
#	.targets/java8 \
#	.targets/wireguard \
	~/.gitconfig \
	| targets

#.targets/c-headers:
#	sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
#	touch $@

gitconfig: ~/.gitconfig
~/.gitconfig: git/config
	$(call to-file,git/config,$@)

/usr/local/bin/emacs: emacs-init/emacs-executable
	$(call to-file,$<,$@)
	chmod 755 $@

install-doom-emacs:
	git clone https://github.com/hlissner/doom-emacs ~/.emacs.d
	~/.emacs.d/bin/doom install

~/.zshenv: rcs/zsh/zshenv
	$(call to-file,$<,$@)

.targets/doom-config: emacs-init/doom.org
	emacs --batch -l org --eval "(org-babel-tangle-file \"$<\")"

# rclone
~/.config/rclone:
	mkdir -p $@

# TODO op install requirement
~/.config/rclone/rclone.conf: ~/.config/rclone
	op get document olst7uwyzbg4lbb6567u67765i --output ~/.config/rclone/rclone.conf

# Annexes 
define setup-annex
	$(call git-clone,git@gitlab.com:d.costaras/annex-$(if $2,$2,$1).git,~/$1)
	cd ~/$1 && git annex enableremote drive
endef

~/comics:
	$(call setup-annex,comics)

~/books:
	$(call setup-annex,books)

Music:
	cd ~/$@ && rm .DS_Store .localized
	$(call setup-annex,Music,music)

Movies:
	# cd ~/$@ && rm .DS_Store .localized
	$(call git-clone,git@github.com:dcostaras/annex-movies,~/Movies)
	cd ~/Movies && git annex enableremote drive

# Git annex
~/bin/git-annex-remote-rclone: 
	$(call git-clone,git@github.com:dcostaras/git-annex-remote-rclone.git,/tmp/git-annex-remote)
	cp /tmp/git-annex-remote/git-annex-remote-rclone $@

# TODO install arm homebrew
arm-homebrew:
	mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
	# We'll be installing Homebrew in the /opt directory.
	# cd /opt
	# Create a directory for Homebrew. This requires root permissions.
	# sudo mkdir homebrew
	# Make us the owner of the directory so that we no longer require root permissions.
	# sudo chown -R $(whoami) /opt/homebrew
	# Download and unzip Homebrew. This command can be found at https://docs.brew.sh/Installation.
	# curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
	# Add the Homebrew bin directory to the PATH. If you don't use zsh, you'll need to do this yourself.
	# echo "export PATH=/opt/homebrew/bin:$PATH" >> ~/.zshrc

# TODO: install brew rule
# TODO export ssh keys from 1password: github-key
# TODO touchid sudo
# TODO rclone and general config out of 1password

#.targets/emacs: emacs-init/emacs.init.org
#	emacs --nw --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "$<")'
#	emacs --batch -l org --eval "(org-babel-tangle-file \"$<\")"
#	touch $@

.targets/rc-init: rcs/rc.init.org
	emacs --batch -l org --eval "(org-babel-tangle-file \"$<\")"
	touch $@

.targets/hosts-install: | .targets/brew/commands
	$(call git-clone,git@github.com:StevenBlack/hosts.git,~/src/hosts)
	pip3 install requests lxml bs4
	touch $@

.targets/hosts: | .targets/hosts-install
	cd ~/src/hosts && python3 updateHostsFile.py --auto --replace --extensions gambling porn fakenews social

.targets/cellar-cask:
	echo 'export PATH="/usr/local/opt/texinfo/bin:$PATH"' >> ~/.bash_profile

brew: \
    .targets/brew/upgrade \
    .targets/brew/fonts \
    .targets/brew/apps

.targets/brew/upgrade:
	brew update || brew update
	brew upgrade
	brew upgrade --cask
	touch $@

.targets/brew/commands: brew/commands.dat .targets/brew/upgrade | targets
	xargs brew install <$<
	touch $@

.targets/brew/fonts: fonts/cask.dat .targets/brew/upgrade | targets
	brew tap homebrew/cask-fonts
	xargs brew install --cask <$<
	touch $@

.targets/brew/apps: brew/apps.dat .targets/brew/upgrade | targets
	xargs brew install --cask <$<
	touch $@

.targets/bash: | .targets/brew/commands
	echo '/usr/local/bin/bash' | sudo tee -a /etc/shells > /dev/null
	chsh -s /usr/local/bin/bash
	touch $@

.targets/java8: .targets/brew/cask
	brew install --cask java8
	touch $@

.targets/wireguard: | .targets/brew-commands
	mkdir -p ~/.config/wireguard
	cd ~/.config/wireguard && wg genkey | tee privatekey | wg pubkey > publickey
	cd ~/.config/wireguard && sudo chmod -R og-rwx ~/.config/wireguard/*
	touch $@

targets: .targets/brew
.targets/brew:
	mkdir -p $@

~/bin:
	mkdir -p $@
