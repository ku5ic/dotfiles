local wezterm = require("wezterm")
local act = wezterm.action

-- Font: primary with italic fallback.
-- Victor Mono provides real cursive italics for Neovim comments and semantic tokens.
-- Remove the fallback entry if you prefer oblique FiraCode italics.
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

-- Catppuccin Mocha palette (subset used for tab bar rendering)
local c = {
	mantle = "#181825",
	surface0 = "#313244",
	surface1 = "#45475a",
	text = "#cdd6f4",
	subtext0 = "#a6adc8",
	mauve = "#cba6f7",
}

-- Returns the foreground process name for the active pane,
-- falling back to the tab or pane title set by the shell.
local function tab_title(tab)
	local title = tab.active_pane.foreground_process_name
	if title and #title > 0 then
		title = title:match("([^/]+)$")
	end
	if not title or #title == 0 then
		title = tab.tab_title
	end
	if not title or #title == 0 then
		title = tab.active_pane.title
	end
	return title or "zsh"
end

local function truncate(str, max_len)
	if #str <= max_len then
		return str
	end
	return str:sub(1, max_len - 1) .. "..."
end

wezterm.on("format-tab-title", function(tab, _, _, _, _, _)
	local title = truncate(tab_title(tab), 24)
	local index = tostring(tab.tab_index + 1)
	local is_active = tab.is_active
	local is_zoomed = tab.active_pane.is_zoomed

	local fg = is_active and c.text or c.subtext0
	local bg = is_active and c.surface0 or c.mantle
	local index_fg = is_active and c.mauve or c.surface1

	-- "+" prefix when pane is zoomed so you can tell at a glance
	local label = is_zoomed and (" + " .. title .. " ") or (" " .. title .. " ")

	return {
		{ Background = { Color = bg } },
		{ Foreground = { Color = index_fg } },
		{ Text = " " .. index },
		{ Foreground = { Color = fg } },
		{ Text = label },
	}
end)

local keys = {
	-- Ctrl+Shift+V: disabled (conflicts with Neovim visual block mode)
	{ key = "v", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment },

	-- Cmd+T: new tab
	{ key = "t", mods = "SUPER", action = act.SpawnTab("CurrentPaneDomain") },
	-- Cmd+W: close current tab
	{ key = "w", mods = "SUPER", action = act.CloseCurrentTab({ confirm = false }) },
	-- Cmd+Shift+[: previous tab
	{ key = "[", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(-1) },
	-- Cmd+Shift+]: next tab
	{ key = "]", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(1) },
	-- Cmd+1-9: jump to tab by index
	{ key = "1", mods = "SUPER", action = act.ActivateTab(0) },
	{ key = "2", mods = "SUPER", action = act.ActivateTab(1) },
	{ key = "3", mods = "SUPER", action = act.ActivateTab(2) },
	{ key = "4", mods = "SUPER", action = act.ActivateTab(3) },
	{ key = "5", mods = "SUPER", action = act.ActivateTab(4) },
	{ key = "6", mods = "SUPER", action = act.ActivateTab(5) },
	{ key = "7", mods = "SUPER", action = act.ActivateTab(6) },
	{ key = "8", mods = "SUPER", action = act.ActivateTab(7) },
	{ key = "9", mods = "SUPER", action = act.ActivateTab(8) },

	-- Cmd+D: split pane left/right
	{ key = "d", mods = "SUPER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	-- Cmd+Shift+D: split pane top/bottom
	{ key = "d", mods = "SUPER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Cmd+Ctrl+H/L/K/J: focus pane in direction
	{ key = "h", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Right") },
	{ key = "k", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Up") },
	{ key = "j", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Down") },

	-- Cmd+Ctrl+Shift+H/L/K/J: resize pane in direction
	{ key = "h", mods = "SUPER|CTRL|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "l", mods = "SUPER|CTRL|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
	{ key = "k", mods = "SUPER|CTRL|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "j", mods = "SUPER|CTRL|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },

	-- Cmd+Shift+Z: zoom (maximize) current pane, same key restores
	{ key = "z", mods = "SUPER|SHIFT", action = act.TogglePaneZoomState },
	-- Cmd+Shift+W: close current pane without closing the tab
	{ key = "w", mods = "SUPER|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },

	-- Cmd+Shift+PageUp/PageDown: scroll by page
	{ key = "PageUp", mods = "SUPER|SHIFT", action = act.ScrollByPage(-1) },
	{ key = "PageDown", mods = "SUPER|SHIFT", action = act.ScrollByPage(1) },
	-- Cmd+Shift+U/I: scroll up/down by line
	{ key = "u", mods = "SUPER|SHIFT", action = act.ScrollByLine(-5) },
	{ key = "i", mods = "SUPER|SHIFT", action = act.ScrollByLine(5) },

	-- Cmd+Shift+Enter: enter copy mode (vi-style selection)
	{ key = "Enter", mods = "SUPER|SHIFT", action = act.ActivateCopyMode },

	-- Cmd+=/−/0: increase, decrease, reset font size
	{ key = "=", mods = "SUPER", action = act.IncreaseFontSize },
	{ key = "-", mods = "SUPER", action = act.DecreaseFontSize },
	{ key = "0", mods = "SUPER", action = act.ResetFontSize },

	-- Cmd+Shift+R: reload config without restarting
	{ key = "r", mods = "SUPER|SHIFT", action = act.ReloadConfiguration },
	-- Cmd+Shift+F: open search bar
	{ key = "f", mods = "SUPER|SHIFT", action = act.Search({ CaseSensitiveString = "" }) },
}

return {
	-- wezterm terminfo enables true color, undercurl, extended mouse, kitty graphics protocol.
	-- Only revert to xterm-256color if SSHing into remotes without wezterm terminfo installed.
	term = "wezterm",

	color_scheme = "Catppuccin Mocha",
	font = font,
	font_size = 14,

	-- On HiDPI/Retina, skip freetype hints. The display handles antialiasing at this density.
	-- On a non-Retina screen, try: freetype_load_target = "Light", freetype_render_target = "HorizontalLcd"

	front_end = "WebGpu",
	max_fps = 120,

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

	-- opacity = 1.0 is clean and sharp. For frosted glass: set opacity to 0.92 and uncomment blur.
	window_background_opacity = 1.0,
	-- macos_window_background_blur = 20,

	use_fancy_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,
	enable_scroll_bar = false,

	-- Undercurl and cursor weight. Requires term = "wezterm".
	underline_thickness = "200%",
	cursor_thickness = "200%",

	selection_word_boundary = " \t\n{}[]()\"'`,;:@|",

	audible_bell = "Disabled",

	keys = keys,
}
