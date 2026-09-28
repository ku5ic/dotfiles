// Package config loads kit.yml and the user's overlay into one typed Config.
package config

// Config mirrors kit.yml. Every key kit.yml may hold is a field here, so a
// strict decode reports an unknown or misspelled key instead of dropping it.
type Config struct {
	GlobalSkills       []string            `yaml:"global_skills"`
	SkillFileMap       []SkillFileRule     `yaml:"skill_file_map"`
	SkillTriggers      map[string]string   `yaml:"skill_triggers"`
	PackageManagers    []PackageManager    `yaml:"package_managers"`
	ExtraLockfiles     []string            `yaml:"extra_lockfiles"`
	ProtectedBranches  []string            `yaml:"protected_branches"`
	RCFiles            []string            `yaml:"rc_files"`
	SensitivePaths     []string            `yaml:"sensitive_paths"`
	LogMaxLines        int                 `yaml:"log_max_lines"`
	DisabledRules      []string            `yaml:"disabled_rules"`
	TaskProviders      []TaskProvider      `yaml:"task_providers"`
	Checks             []Check             `yaml:"checks"`
	ToolchainChecks    []ToolchainCheck    `yaml:"toolchain_checks"`
	SubprojectMaxDepth int                 `yaml:"subproject_max_depth"`
	Formatters         []Formatter         `yaml:"formatters"`
	DisabledFormatters []string            `yaml:"disabled_formatters"`
	BinLookups         []BinLookup         `yaml:"bin_lookups"`
	FileChecks         []FileCheck         `yaml:"file_checks"`
	DisabledFileChecks []string            `yaml:"disabled_file_checks"`
	Tools              []string            `yaml:"tools"`
	Orchestrators      []Orchestrator      `yaml:"orchestrators"`
	Versions           map[string][]string `yaml:"versions"`
	VersionSources     map[string][]Source `yaml:"version_sources"`
	Stacks             map[string]Stack    `yaml:"stacks"`
}

type SkillFileRule struct {
	On     string   `yaml:"on"`
	Globs  []string `yaml:"globs"`
	Skills []string `yaml:"skills"`
}

type PackageManager struct {
	Lockfile   string `yaml:"lockfile"`
	Manager    string `yaml:"manager"`
	Ecosystem  string `yaml:"ecosystem"`
	HandEdited bool   `yaml:"hand_edited"`
}

type TaskProvider struct {
	Name      string            `yaml:"name"`
	Stack     string            `yaml:"stack"`
	Manifests []string          `yaml:"manifests"`
	Extractor string            `yaml:"extractor"`
	Arg       string            `yaml:"arg"`
	Run       string            `yaml:"run"`
	RunByPM   map[string]string `yaml:"run_by_pm"`
}

type Check struct {
	Name    string   `yaml:"name"`
	Tasks   []string `yaml:"tasks"`
	Exclude []string `yaml:"exclude"`
}

type ToolchainCheck struct {
	Stack   string   `yaml:"stack"`
	Name    string   `yaml:"name"`
	Cmd     string   `yaml:"cmd"`
	Bin     []string `yaml:"bin"`
	WhenDir string   `yaml:"when_dir"`
}

type Formatter struct {
	Name           string   `yaml:"name"`
	Ext            []string `yaml:"ext"`
	SignalFiles    []string `yaml:"signal_files"`
	SignalTOML     string   `yaml:"signal_toml"`
	SignalPrettier bool     `yaml:"signal_prettier"`
	Bin            string   `yaml:"bin"`
	Cmd            string   `yaml:"cmd"`
}

type BinLookup struct {
	Name        string   `yaml:"name"`
	SignalFiles []string `yaml:"signal_files"`
	VenvCmd     string   `yaml:"venv_cmd"`
	Probe       string   `yaml:"probe"`
	Run         string   `yaml:"run"`
}

type FileCheck struct {
	Name        string   `yaml:"name"`
	Ext         []string `yaml:"ext"`
	SignalFiles []string `yaml:"signal_files"`
	SignalTOML  string   `yaml:"signal_toml"`
	TestScript  string   `yaml:"test_script"`
	NeedsFiles  []string `yaml:"needs_files"`
	ExcludeTOML string   `yaml:"exclude_toml"`
	LocalOnly   bool     `yaml:"local_only"`
	Bin         string   `yaml:"bin"`
	Cmd         string   `yaml:"cmd"`
}

type Orchestrator struct {
	Name      string   `yaml:"name"`
	Signal    string   `yaml:"signal"`
	TaskPaths []string `yaml:"task_paths"`
	Run       string   `yaml:"run"`
}

type Source struct {
	File      string `yaml:"file"`
	Extractor string `yaml:"extractor"`
	Arg       string `yaml:"arg"`
	Label     string `yaml:"label"`
	Up        bool   `yaml:"up"`
}

type Stack struct {
	Sentinels []Sentinel `yaml:"sentinels"`
	Skills    []string   `yaml:"skills"`
	Extras    []Extra    `yaml:"extras"`
}

type Sentinel struct {
	Name   string `yaml:"name"`
	Anchor bool   `yaml:"anchor"`
}

// Rule is one detection test of an extra: a dep, a file, or a grep over files.
type Rule struct {
	Dep  string   `yaml:"dep"`
	File string   `yaml:"file"`
	Grep string   `yaml:"grep"`
	In   []string `yaml:"in"`
}

type Extra struct {
	Name   string `yaml:"name"`
	Rule   `yaml:",inline"`
	AnyOf  []Rule   `yaml:"any_of"`
	Rename string   `yaml:"rename"`
	Skills []string `yaml:"skills"`
}
