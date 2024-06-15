My dotfiles

Install chezmoi:
```
export GITHUB_USERNAME=iKadmium
sh -c "$(curl -fsLS get.chezmoi.io/lb)"
chezmoi init https://github.com/$GITHUB_USERNAME/dotfiles.git
```

