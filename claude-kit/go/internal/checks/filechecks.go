package checks

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"

	"github.com/ku5ic/dotfiles/claude-kit/go/internal/config"
	"github.com/ku5ic/dotfiles/claude-kit/go/internal/project"
	"github.com/ku5ic/dotfiles/claude-kit/go/internal/tools"
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

// Group is one planned check run: the files an adapter claims under one
// directory, which is where it runs, and the command (nil when the tool
// isn't installed, with Skip saying why).
type Group struct {
	Adapter tools.Adapter
	Dir     string
	Why     string
	Files   []string
	Words   []string
	Skip    string
	label   string
}

// Plan works out which adapters claim which of the edited files under root
// (relative paths resolved against base) and the command each would run,
// without running anything. Deleted, ignored, and outside-the-repo files
// don't count: an ignored file (scratch, build output) never lands in the
// repo, so its checks have nothing to protect.
func Plan(cfg *config.Config, root, base string, edited []string) []*Group {
	adapters := tools.All(cfg)
	var groups []*Group
	byKey := map[string]*Group{}
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
		if !strings.HasPrefix(path, root+"/") || seen[path] || !isFile(path) || ignored[path] {
			continue
		}
		seen[path] = true
		for i, a := range adapters {
			claim, ok := a.Claims(path, root)
			if !ok {
				continue
			}
			key := fmt.Sprintf("%d|%s", i, claim.Dir)
			g, found := byKey[key]
			if !found {
				g = &Group{Adapter: a, Dir: claim.Dir, Why: claim.Why}
				byKey[key] = g
				groups = append(groups, g)
			}
			g.Files = append(g.Files, path)
		}
	}
	for _, g := range groups {
		plural := "s"
		if len(g.Files) == 1 {
			plural = ""
		}
		g.label = fmt.Sprintf("%s (%d file%s)", g.Adapter.Name, len(g.Files), plural)
		if g.Dir != root {
			g.label += " [" + strings.TrimPrefix(g.Dir, root+"/") + "]"
		}
		bin := tools.Resolve(g.Dir, root, g.Adapter.Bin, g.Adapter.LocalOnly)
		if bin == nil {
			where := "not installed"
			if g.Adapter.LocalOnly {
				where = "not in the project environment"
			}
			g.Skip = g.Adapter.Bin + " " + where
			continue
		}
		g.Words = expand(g.Adapter.Cmd, bin, g.Files, g.Dir)
	}
	return groups
}

// FileChecks runs the planned checks and returns the report (PASS/FAIL/SKIP
// lines), the failures with each tool's last 30 output lines, and the
// summary line. ran is false when no check claimed a file.
func FileChecks(cfg *config.Config, root, base string, edited []string) (report, failures, summary string, failed, ran bool) {
	groups := Plan(cfg, root, base, edited)
	if len(groups) == 0 {
		return "", "", "", false, false
	}
	var rep, fails strings.Builder
	pass, fail, skip := 0, 0, 0
	for _, g := range groups {
		label, words := g.label, g.Words
		if g.Skip != "" {
			fmt.Fprintf(&rep, "SKIP %s (%s)\n", label, g.Skip)
			skip++
			continue
		}
		var out bytes.Buffer
		cmd := exec.Command(words[0], words[1:]...)
		cmd.Dir, cmd.Stdout, cmd.Stderr = g.Dir, &out, &out
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
