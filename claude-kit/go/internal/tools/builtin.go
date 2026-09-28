package tools

var jsExt = []string{"js", "jsx", "ts", "tsx", "mjs", "cjs", "mts", "cts"}

// builtins are the file-scoped checks every project gets when it uses the
// tool. None writes: no --fix, no --write, no new snapshots (CI mode);
// stylelint and markdownlint-cli2 still apply a config's own fix setting,
// since neither has a command-line override.
var builtins = []Adapter{
	{
		Name: "eslint", Ext: jsExt, Bin: "eslint", Cmd: "{bin} {files}",
		Signals: []string{"eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", "eslint.config.ts", "eslint.config.mts", "eslint.config.cts",
			".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", ".eslintrc.yml", ".eslintrc.yaml", ".eslintrc"},
	},
	{
		// --no-errors-on-unmatched: files biome.json ignores are otherwise an error.
		Name: "biome", Ext: []string{"js", "jsx", "ts", "tsx", "json", "jsonc", "css"}, Bin: "biome",
		Cmd: "{bin} check --no-errors-on-unmatched {files}", Signals: []string{"biome.json", "biome.jsonc"},
	},
	{
		Name: "stylelint", Ext: []string{"css", "scss"}, Bin: "stylelint", Cmd: "{bin} --allow-empty-input {files}",
		Signals: []string{"stylelint.config.js", "stylelint.config.mjs", "stylelint.config.cjs", ".stylelintrc", ".stylelintrc.json",
			".stylelintrc.js", ".stylelintrc.cjs", ".stylelintrc.yml", ".stylelintrc.yaml"},
	},
	{
		// CI=1: outside CI, vitest writes new snapshots.
		Name: "vitest", Ext: jsExt, Bin: "vitest", Cmd: "env CI=1 {bin} related --run --passWithNoTests {files}",
		Deps: JS, Packages: []string{"vitest"}, TestRunner: true,
	},
	{
		// --ci: fail on a missing snapshot instead of writing it.
		Name: "jest", Ext: jsExt, Bin: "jest", Cmd: "{bin} --ci --findRelatedTests --passWithNoTests {files}",
		Deps: JS, Packages: []string{"jest"}, TestRunner: true,
	},
	{
		// --no-fix: a project's `fix = true` would otherwise rewrite the files.
		Name: "ruff", Ext: []string{"py"}, Bin: "ruff", Cmd: "{bin} check --no-fix --force-exclude {files}",
		Signals: []string{"ruff.toml", ".ruff.toml"}, TOML: "pyproject.toml .tool.ruff", Deps: Python, Packages: []string{"ruff"},
	},
	{
		// mypy checks a file named on its command line even when its
		// exclude covers it, so the exclude is applied first.
		Name: "mypy", Ext: []string{"py"}, Bin: "mypy", Cmd: "{bin} {files}",
		Signals: []string{"mypy.ini", ".mypy.ini"}, TOML: "pyproject.toml .tool.mypy", Deps: Python, Packages: []string{"mypy"},
		ExcludeTOML: "pyproject.toml .tool.mypy.exclude", LocalOnly: true,
	},
	{
		Name: "pyright", Ext: []string{"py"}, Bin: "pyright", Cmd: "{bin} {files}",
		Signals: []string{"pyrightconfig.json"}, TOML: "pyproject.toml .tool.pyright", Deps: Python, Packages: []string{"pyright"},
		LocalOnly: true,
	},
	{
		// Runs from the module (go.mod), where packages load; golangci-lint
		// finds its config by walking up. --fix=false against issues.fix.
		Name: "golangci-lint", Ext: []string{"go"}, Bin: "golangci-lint", Cmd: "{bin} run --fix=false {dirs}",
		Signals: []string{"go.mod"}, Needs: []string{".golangci.yml", ".golangci.yaml", ".golangci.toml", ".golangci.json"},
	},
	{Name: "go-vet", Ext: []string{"go"}, Bin: "go", Cmd: "{bin} vet {dirs}", Signals: []string{"go.mod"}},
	{
		Name: "rubocop", Ext: []string{"rb"}, Bin: "rubocop", Cmd: "{bin} --force-exclusion {files}",
		Signals: []string{".rubocop.yml"}, Deps: Ruby, Packages: []string{"rubocop"},
	},
	{
		// Its arguments are globs (":" marks a literal path); --no-globs
		// drops the config's own, which would lint the whole repo.
		Name: "markdownlint", Ext: []string{"md"}, Bin: "markdownlint-cli2", Cmd: "{bin} --no-globs :{files}",
		Signals: []string{".markdownlint-cli2.jsonc", ".markdownlint-cli2.yaml", ".markdownlint-cli2.cjs", ".markdownlint-cli2.mjs",
			".markdownlint.json", ".markdownlint.jsonc", ".markdownlint.yaml", ".markdownlint.yml"},
	},
	{
		Name: "yamllint", Ext: []string{"yml", "yaml"}, Bin: "yamllint", Cmd: "{bin} {files}",
		Signals: []string{".yamllint", ".yamllint.yml", ".yamllint.yaml"},
	},
	{Name: "tofu-fmt", Ext: []string{"tf", "tfvars"}, Bin: "tofu", Cmd: "{bin} fmt -check {files}", Signals: []string{".terraform.lock.hcl"}},
	{Name: "shellcheck", Ext: []string{"sh", "bash"}, Bin: "shellcheck", Cmd: "{bin} -x {files}", Signals: []string{".shellcheckrc"}},
}

func init() {
	for i := range builtins {
		builtins[i].Builtin = true
	}
}
