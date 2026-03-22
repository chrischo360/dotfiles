-- Plugin: Pendulum
-- Description: Timer plugin for coding practice and competitive programming. Track time spent coding with pause/resume.
-- Commands: :TimerStart, :TimerPause, :TimerResume, :TimerStop, :TimerRestart, :TimerTemplate

return {
  "SunnyTamang/pendulum.nvim",
  cmd = {
    "TimerStart",
    "TimerPause",
    "TimerResume",
    "TimerStop",
    "TimerRestart",
    "TimerTemplate",
    "StartYourCustomTimer",
  },
  opts = {
    lualine = false, -- Set to true to display timer in lualine
  },
}
