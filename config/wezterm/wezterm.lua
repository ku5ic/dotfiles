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
	-- Cmd+1: jump to tab 1
	{ key = "1", mods = "SUPER", action = act.ActivateTab(0) },
	-- Cmd+2: jump to tab 2
	{ key = "2", mods = "SUPER", action = act.ActivateTab(1) },
	-- Cmd+3: jump to tab 3
	{ key = "3", mods = "SUPER", action = act.ActivateTab(2) },
	-- Cmd+4: jump to tab 4
	{ key = "4", mods = "SUPER", action = act.ActivateTab(3) },
	-- Cmd+5: jump to tab 5
	{ key = "5", mods = "SUPER", action = act.ActivateTab(4) },
	-- Cmd+6: jump to tab 6
	{ key = "6", mods = "SUPER", action = act.ActivateTab(5) },
	-- Cmd+7: jump to tab 7
	{ key = "7", mods = "SUPER", action = act.ActivateTab(6) },
	-- Cmd+8: jump to tab 8
	{ key = "8", mods = "SUPER", action = act.ActivateTab(7) },
	-- Cmd+9: jump to tab 9
	{ key = "9", mods = "SUPER", action = act.ActivateTab(8) },

	-- Cmd+D: split pane left/right
	{ key = "d", mods = "SUPER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	-- Cmd+Shift+D: split pane top/bottom
	{ key = "d", mods = "SUPER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Cmd+Ctrl+H: focus pane to the left
	{ key = "h", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Left") },
	-- Cmd+Ctrl+L: focus pane to the right
	{ key = "l", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Right") },
	-- Cmd+Ctrl+K: focus pane above
	{ key = "k", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Up") },
	-- Cmd+Ctrl+J: focus pane below
	{ key = "j", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Down") },

	-- Cmd+Ctrl+Shift+H: shrink pane from the right edge (grow toward left)
	{ key = "h", mods = "SUPER|CTRL|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	-- Cmd+Ctrl+Shift+L: grow pane to the right
	{ key = "l", mods = "SUPER|CTRL|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
	-- Cmd+Ctrl+Shift+K: grow pane upward
	{ key = "k", mods = "SUPER|CTRL|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	-- Cmd+Ctrl+Shift+J: grow pane downward
	{ key = "j", mods = "SUPER|CTRL|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },

	-- Cmd+Shift+Z: zoom (maximize) current pane, same key restores
	{ key = "z", mods = "SUPER|SHIFT", action = act.TogglePaneZoomState },
	-- Cmd+Shift+W: close current pane without closing the tab
	{ key = "w", mods = "SUPER|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },

	-- Cmd+Shift+PageUp: scroll buffer up by one page
	{ key = "PageUp", mods = "SUPER|SHIFT", action = act.ScrollByPage(-1) },
	-- Cmd+Shift+PageDown: scroll buffer down by one page
	{ key = "PageDown", mods = "SUPER|SHIFT", action = act.ScrollByPage(1) },
	-- Cmd+Shift+U: scroll buffer up by 5 lines
	{ key = "u", mods = "SUPER|SHIFT", action = act.ScrollByLine(-5) },
	-- Cmd+Shift+I: scroll buffer down by 5 lines
	{ key = "i", mods = "SUPER|SHIFT", action = act.ScrollByLine(5) },

	-- Cmd+Shift+Enter: enter copy mode (vi-style selection)
	{ key = "Enter", mods = "SUPER|SHIFT", action = act.ActivateCopyMode },

	-- Cmd+=: increase font size
	{ key = "=", mods = "SUPER", action = act.IncreaseFontSize },
	-- Cmd+-: decrease font size
	{ key = "-", mods = "SUPER", action = act.DecreaseFontSize },
	-- Cmd+0: reset font size to configured default
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
	-- Prefer the discrete GPU on dual-GPU Macs for consistent frame pacing.
	-- Tradeoff: marginally higher battery draw on laptops; switch to "LowPower" if that matters.
	webgpu_power_preference = "HighPerformance",
	max_fps = 120,
	-- Independent of max_fps: paces cursor blink and other animated visuals.
	animation_fps = 60,
	-- Default is true; declared explicitly so future readers see image-protocol intent.
	enable_kitty_graphics = true,
	-- Default is 3500. Bumped for log review and long compile output.
	scrollback_lines = 10000,
	-- Cmd+= / Cmd+- adjust font without nudging window geometry.
	adjust_window_size_when_changing_font_size = false,

	initial_rows = 33,
	initial_cols = 100,

	-- Symmetric padding on all four sides for visual balance.
	window_padding = {
		left = 20,
		right = 20,
		top = 20,
		bottom = 20,
	},

	window_decorations = "INTEGRATED_BUTTONS",
	native_macos_fullscreen_mode = true,

	-- opacity = 1.0 is clean and sharp. For frosted glass: set opacity to 0.92 and uncomment blur.
	window_background_opacity = 1.0,
	-- macos_window_background_blur = 20,

	-- Dim inactive panes so the focused pane is visually obvious.
	inactive_pane_hsb = {
		saturation = 0.85,
		brightness = 0.75,
	},

	-- Cursor: explicit defaults so future-you can tune without spelunking docs.
	default_cursor_style = "SteadyBlock",
	cursor_blink_rate = 500,

	-- Tab bar font matches the main font. Uses Catppuccin surface tones for the frame.
	window_frame = {
		font = font,
		font_size = 13,
		active_titlebar_bg = c.mantle,
		inactive_titlebar_bg = c.mantle,
	},

	-- Tie tab bar background to the Catppuccin palette already used in format-tab-title.
	colors = {
		tab_bar = {
			background = c.mantle,
			active_tab = { bg_color = c.surface0, fg_color = c.text },
			inactive_tab = { bg_color = c.mantle, fg_color = c.subtext0 },
			inactive_tab_hover = { bg_color = c.surface0, fg_color = c.text },
			new_tab = { bg_color = c.mantle, fg_color = c.subtext0 },
			new_tab_hover = { bg_color = c.surface0, fg_color = c.text },
		},
	},

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
