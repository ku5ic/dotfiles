local wezterm = require("wezterm")
local act = wezterm.action

-- Font: primary with italic fallback
-- Victor Mono gives real cursive italics for comments and semantic tokens.
-- Remove the fallback entry if you prefer to stick with oblique FiraCode italics.
local font = wezterm.font_with_fallback({
	{
		family = "FiraCode Nerd Font Propo",
		weight = 450,
		stretch = "Normal",
		style = "Normal",
	},
	{
		family = "Victor Mono",
		weight = "Medium",
		style = "Italic",
	},
})

local keys = {
	-- Ctrl+Shift+V: disabled (conflicts with Neovim paste)
	{ key = "v", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment },

	-- Cmd+T: new tab
	{ key = "t", mods = "SUPER", action = act.SpawnTab("CurrentPaneDomain") },
	-- Cmd+W: close current tab
	{ key = "w", mods = "SUPER", action = act.CloseCurrentTab({ confirm = false }) },
	-- Cmd+Shift+[: previous tab
	{ key = "[", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(-1) },
	-- Cmd+Shift+]: next tab
	{ key = "]", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(1) },

	-- Cmd+D: split pane left/right
	{ key = "d", mods = "SUPER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	-- Cmd+Shift+D: split pane top/bottom
	{ key = "d", mods = "SUPER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Cmd+Ctrl+H: focus pane left
	{ key = "h", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Left") },
	-- Cmd+Ctrl+L: focus pane right
	{ key = "l", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Right") },
	-- Cmd+Ctrl+K: focus pane up
	{ key = "k", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Up") },
	-- Cmd+Ctrl+J: focus pane down
	{ key = "j", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Down") },
	-- Cmd+Shift+Z: toggle zoom (maximize/restore current pane)
	{ key = "z", mods = "SUPER|SHIFT", action = act.TogglePaneZoomState },

	-- Cmd+Shift+Enter: enter copy mode (vi-style text selection)
	{ key = "Enter", mods = "SUPER|SHIFT", action = act.ActivateCopyMode },
}

return {
	-- Use WezTerm's own terminfo for full feature support:
	-- true color, undercurl, extended mouse, kitty graphics protocol.
	term = "wezterm",

	color_scheme = "Catppuccin Mocha",
	font = font,
	font_size = 14,

	-- On HiDPI/Retina, skip freetype hints entirely.
	-- The display handles antialiasing at this density.
	-- If you are on a non-Retina screen, try:
	--   freetype_load_target = "Light",
	--   freetype_render_target = "HorizontalLcd",

	front_end = "WebGpu",

	initial_rows = 33,
	initial_cols = 100,

	window_padding = {
		left = 20,
		right = 20,
		top = 20,
		bottom = 0,
	},

	window_decorations = "INTEGRATED_BUTTONS",
	native_macos_fullscreen_mode = true,

	-- Solid background. At 0.95 without blur you mostly see whatever app
	-- is behind the terminal, which adds noise. Use one of:
	--   1. opacity = 1.0, no blur (clean, sharp)
	--   2. opacity = 0.92 + blur = 20 (frosted glass effect)
	window_background_opacity = 1.0,
	-- macos_window_background_blur = 20,  -- uncomment for frosted glass

	use_fancy_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,
	enable_scroll_bar = false,

	-- Undercurl support for Neovim diagnostics
	-- Requires term = "wezterm"
	underline_thickness = "200%",
	cursor_thickness = "200%",

	selection_word_boundary = " \t\n{}[]()\"'`,;:@|",

	audible_bell = "Disabled",

	-- Reduce latency. WebGpu should handle this fine.
	max_fps = 120,

	keys = keys,
}
