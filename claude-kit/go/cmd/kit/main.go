// Command kit is claude-kit's single binary: hooks and helper scripts as
// subcommands, reached through same-name shims in hooks/ and bin/.
package main

import (
	"fmt"
	"io"
	"os"
	"strings"
	"time"

	"go.yaml.in/yaml/v3"

	"github.com/ku5ic/dotfiles/claude-kit/go/internal/config"
	"github.com/ku5ic/dotfiles/claude-kit/go/internal/detect"
	"github.com/ku5ic/dotfiles/claude-kit/go/internal/gitbase"
	"github.com/ku5ic/dotfiles/claude-kit/go/internal/project"
)

const usage = `usage: kit <command> [args]

  config [--check]           print the effective kit.yml (base + overlay);
                             --check prints only warnings, exits 1 on any
  subprojects [root]         ".", then each subproject directory, sorted
  tasks [dir]                provider, stack, task, command (tab-separated)
  project-root [--check]     the project root; --check: exit 1 if unanchored
  project-name               slug-safe project identifier
  scratch-dir [kind [slug]]  scratch directory, or a report path in it
  plans-dir                  plans directory
  detect-stack               compact stack report
  git-base [--diff|--log] [base] [flags] [-- paths]
  hook <name>                run a Claude Code hook; payload on stdin
`

func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
}

// env is what every command needs: the kit's paths and, loaded on first
// use, its config.
type env struct {
	paths  config.Paths
	stdout io.Writer
	stderr io.Writer
	cwd    string
	cfg    *config.Config
	warned bool // config produced warnings
}

func (e *env) config() (*config.Config, error) {
	if e.cfg != nil {
		return e.cfg, nil
	}
	cfg, warnings, err := config.Load(e.paths)
	for _, w := range warnings {
		fmt.Fprintln(e.stderr, "kit: warning:", w)
	}
	e.cfg, e.warned = cfg, len(warnings) > 0
	return cfg, err
}

func run(args []string, stdout, stderr io.Writer) int {
	if len(args) == 0 {
		fmt.Fprint(stderr, usage)
		return 2
	}
	exe, err := os.Executable()
	if err != nil {
		fmt.Fprintln(stderr, "kit:", err)
		return 1
	}
	paths, err := config.ResolvePaths(exe)
	if err != nil {
		fmt.Fprintln(stderr, "kit:", err)
		return 1
	}
	cwd, err := os.Getwd()
	if err != nil {
		fmt.Fprintln(stderr, "kit:", err)
		return 1
	}
	e := &env{paths: paths, stdout: stdout, stderr: stderr, cwd: cwd}

	name, rest := args[0], args[1:]
	switch name {
	case "-h", "--help", "help":
		fmt.Fprint(stdout, usage)
		return 0
	case "config":
		return cmdConfig(e, rest)
	case "git-base":
		return gitbase.Run(rest, stdout, stderr)
	case "hook":
		return cmdHook(e, rest, os.Stdin)
	}

	commands := map[string]func(*env, *config.Config, []string) int{
		"subprojects":  cmdSubprojects,
		"tasks":        cmdTasks,
		"project-root": cmdProjectRoot,
		"project-name": cmdProjectName,
		"scratch-dir":  cmdScratchDir,
		"plans-dir":    cmdPlansDir,
		"detect-stack": cmdDetectStack,
	}
	cmd, ok := commands[name]
	if !ok {
		fmt.Fprintf(stderr, "kit: unknown command %q\n%s", name, usage)
		return 2
	}
	cfg, err := e.config()
	if err != nil {
		fmt.Fprintln(stderr, "kit:", err)
		return 1
	}
	return cmd(e, cfg, rest)
}

func cmdConfig(e *env, args []string) int {
	_, err := e.config()
	if err != nil {
		fmt.Fprintln(e.stderr, "kit:", err)
		return 1
	}
	if len(args) > 0 && args[0] == "--check" {
		if e.warned {
			return 1
		}
		return 0
	}
	merged, err := config.Merged(e.paths)
	if err != nil {
		fmt.Fprintln(e.stderr, "kit:", err)
		return 1
	}
	enc := yaml.NewEncoder(e.stdout)
	enc.SetIndent(2)
	if err := enc.Encode(merged); err != nil {
		fmt.Fprintln(e.stderr, "kit:", err)
		return 1
	}
	return 0
}

func cmdSubprojects(e *env, cfg *config.Config, args []string) int {
	root := ""
	if len(args) > 0 {
		root = args[0]
	}
	if root == "" {
		if root = project.Toplevel(e.cwd); root == "" {
			root = e.cwd
		}
	}
	for _, dir := range project.Subprojects(cfg, root) {
		fmt.Fprintln(e.stdout, dir)
	}
	return 0
}

func cmdTasks(e *env, cfg *config.Config, args []string) int {
	dir := "."
	if len(args) > 0 {
		dir = args[0]
	}
	for _, task := range project.Tasks(cfg, dir) {
		stack := task.Stack
		if stack == "" {
			stack = "-"
		}
		fmt.Fprintln(e.stdout, strings.Join([]string{task.Provider, stack, task.Name, task.Cmd}, "\t"))
	}
	return 0
}

func cmdProjectRoot(e *env, cfg *config.Config, args []string) int {
	root, anchored := project.Root(cfg, e.cwd)
	if len(args) > 0 && args[0] == "--check" {
		if anchored {
			return 0
		}
		return 1
	}
	fmt.Fprintln(e.stdout, root)
	return 0
}

func cmdProjectName(e *env, cfg *config.Config, _ []string) int {
	root, _ := project.Root(cfg, e.cwd)
	fmt.Fprintln(e.stdout, project.Name(root))
	return 0
}

func cmdScratchDir(e *env, cfg *config.Config, args []string) int {
	dir, err := project.Dir(cfg, e.paths, e.cwd, "scratch", true)
	if err != nil {
		fmt.Fprintln(e.stderr, "scratch-dir.sh:", err)
		return 1
	}
	if len(args) == 0 {
		fmt.Fprintln(e.stdout, dir)
		return 0
	}
	slug := ""
	if len(args) > 1 {
		slug = args[1]
	}
	fmt.Fprintln(e.stdout, project.ReportPath(dir, args[0], slug, time.Now().Format("20060102-1504")))
	return 0
}

func cmdPlansDir(e *env, cfg *config.Config, _ []string) int {
	dir, err := project.Dir(cfg, e.paths, e.cwd, "plans", true)
	if err != nil {
		fmt.Fprintln(e.stderr, "plans-dir.sh:", err)
		return 1
	}
	fmt.Fprintln(e.stdout, dir)
	return 0
}

func cmdDetectStack(e *env, cfg *config.Config, _ []string) int {
	root, _ := project.Root(cfg, e.cwd)
	fmt.Fprint(e.stdout, detect.Report(cfg, root))
	return 0
}
