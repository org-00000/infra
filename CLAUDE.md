# CLAUDE.md

- The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD
  NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as
  described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

- Personal preferences that should not be committed belong in `CLAUDE.local.md` (add it
  to `.gitignore`).

## Environment

- You are executing in a Guix container started with: `./bin/env-start`

- Read: `./etc/bash-dev-session`

- Read: `./etc/bash-dev-profile`

- You SHOULD use `fd` instead of `find`

- You SHOULD use `ripgrep` instead of `grep`

## Documentation

- All files ending with extension `.org` use OrgMode: https://orgmode.org/org.html

- Read: `./doc.org`

- `[[ref:UUID]]` references a spec node; `[[id:UUID]]` anchors one. To navigate:
  `,find-references UUID` lists usages; `,find-identifiers UUID` finds the anchor.

- Task definition: `doc/task.org` — Backlog: `doc/backlog.org`

- Project commands are sent as messages to `bin/actor`. See `doc/actor.org` for the
  specification of each command. Commands are available in `$PATH` as symlinks under
  `bin/`.

## Workflow

- Given a task to do, you SHOULD follow: `doc/fork-pr.org`.

- Workflow for any task: identify or create a task in `doc/backlog.org` → follow
  `doc/fork-pr.org` → verify the checklist at `fork-pr#pull-request` → mark DONE.

- When a command fails: read its full output and address the root cause. Do not retry
  without understanding the error.

- When compacting, preserve: the current task objective, any open `[[ref:UUID]]` chains
  being resolved, and the working state of `doc/backlog.org` items in progress.

## Conventions

- Before implementing anything non-trivial: write or update its specification in `doc/`
  following the format in `doc/specification.org`. Link from the implementation with
  `[[ref:UUID][Specification]]` in a language comment and anchor the spec node with
  `[[id:UUID]]`.

- TODOs left in code have the form `TODO(<4-char-id>)` or `TODO(<4-char-id>): description`.
  See `doc/todo.org`. Prefer capturing pending work as a task in `doc/backlog.org` over
  leaving a TODO in code.

- When introducing new domain terms, define them in `doc/definitions.org`.
