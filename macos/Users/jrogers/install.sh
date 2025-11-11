/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install bash-completion@2 brew-cask-completion dnscrypt-proxy grc mpv nano nanorc coreutils curl dos2unix gawk git gnu-sed grep htop mtr nmap p7zip parallel pnpm pstree ripgrep wget aspell
sudo chsh -s /opt/homebrew/bin/bash jrogers

osascript -e "
tell application \"Finder\"
  set desktop picture to POSIX file wallpaper.jpg
end tell"

echo "Generating PERSONAL-RANDOM SSH KEY"
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519-personal-random

echo "Generating PERSONAL-GITHUB SSH KEY"
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519-personal-github

echo "Generating WORK-GITHUB SSH KEY"
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519-work-github

