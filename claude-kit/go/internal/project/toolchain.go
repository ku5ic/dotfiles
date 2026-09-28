package project

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/ku5ic/dotfiles/claude-kit/go/internal/config"
)

// ResolvePackageManager is the manager of the first package_managers
// lockfile (kit.yml order) found in dir or at its git toplevel, "" when
// none: monorepo lockfiles live at the root.
func ResolvePackageManager(cfg *config.Config, dir string) string {
	top := Toplevel(dir)
	for _, pm := range cfg.PackageManagers {
		if pm.Lockfile == "" || pm.Manager == "" {
			continue
		}
		if isFile(filepath.Join(dir, pm.Lockfile)) || (top != "" && isFile(filepath.Join(top, pm.Lockfile))) {
			return pm.Manager
		}
	}
	return ""
}

// ResolveBin is the nearest project-local copy of name (node_modules/.bin,
// .venv/bin, or venv/bin, from dir up to root), else PATH's, else "". Never
// npx, pnpm dlx, or uv run: those can install packages.
func ResolveBin(dir, root, name string) string {
	for _, sub := range []string{"node_modules/.bin", ".venv/bin", "venv/bin"} {
		if found := FindUp(dir, root, filepath.Join(sub, name)); found != "" && isExecutable(found) {
			return found
		}
	}
	if path, err := exec.LookPath(name); err == nil {
		return path
	}
	return ""
}

func isExecutable(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir() && info.Mode()&0o111 != 0
}

// ToolchainCmd resolves toolchain_checks entry tc for dir: the command with
// {bin} filled in, or the reason it can't run (its when_dir is missing, or
// none of its bins is on PATH). run-checks and the <tooling> block both use
// it, so Claude is never told about a check the checks skip.
func ToolchainCmd(tc config.ToolchainCheck, dir string) (cmd, skip string) {
	if tc.WhenDir != "" && !isDir(filepath.Join(dir, tc.WhenDir)) {
		return "", "no " + tc.WhenDir + "/ yet"
	}
	if len(tc.Bin) == 0 {
		return tc.Cmd, ""
	}
	for _, bin := range tc.Bin {
		if _, err := exec.LookPath(bin); err == nil {
			return strings.ReplaceAll(tc.Cmd, "{bin}", bin), ""
		}
	}
	return "", "none of " + strings.Join(tc.Bin, " ") + " on PATH"
}
