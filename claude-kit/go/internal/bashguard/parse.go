// Package bashguard is guard-bash: it blocks genuinely destructive shell
// commands that permission rules can't express, on a real bash syntax tree
// (mvdan.cc/sh) instead of hand-rolled splitting.
package bashguard

import (
	"errors"
	"strings"

	"mvdan.cc/sh/v3/syntax"
)

// Word is one shell word: Value has quotes removed and escapes resolved,
// with expansions left as their source text ("$HOME/x", "$(scratch-dir.sh)"),
// as the bash original's word splitter produced it. Raw is the source.
type Word struct {
	Value string
	Raw   string
	end   int // source offset just past the word
}

// Redir is an output redirect: its operator and target word.
type Redir struct {
	Op     string
	Target Word
}

// Call is one simple command of a pipeline.
type Call struct {
	Assigns int // leading VAR=value words
	Words   []Word
	Redirs  []Redir
	// Heredocs are the raw bodies of this command's here-documents.
	Heredocs []string
	start    int // source offset of the first word
}

// Segment is one pipeline: the commands between &&, ||, ;, &, or a newline.
type Segment struct {
	Calls []Call
	end   int // source offset where the pipeline ends
	src   string
}

// Rest is the normalized source text after call's word, to the end of the
// pipeline: what the bash original matched its per-command regexes on. A
// word index past the end means the text after the whole call.
func (s Segment) Rest(call, word int) string {
	c := s.Calls[call]
	start := c.start
	switch {
	case word < len(c.Words):
		start = c.Words[word].end
	case len(c.Words) > 0:
		start = c.Words[len(c.Words)-1].end
	}
	if start >= s.end || start > len(s.src) {
		return ""
	}
	return normalize(s.src[start:s.end])
}

// normalize turns tabs into spaces and squeezes runs of spaces, as the bash
// original did with `tr '\t' ' ' | tr -s ' '` before any check.
func normalize(s string) string {
	s = strings.ReplaceAll(s, "\t", " ")
	for strings.Contains(s, "  ") {
		s = strings.ReplaceAll(s, "  ", " ")
	}
	return s
}

// shells are the commands a heredoc body is fed to as a script.
var shells = map[string]bool{"sh": true, "bash": true, "zsh": true, "dash": true, "ksh": true}

// Segments parses src and returns every pipeline in it, substitution and
// process-substitution bodies included (inner ones first, as they run
// first), and heredoc bodies fed to a shell. A parse error fails closed:
// statements before the error line are kept, and the lines after it are
// parsed again as a script of their own, so an unterminated heredoc's body
// is checked as commands.
func Segments(src string) []Segment {
	c := &collector{}
	c.parse(src, 0)
	return c.segs
}

type collector struct {
	segs  []Segment
	depth int
}

func (c *collector) parse(src string, depth int) {
	if depth > 8 || strings.TrimSpace(src) == "" {
		return
	}
	file, err := syntax.NewParser().Parse(strings.NewReader(src), "")
	if err == nil {
		c.stmts(src, file.Stmts)
		return
	}
	line := errorLine(err)
	if file != nil {
		var before []*syntax.Stmt
		for _, s := range file.Stmts {
			if int(s.End().Line()) < line {
				before = append(before, s)
			}
		}
		c.stmts(src, before)
	}
	if rest := afterLine(src, line); rest != "" {
		c.parse(rest, depth+1)
	}
}

func errorLine(err error) int {
	if pe, ok := errors.AsType[syntax.ParseError](err); ok {
		return int(pe.Pos.Line())
	}
	return 1
}

// afterLine is src from the line after line on.
func afterLine(src string, line int) string {
	for i := 0; i < line; i++ {
		nl := strings.IndexByte(src, '\n')
		if nl < 0 {
			return ""
		}
		src = src[nl+1:]
	}
	return src
}

func (c *collector) stmts(src string, stmts []*syntax.Stmt) {
	for _, s := range stmts {
		c.stmt(src, s)
	}
}

func (c *collector) stmt(src string, s *syntax.Stmt) {
	if s == nil {
		return
	}
	if bin, ok := s.Cmd.(*syntax.BinaryCmd); ok && (bin.Op == syntax.AndStmt || bin.Op == syntax.OrStmt) {
		c.stmt(src, bin.X)
		c.stmt(src, bin.Y)
		return
	}
	parts := pipeline(s)
	if parts == nil {
		// A compound command: its own statements, and any substitution in
		// its words (for items, case subjects, [[ ]] operands).
		c.inner(src, s.Cmd)
		for _, r := range s.Redirs {
			c.inner(src, r)
		}
		return
	}

	// The pipeline ends at its last command's last word or redirect, not at
	// the statement's end, which takes in a trailing ; or &.
	last := parts[len(parts)-1]
	end := int(last.Cmd.End().Offset())
	for _, r := range last.Redirs {
		if r.Hdoc == nil {
			end = max(end, int(r.End().Offset()))
		}
	}
	seg := Segment{src: src, end: end}
	feedsShell := false
	for _, p := range parts {
		call, ok := p.Cmd.(*syntax.CallExpr)
		if !ok {
			// ( ... ) or { ... } inside a pipeline: its statements are
			// segments of their own.
			c.inner(src, p.Cmd)
			continue
		}
		for _, a := range call.Assigns {
			c.inner(src, a)
		}
		for _, w := range call.Args {
			c.inner(src, w)
		}
		for _, r := range p.Redirs {
			c.inner(src, r.Word)
		}
		cl := Call{Assigns: len(call.Assigns)}
		if len(call.Args) > 0 {
			cl.start = int(call.Args[0].Pos().Offset())
		} else {
			cl.start = int(p.Pos().Offset())
		}
		for _, w := range call.Args {
			cl.Words = append(cl.Words, Word{wordValue(src, w), src[w.Pos().Offset():w.End().Offset()], int(w.End().Offset())})
		}
		for _, r := range p.Redirs {
			if r.Hdoc != nil {
				body := src[r.Hdoc.Pos().Offset():r.Hdoc.End().Offset()]
				// The slice ends with the terminator line; it isn't body.
				if nl := strings.LastIndexByte(body, '\n'); nl >= 0 && r.Word != nil &&
					strings.TrimLeft(body[nl+1:], "\t") == wordValue(src, r.Word) {
					body = body[:nl]
				}
				cl.Heredocs = append(cl.Heredocs, body)
				c.inner(src, r.Hdoc)
				continue
			}
			if op := r.Op.String(); strings.Contains(op, ">") && r.Word != nil {
				value := wordValue(src, r.Word)
				// >&2 duplicates an fd; the bash original read its target as
				// "&2", never a file name.
				if r.Op == syntax.DplOut {
					value = "&" + value
				}
				cl.Redirs = append(cl.Redirs, Redir{op, Word{value, src[r.Word.Pos().Offset():r.Word.End().Offset()], int(r.Word.End().Offset())}})
			}
		}
		if len(cl.Words) > 0 && shells[baseName(cl.Words[0].Value)] {
			feedsShell = true
		}
		seg.Calls = append(seg.Calls, cl)
	}
	if len(seg.Calls) > 0 {
		c.segs = append(c.segs, seg)
	}
	// A heredoc fed to a shell (bash <<EOF, cat <<EOF | sh) is commands.
	if feedsShell {
		for _, cl := range seg.Calls {
			for _, body := range cl.Heredocs {
				c.parse(body, c.depth+1)
			}
		}
	}
}

// inner collects the statements nested anywhere under n: substitution
// bodies and compound-command bodies.
func (c *collector) inner(src string, n syntax.Node) {
	if n == nil {
		return
	}
	syntax.Walk(n, func(node syntax.Node) bool {
		if st, ok := node.(*syntax.Stmt); ok {
			c.stmt(src, st)
			return false
		}
		return true
	})
}

// pipeline flattens a | or |& chain (or a lone command) into its parts; nil
// for anything else.
func pipeline(s *syntax.Stmt) []*syntax.Stmt {
	switch cmd := s.Cmd.(type) {
	case *syntax.CallExpr:
		return []*syntax.Stmt{s}
	case *syntax.BinaryCmd:
		if cmd.Op != syntax.Pipe && cmd.Op != syntax.PipeAll {
			return nil
		}
		left := pipeline(cmd.X)
		if left == nil {
			left = []*syntax.Stmt{cmd.X}
		}
		right := pipeline(cmd.Y)
		if right == nil {
			right = []*syntax.Stmt{cmd.Y}
		}
		return append(left, right...)
	}
	return nil
}

// wordValue removes quotes and resolves escapes, leaving every expansion as
// its source text.
func wordValue(src string, w *syntax.Word) string {
	var b strings.Builder
	for _, part := range w.Parts {
		b.WriteString(partValue(src, part, false))
	}
	return b.String()
}

func partValue(src string, part syntax.WordPart, inDouble bool) string {
	switch p := part.(type) {
	case *syntax.Lit:
		return unescape(p.Value, inDouble)
	case *syntax.SglQuoted:
		if p.Dollar {
			return src[p.Pos().Offset():p.End().Offset()]
		}
		return p.Value
	case *syntax.DblQuoted:
		var b strings.Builder
		for _, inner := range p.Parts {
			b.WriteString(partValue(src, inner, true))
		}
		return b.String()
	default:
		return src[part.Pos().Offset():part.End().Offset()]
	}
}

// unescape resolves backslash escapes as bash does: anything outside
// quotes, only $ ` " \ and newline inside double quotes.
func unescape(s string, inDouble bool) string {
	if !strings.Contains(s, `\`) {
		return s
	}
	var b strings.Builder
	for i := 0; i < len(s); i++ {
		if s[i] != '\\' || i+1 >= len(s) {
			b.WriteByte(s[i])
			continue
		}
		next := s[i+1]
		switch {
		case next == '\n':
			i++
		case !inDouble || strings.IndexByte("$`\"\\", next) >= 0:
			b.WriteByte(next)
			i++
		default:
			b.WriteByte('\\')
		}
	}
	return b.String()
}

func baseName(s string) string { return s[strings.LastIndexByte(s, '/')+1:] }
