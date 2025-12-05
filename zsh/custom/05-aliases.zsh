# Aliases

# Alacritty theme picker
alias at="$HOME/dotfiles/alacritty/scripts/alacritty-theme-picker.sh"

# CodeForces - Find Next Problem
alias cfnext="(cd $HOME/codebase/codeforces && cargo run -p tools --bin next-unsolved)"
alias cfnext800="cargo run --bin next-unsolved -- --level 800"
alias cfnext1200="cargo run --bin next-unsolved -- --level 1200"

# CodeForces - Progress Tracking
alias cfadd="(cd $HOME/codebase/codeforces/training && cargo run -- add)"
alias cfshow="(cd $HOME/codebase/codeforces/training && cargo run -- show)"
