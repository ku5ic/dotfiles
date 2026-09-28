// Command kit is claude-kit's single binary: hooks and helper scripts as
// subcommands, reached through same-name shims in hooks/ and bin/.
package main

import (
	"fmt"
	"io"
	"os"
	"strings"

	"go.yaml.in/yaml/v3"

	"github.com/ku5ic/dotfiles/claude-kit/go/internal/config"
	"github.com/ku5ic/dotfiles/claude-kit/go/internal/project"
)

const usage = `usage: kit <command> [args]

  config [--check]     print the effective kit.yml (base + overlay);
                       --check prints only warnings and exits 1 on any
  subprojects [root]   ".", then each subproject directory, sorted
  tasks [dir]          provider, stack, task, command per line (tab-separated)
`

func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
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

	switch args[0] {
	case "config":
		return cmdConfig(paths, args[1:], stdout, stderr)
	case "subprojects", "tasks":
		cfg, warnings, err := config.Load(paths)
		for _, w := range warnings {
			fmt.Fprintln(stderr, "kit: warning:", w)
		}
		if err != nil {
			fmt.Fprintln(stderr, "kit:", err)
			return 1
		}
		if args[0] == "subprojects" {
			return cmdSubprojects(cfg, args[1:], stdout)
		}
		return cmdTasks(cfg, args[1:], stdout)
	case "-h", "--help", "help":
		fmt.Fprint(stdout, usage)
		return 0
	}
	fmt.Fprintf(stderr, "kit: unknown command %q\n%s", args[0], usage)
	return 2
}

func cmdConfig(paths config.Paths, args []string, stdout, stderr io.Writer) int {
	_, warnings, err := config.Load(paths)
	for _, w := range warnings {
		fmt.Fprintln(stderr, "kit: warning:", w)
	}
	if err != nil {
		fmt.Fprintln(stderr, "kit:", err)
		return 1
	}
	if len(args) > 0 && args[0] == "--check" {
		if len(warnings) > 0 {
			return 1
		}
		return 0
	}
	merged, err := config.Merged(paths)
	if err != nil {
		fmt.Fprintln(stderr, "kit:", err)
		return 1
	}
	enc := yaml.NewEncoder(stdout)
	enc.SetIndent(2)
	if err := enc.Encode(merged); err != nil {
		fmt.Fprintln(stderr, "kit:", err)
		return 1
	}
	return 0
}

func cmdSubprojects(cfg *config.Config, args []string, stdout io.Writer) int {
	root := ""
	if len(args) > 0 {
		root = args[0]
	}
	if root == "" {
		wd, _ := os.Getwd()
		if root = project.Toplevel(wd); root == "" {
			root = wd
		}
	}
	for _, dir := range project.Subprojects(cfg, root) {
		fmt.Fprintln(stdout, dir)
	}
	return 0
}

func cmdTasks(cfg *config.Config, args []string, stdout io.Writer) int {
	dir := "."
	if len(args) > 0 {
		dir = args[0]
	}
	for _, task := range project.Tasks(cfg, dir) {
		stack := task.Stack
		if stack == "" {
			stack = "-"
		}
		fmt.Fprintln(stdout, strings.Join([]string{task.Provider, stack, task.Name, task.Cmd}, "\t"))
	}
	return 0
}
