# Skills evaluations

Evaluation infrastructure for skills under `~/.dotfiles/claude/skills/`. Per Anthropic's authoring guide and the skill-creator skill, evals come before extensive documentation and are the source of truth for measuring skill effectiveness.

## Schema

Eval files at `scenarios/<skill-name>/evals.json` match the skill-creator documented schema:

```json
{
  "skill_name": "skill-name",
  "evals": [
    {
      "id": 1,
      "prompt": "Task prompt as the user would type it",
      "files": ["fixture-name.ext"],
      "expected_output": "Description of the expected result, may include enumerated behaviors",
      "assertions": []
    }
  ]
}
```

Fields are intentionally compatible with skill-creator's tooling (`scripts/run_loop.py`, `scripts/aggregate_benchmark.py`, the eval viewer). The `assertions` field is reserved for automated grading; manual grading uses `expected_output` only.

## Running an eval (manual mode)

```sh
# List skills with available evals
~/.dotfiles/claude/skills/evals/run.sh list

# Run all evals for a skill (prints prompts and expected outputs)
~/.dotfiles/claude/skills/evals/run.sh wcag-audit

# Run a specific eval by id
~/.dotfiles/claude/skills/evals/run.sh wcag-audit 1
```

The runner prints each eval's prompt, fixture paths, and expected output. Workflow:

1. Copy the prompt into Claude Code or claude.ai with the relevant skill loaded.
2. Compare the produced output against the `expected_output` description.
3. Record pass / fail / partial in `~/.claude/scratch/eval-<skill-name>-<YYYYMMDD-HHMM>.md`. Use the markdown-report skill format.

## Iteration ceiling

This setup supports first-pass evaluation. It does NOT support skill-creator's full iteration loop (test -> grade -> review -> revise across iteration directories with structured feedback). If you find yourself iterating on a skill more than two cycles, consider migrating that skill's evaluation to skill-creator's tooling, which provides:

- Subagent-based parallel test runs
- Per-eval `eval_metadata.json`, `timing.json`, `grading.json`
- The eval viewer for structured user feedback (`feedback.json`)
- Automated grading via `agents/grader.md`
- Iteration directories under `<skill-name>-workspace/`

The schema in our `evals.json` is already compatible with skill-creator's tooling, so migration does not require data conversion.

## Adding a new eval scenario

1. Open `scenarios/<skill-name>/evals.json`.
2. Add an object to the `evals` array with the next integer `id`, `prompt`, optional `files`, and `expected_output`. Leave `assertions` as `[]`.
3. If the eval needs a fixture file, add it under `fixtures/` with a descriptive name.
4. Run the eval at least once to confirm it exercises the skill.

## Adding evals for a new skill

1. Create `scenarios/<skill-name>/evals.json` with at minimum three evals matching the schema above.
2. Add fixtures under `fixtures/` as needed.
3. Run all three evals and record baseline results in `~/.claude/scratch/`.

## Eval design rules

These rules echo skill-creator's "Description Optimization" and "Test Cases" guidance. They apply to all evals in this directory.

- Prompts must be realistic -- text a real user would type, not abstract test cases.
- Vary tone (formal, casual), length, and explicitness across the three scenarios per skill.
- At least one negative or near-miss scenario per skill (a query the skill should NOT trigger on, or a query that touches the domain but should produce a different response).
- `expected_output` should be specific and verifiable. "Identifies the missing label as a failure citing 1.3.1 or 3.3.2" is good; "produces a good audit" is not.
