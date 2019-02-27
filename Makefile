all: \
	.targets/hosts
	.targets/brew-commands
	.targets/brew-apps

.targets/hosts: .targets/brew
	git clone git@github.com:StevenBlack/hosts.git ~/src
	pip3 install lxml bs4
	cd ~/src/hosts && python3 updateHostsFile.py --auto --replace --extensions gambling porn fakenews social

.targets/brew-commands: brew-commands.dat | .targets
	xargs brew install <$<

.targets/brew-apps: brew-apps.dat | .targets
	xargs brew cask install <$<

.targets:
        mkdir .targets
