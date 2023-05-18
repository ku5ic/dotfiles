-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices
config.color_scheme = "Tokyo Night Storm"
config.font = wezterm.font("FiraCode Nerd Font Propo", {
	weight = 450,
	stretch = "Normal",
	style = "Normal",
}) -- (AKA: FiraCode Nerd Font Propo Ret) /Users/ku5ic/Library/Fonts/FiraCodeNerdFontPropo-Retina.ttf, CoreText
config.freetype_load_target = 'Light'
config.freetype_render_target = 'HorizontalLcd'
config.font_size = 14
config.initial_rows = 30
config.initial_cols = 100
config.window_padding = {
	left = 20,
	right = 20,
	top = 0,
	bottom = 0,
}
config.native_macos_fullscreen_mode = true
config.window_background_opacity = 0.95
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.enable_scroll_bar = true
config.enable_csi_u_key_encoding = true
config.audible_bell = "Disabled"

-- and finally, return the configuration to wezterm
return config
