     │ Fix Alt/Option Keys for Harpoon                                     │
     │                                                                     │
     │ Problem: Alt+hjkl keys aren't working because Terminal.app isn't    │
     │ sending Meta key sequences, and tmux needs configuration.           │
     │                                                                     │
     │ Solution: Option A - Fix Terminal + Tmux (Recommended)              │
     │                                                                     │
     │ Phase 1: Configure Terminal.app                                     │
     │                                                                     │
     │ 1. Open Terminal.app → Preferences → Profiles → Keyboard            │
     │ 2. Enable "Use Option as Meta key"                                  │
     │ 3. Restart terminal or open new window                              │
     │                                                                     │
     │ Phase 2: Update .tmux.conf                                          │
     │                                                                     │
     │ Add these settings to properly handle escape sequences:             │
     │ set -sg escape-time 10      # Faster key recognition                │
     │ set -g xterm-keys on        # Pass through modifier keys            │
     │                                                                     │
     │ Phase 3: Test Alt Keys                                              │
     │                                                                     │
     │ 1. Restart tmux session                                             │
     │ 2. Open nvim and test <M-h> navigation                              │
     │ 3. Verify all Alt+hjkl keys work                                    │
     │                                                                     │
     │ Alternative if you prefer: I can also implement Option B (change to │
     │ <leader>1-4 keys instead) or Option C (hybrid approach) - just let  │
     │ me know!                                                            │
