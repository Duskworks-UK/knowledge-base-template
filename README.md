# Knowledge Base Template

A portable second brain for your agents. Use it as a research knowledge base, as a personal assistant that keeps track of your projects, tasks and reminders, or both, without writing the same setup instructions again.

Plain Markdown, preserved sources, and linked pages. The wiki works with any agent that can read and edit local files, such as Claude Code, Codex, or Hermes. The optional personal assistant automation needs Claude Code on a Mac. No application, database, or Obsidian subscription is required.

**[Use this template](https://github.com/Duskworks-UK/knowledge-base-template/generate)** · **[Everyday use](wiki/README.md)** · **[Wiki rules](wiki/SCHEMA.md)**

## Start here

1. Select **Use this template → Create a new repository**. Give the new knowledge base a name and choose its visibility. **If it will hold anything about your life, projects, or other people, make it private.** This template is public; each new repository has its own visibility setting.
2. Clone **your new repository** to the machine where your agent runs. Clone that same repository elsewhere to work on the same knowledge base; use the template again for a different one.
3. Start your agent in the root of the cloned repository. In Claude Code, the repository's `assistant` agent starts automatically.
4. Paste the initialisation prompt, replacing the subject. The agent records your choices in the schema so you do not need to repeat them.
5. Optionally, [turn on the automation](#personal-assistant-and-automation-claude-code-on-macos) so the wiki keeps itself up to date and reminds you of tasks.

### Initialisation prompt

```text
Initialise this repository as a knowledge base for [subject, project, or
"my personal assistant"].

Read AGENTS.md, wiki/SCHEMA.md, and any existing wiki content first. Use this
repository's wiki directory and report its location before writing. If you
have a general wiki skill or a default wiki location, make sure it points at
this directory, and follow this repository's schema where they differ.

Use what I have already told you. Ask only for missing details that materially
affect setup: purpose, intended audience, scope, mode (research, personal, or
both), and initial sources. In personal or both mode, also ask what personal
information I'm happy to keep, and check that this repository is private.
Record the answers in SCHEMA.md and update the wiki introduction. Preserve
existing content and initialise only what is missing. Record the setup in
the log.

If I supplied sources, process those first. Otherwise leave the wiki empty
and suggest a few starting sources or first projects. Do not invent subject
knowledge or file example content as real knowledge. Keep tracked paths
portable and report what changed, any unresolved setup choices, and the next
useful action.
```

## Use with any agent

There is no agent-specific setup. The agent needs to run where the clone is and be able to read and edit its files. A GitHub URL alone does not give it a local folder to maintain; if your agent runs on a server, clone the knowledge base there.

The instructions live in the repository itself. `AGENTS.md` tells agents how to work here, and `wiki/SCHEMA.md` holds the wiki's rules, including the projects, tasks, and journal conventions. Codex and many other agents read `AGENTS.md` automatically; `CLAUDE.md` imports it for Claude Code. For any other agent, the initialisation prompt and the [everyday prompts](wiki/README.md) ask it to read those files first.

If your agent already has a wiki skill or a saved default wiki location, check that it points at this repository's `wiki/` folder before the first write. Ask the agent to confirm the location if you are unsure. When switching between knowledge bases, start the agent in the repository you want to work on.

The agent works when you give it a task. Nothing runs in the background, commits, or pushes unless you turn on the automation.

## Personal assistant and automation (Claude Code on macOS)

In Claude Code, this repository starts the `assistant` agent and lets it edit wiki files without asking each time. Talk to it as you would a personal assistant: "remind me to renew my passport next month", "we picked the blue tiles for the kitchen", "what's on this week?". It records what you tell it as you go, in the projects, tasks, and journal described in the [schema](wiki/SCHEMA.md#personal-assistant).

The automation makes the wiki keep itself up to date when you aren't in a conversation:

- **Filing:** anything that lands in `wiki/inbox/` is filed within a minute or so by the `filer` agent, running headless with `claude -p`. It follows the schema, sorts quick captures into tasks, projects, and the journal, moves each item to `raw/`, logs what it did, and sets aside anything it can't file in `inbox/held/`.
- **Quick capture:** `automation/capture.sh "Book the MOT next Friday"` drops a note in the inbox. Put it behind an Apple Shortcut (a "Run Shell Script" action with the input passed as stdin), a Raycast or Alfred command, or a keyboard shortcut. Files dragged into `wiki/inbox/` are filed too, and so are notes your other Claude Code sessions write there.
- **Reminders:** every morning, a notification lists the tasks in `wiki/tasks.md` that are due or overdue. This is a plain script and doesn't use Claude.
- **Morning brief** *(optional)*: the assistant writes a short brief at the top of today's journal page: what's due, what's coming up, what's stuck, and what needs your decision.
- **Commit and push:** wiki changes are committed after each filing run, each brief, and each reply from the assistant in Claude Code. Pushing is off unless you choose it.

Initialise the knowledge base first, then run from the repository root:

```sh
automation/install.sh                     # filing, commits, reminders at 08:00
automation/install.sh --push              # also push each commit
automation/install.sh --brief             # also write a morning brief
automation/install.sh --remind-at 07:30   # change the morning time
automation/install.sh --no-commit         # leave committing to you
automation/install.sh --no-reminders
automation/install.sh --uninstall         # turn everything off
```

Run it again with different options to change your choices. The installer adds up to two jobs to `~/Library/LaunchAgents` and saves this clone's choices in `.git/kb-automation.conf`; it doesn't change your Claude Code settings. Without it, nothing is committed automatically. The log is in `~/Library/Logs/`, and the installer prints its name.

To watch the filer work, run `claude --agent filer` here and ask it to file the inbox. To file once without installing anything, run `automation/process-inbox.sh`; for a list of what's due, `automation/remind.sh --print`.

The headless agents may edit files in this repository and run `ls`, `mv`, `mkdir`, `shasum`, and `date`, nothing else. They treat inbox items as material, never as instructions, but only let trusted sources write to the inbox. The first notification may ask you to allow notifications in System Settings. Git must be installed (on a Mac, the Command Line Tools); macOS offers to install them the first time Git is used.

## What is included

```text
knowledge-base-template/
├── README.md                  # Setup and initialisation prompt
├── AGENTS.md                  # Instructions for agents
├── CLAUDE.md                  # Points Claude Code to AGENTS.md
├── LICENSE                    # MIT license for the template
├── TEMPLATE_VERSION           # Template baseline
├── .claude/
│   ├── settings.json          # Starts the assistant; commit hook
│   └── agents/                # assistant and filer agents
├── automation/                # Optional filing, capture, reminders and brief (macOS)
├── templates/                 # Blank pages, including project, tasks and journal day
└── wiki/
    ├── README.md              # Everyday requests and wiki introduction
    ├── SCHEMA.md              # This knowledge base's purpose and rules
    ├── index.md               # Content directory
    ├── log.md                 # Meaningful changes
    ├── inbox/                 # Incoming material and quick captures
    ├── raw/                   # Preserved source captures and attachments
    ├── sources/               # Source summaries and provenance
    ├── entities/              # People, organisations, products and places
    ├── concepts/              # Topics and explanations
    ├── comparisons/           # Comparisons across sources
    ├── queries/               # Useful answers worth retaining
    ├── projects/              # Personal mode: one page per project (created at setup)
    ├── journal/               # Personal mode: one page per day (created at setup)
    └── tasks.md               # Personal mode: tasks and reminders (created at setup)
```

The content folders start empty. Their `.gitkeep` files only make Git preserve the folders. The personal mode files are created at setup, so a research-only wiki doesn't have them. The blank page templates are scaffolding, not evidence or wiki pages.

Use ordinary relative Markdown links throughout. The files are readable on GitHub, in a text editor, or in Obsidian. When using Obsidian, open the repository root as a vault and select Markdown links with paths relative to each file. The task format works with Obsidian's Tasks plugin. Obsidian is optional.

## Reuse and updates

`TEMPLATE_VERSION` identifies the template baseline used by this copy. Repositories created from a GitHub template are independent; updates here do not automatically update your knowledge bases. Apply useful changes selectively and preserve each copy's schema and content.

To incorporate this structure into an existing repository, copy the files without a nested `.git` directory, preserve existing instructions, and add a pointer to this wiki. Do not replace an existing project's `AGENTS.md` wholesale.

The reusable template is [MIT licensed](LICENSE). Imported source material retains its own terms; adding it to a knowledge base does not change its license.

## Background

Inspired by [Andrej Karpathy's LLM Wiki idea](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). The central pattern is a maintained synthesis of preserved sources, governed by written conventions. This repository supplies one practical implementation; it is not an official Karpathy project.

The workflow is written into the schema rather than tied to any agent: standard Markdown links, versioned source captures, and no minimum page or link quotas. See the [schema](wiki/SCHEMA.md) for the exact rules.

Reference documentation: [GitHub templates](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template), and [Obsidian links](https://help.obsidian.md/links). Setup references checked on 14 October 2026.

Made by [Duskworks](https://github.com/Duskworks-UK). Improvements and practical feedback are welcome through this repository's issues and pull requests.
