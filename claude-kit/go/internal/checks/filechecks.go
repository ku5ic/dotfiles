package checks

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strings"

	"github.com/ku5ic/dotfiles/claude-kit/go/internal/config"
	"github.com/ku5ic/dotfiles/claude-kit/go/internal/extract"
	"github.com/ku5ic/dotfiles/claude-kit/go/internal/project"
)

// EditedFiles lists the file_path (or notebook_path) of every Edit, Write,
// MultiEdit, and NotebookEdit call in the last turn of a transcript: the
// entries after the last real user prompt. A tool result is not a prompt;
// neither is a meta entry.
func EditedFiles(transcript string) ([]string, error) {
	f, err := os.Open(transcript)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	type entry struct {
		Type    string `json:"type"`
		IsMeta  bool   `json:"isMeta"`
		Message struct {
			Content json.RawMessage `json:"content"`
		} `json:"message"`
	}
	type block struct {
		Type  string `json:"type"`
		Name  string `json:"name"`
		Input struct {
			FilePath     *string `json:"file_path"`
			NotebookPath *string `json:"notebook_path"`
		} `json:"input"`
	}

	var edited []string
	scanner := bufio.NewScanner(f)
	scanner.Buffer(make([]byte, 1024*1024), 64*1024*1024)
	for scanner.Scan() {
		var e entry
		if json.Unmarshal(scanner.Bytes(), &e) != nil {
			continue
		}
		var blocks []block
		isArray := json.Unmarshal(e.Message.Content, &blocks) == nil
		switch e.Type {
		case "user":
			if e.IsMeta {
				continue
			}
			if isArray && slices.ContainsFunc(blocks, func(b block) bool { return b.Type == "tool_result" }) {
				continue
			}
			edited = edited[:0] // a new turn starts
		case "assistant":
			if !isArray {
				continue
			}
			for _, b := range blocks {
				if b.Type != "tool_use" || !slices.Contains([]string{"Edit", "Write", "MultiEdit", "NotebookEdit"}, b.Name) {
					continue
				}
				switch {
				case b.Input.FilePath != nil:
					edited = append(edited, *b.Input.FilePath)
				case b.Input.NotebookPath != nil:
					edited = append(edited, *b.Input.NotebookPath)
				default:
					edited = append(edited, "")
				}
			}
		}
	}
	return edited, scanner.Err()
}

// group is one check's run: the files it claims under one signal directory,
// which is also where it runs.
type group struct {
	check config.FileCheck
	dir   string
	files []string
}

// FileChecks runs kit.yml's file_checks on the edited files under root
// (relative ones resolved against base) and returns the report
// (PASS/FAIL/SKIP lines), the failures with each tool's last 30 output
// lines, and the summary line. ran is false when no check claimed a file.
func FileChecks(cfg *config.Config, root, base string, edited []string) (report, failures, summary string, failed, ran bool) {
	var groups []*group
	byKey := map[string]*group{}
	seen := map[string]bool{}
	ignored := gitIgnored(root, edited, base)
	for _, path := range edited {
		if path == "" {
			continue
		}
		if !filepath.IsAbs(path) {
			path = filepath.Join(base, path)
		}
		path = project.PhysicalPath(path)
		// An ignored file (scratch, build output, node_modules) never lands
		// in the repo, so its checks have nothing to protect.
		if !strings.HasPrefix(path, root+"/") || seen[path] || !isFile(path) || ignored[path] {
			continue
		}
		seen[path] = true
		base := filepath.Base(path)
		if !strings.Contains(base, ".") {
			continue
		}
		ext := strings.ToLower(base[strings.LastIndexByte(base, '.')+1:])
		for i, c := range cfg.FileChecks {
			if slices.Contains(cfg.DisabledFileChecks, c.Name) || !slices.Contains(c.Ext, ext) {
				continue
			}
			signal := findSignal(c, filepath.Dir(path), root)
			if signal == "" {
				continue
			}
			sigDir := filepath.Dir(signal)
			if c.TestScript != "" && !namesWord(extract.JSONValue(filepath.Join(sigDir, "package.json"), ".scripts.test"), c.TestScript) {
				continue
			}
			if len(c.NeedsFiles) > 0 && project.FindUp(sigDir, root, c.NeedsFiles...) == "" {
				continue
			}
			if c.ExcludeTOML != "" && excluded(sigDir, path, c.ExcludeTOML) {
				continue
			}
			key := fmt.Sprintf("%d|%s", i, sigDir)
			g, ok := byKey[key]
			if !ok {
				g = &group{check: c, dir: sigDir}
				byKey[key] = g
				groups = append(groups, g)
			}
			g.files = append(g.files, path)
		}
	}
	if len(groups) == 0 {
		return "", "", "", false, false
	}

	var rep, fails strings.Builder
	pass, fail, skip := 0, 0, 0
	for _, g := range groups {
		plural := "s"
		if len(g.files) == 1 {
			plural = ""
		}
		label := fmt.Sprintf("%s (%d file%s)", g.check.Name, len(g.files), plural)
		if g.dir != root {
			label += " [" + strings.TrimPrefix(g.dir, root+"/") + "]"
		}
		binCmd := resolveRun(cfg, root, g.dir, g.check.Bin, g.check.LocalOnly)
		if len(binCmd) == 0 {
			where := "not installed"
			if g.check.LocalOnly {
				where = "not in the project environment"
			}
			fmt.Fprintf(&rep, "SKIP %s (%s %s)\n", label, g.check.Bin, where)
			skip++
			continue
		}
		words := expand(g.check.Cmd, binCmd, g.files, g.dir)
		var out bytes.Buffer
		cmd := exec.Command(words[0], words[1:]...)
		cmd.Dir, cmd.Stdout, cmd.Stderr = g.dir, &out, &out
		if cmd.Run() == nil {
			fmt.Fprintf(&rep, "PASS %s\n", label)
			pass++
			continue
		}
		fmt.Fprintf(&rep, "FAIL %s\n", label)
		// The tail: linters print findings and the summary last, after
		// preambles like rubocop's unconfigured-cops notice.
		lines := strings.Split(strings.TrimRight(out.String(), "\n"), "\n")
		fmt.Fprintf(&fails, "FAIL %s\n%s\n", label, strings.Join(lines[max(0, len(lines)-30):], "\n"))
		fail++
	}
	return rep.String(), fails.String(), fmt.Sprintf("checks: %d passed, %d failed, %d skipped", pass, fail, skip), fail > 0, true
}

// gitIgnored asks git once which of the edited files it ignores, keyed by
// physical path. Any failure means "none ignored": check them all.
func gitIgnored(root string, edited []string, base string) map[string]bool {
	var paths []string
	for _, p := range edited {
		if p == "" {
			continue
		}
		if !filepath.IsAbs(p) {
			p = filepath.Join(base, p)
		}
		paths = append(paths, project.PhysicalPath(p))
	}
	ignored := map[string]bool{}
	if len(paths) == 0 {
		return ignored
	}
	cmd := exec.Command("git", "-C", root, "check-ignore", "--stdin")
	cmd.Stdin = strings.NewReader(strings.Join(paths, "\n") + "\n")
	out, _ := cmd.Output() // exit 1 means none ignored
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		if line != "" {
			ignored[line] = true
		}
	}
	return ignored
}

func isFile(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.Mode().IsRegular()
}

// findSignal is the nearest signal_files entry from dir up to root, else
// the nearest signal_toml file holding its table, walking past a nearer
// TOML without the table as ruff's own lookup does.
func findSignal(c config.FileCheck, dir, root string) string {
	if len(c.SignalFiles) > 0 {
		if found := project.FindUp(dir, root, c.SignalFiles...); found != "" {
			return found
		}
	}
	if c.SignalTOML == "" {
		return ""
	}
	file, table, _ := strings.Cut(c.SignalTOML, " ")
	for from := dir; ; {
		found := project.FindUp(from, root, file)
		if found == "" {
			return ""
		}
		if extract.TOMLHas(found, table) {
			return found
		}
		if filepath.Dir(found) == root {
			return ""
		}
		from = filepath.Dir(filepath.Dir(found))
	}
}

var nonWord = regexp.MustCompile(`[^A-Za-z0-9_-]`)

// namesWord is true when script contains word as a whole word.
func namesWord(script, word string) bool {
	return slices.Contains(strings.Fields(nonWord.ReplaceAllString(script, " ")), word)
}

// excluded is true when path, relative to dir, matches a regex the TOML
// file in dir holds at the dotted path (a string or a list), as mypy's
// exclude matches with re.search.
func excluded(dir, path, spec string) bool {
	file, table, _ := strings.Cut(spec, " ")
	tomlPath := filepath.Join(dir, file)
	rel := strings.TrimPrefix(path, dir+"/")
	patterns := extract.TOMLArray(tomlPath, table)
	if len(patterns) == 0 {
		if v := extract.TOMLString(tomlPath, table); v != "" {
			patterns = []string{v}
		}
	}
	for _, pattern := range patterns {
		if re, err := regexp.Compile(pattern); err == nil && re.MatchString(rel) {
			return true
		}
	}
	return false
}

// resolveRun is the words that run name from dir: a project-local bin, else
// the first bin_lookups hit, else PATH unless localOnly. Nil when none has it.
func resolveRun(cfg *config.Config, root, dir, name string, localOnly bool) []string {
	found := project.ResolveBin(dir, root, name)
	if found != "" && strings.HasPrefix(found, root+"/") {
		return []string{found}
	}
	for _, l := range cfg.BinLookups {
		signal := project.FindUp(dir, root, l.SignalFiles...)
		if signal == "" {
			continue
		}
		if l.VenvCmd != "" {
			words := strings.Fields(l.VenvCmd)
			if _, err := exec.LookPath(words[0]); err != nil {
				continue
			}
			cmd := exec.Command(words[0], words[1:]...)
			cmd.Dir = filepath.Dir(signal)
			out, err := cmd.Output()
			venv := strings.TrimSpace(string(out))
			if err == nil && venv != "" {
				if bin := filepath.Join(venv, "bin", name); isExecutable(bin) {
					return []string{bin}
				}
			}
			continue
		}
		if l.Probe != "" {
			words := strings.Fields(strings.ReplaceAll(l.Probe, "{bin}", name))
			if _, err := exec.LookPath(words[0]); err != nil {
				continue
			}
			cmd := exec.Command(words[0], words[1:]...)
			cmd.Dir = filepath.Dir(signal)
			if cmd.Run() != nil {
				continue
			}
			return strings.Fields(strings.ReplaceAll(l.Run, "{bin}", name))
		}
	}
	if found != "" && !localOnly {
		return []string{found}
	}
	return nil
}

func isExecutable(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir() && info.Mode()&0o111 != 0
}

// expand fills a check's cmd word by word: {bin} (a whole word) becomes the
// resolved run words, a word holding {files} repeats once per file, and a
// word holding {dirs} once per file directory as ./<relative to dir>.
func expand(cmd string, bin, files []string, dir string) []string {
	var parts []string
	for _, word := range strings.Fields(cmd) {
		switch {
		case strings.Contains(word, "{files}"):
			for _, f := range files {
				parts = append(parts, strings.ReplaceAll(word, "{files}", f))
			}
		case strings.Contains(word, "{dirs}"):
			var dirs []string
			for _, f := range files {
				rel := filepath.Dir("./" + strings.TrimPrefix(f, dir+"/"))
				if rel != "." {
					rel = "./" + rel
				}
				if !slices.Contains(dirs, rel) {
					dirs = append(dirs, rel)
				}
			}
			for _, d := range dirs {
				parts = append(parts, strings.ReplaceAll(word, "{dirs}", d))
			}
		case word == "{bin}":
			parts = append(parts, bin...)
		default:
			parts = append(parts, word)
		}
	}
	return parts
}
