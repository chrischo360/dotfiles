# Platform-specific shell configuration

case "$(uname -s)" in
  Darwin)
    [[ -d /opt/homebrew/opt/php@8.1/bin ]] && export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"
    [[ -d /opt/homebrew/opt/php@8.1/sbin ]] && export PATH="/opt/homebrew/opt/php@8.1/sbin:$PATH"
    export PATH="$PATH:$HOME/Library/Application Support/Coursier/bin"
    export PATH="$PATH:$HOME/Library/Caches/ScalaCli/local-repo/bin/scala-cli"
    ;;
  Linux)
    ;;
esac
