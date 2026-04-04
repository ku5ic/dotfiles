-- Pull in the wezterm API
local wezterm = require("wezterm")

-- Font configuration
local font = wezterm.font("FiraCode Nerd Font Propo", {
	weight = 450,
	stretch = "Normal",
	style = "Normal",
})

-- Window padding configuration
local window_padding = {
	left = 20,
	right = 20,
	top = 20,
	bottom = 0,
}

-- Keybindings configuration
local keys = {
	{
		key = "v",
		mods = "CTRL|SHIFT",
		action = wezterm.action.DisableDefaultAssignment,
	},
}

return {
	term = "xterm-256color",
	color_scheme = "Catppuccin Mocha",
	font = font,
	freetype_load_target = "Light",
	freetype_render_target = "HorizontalLcd",
	font_size = 14,
	front_end = "WebGpu",
	initial_rows = 33,
	initial_cols = 100,
	window_padding = window_padding,
	window_decorations = "INTEGRATED_BUTTONS",
	native_macos_fullscreen_mode = true,
	window_background_opacity = 0.95,
	use_fancy_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,
	enable_scroll_bar = false,
	selection_word_boundary = " \t\n{}[]()\"'`,;:@│",
	audible_bell = "Disabled",
	keys = keys,
}
