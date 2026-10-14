# Knowledge Base Template

A portable second brain for your agents. Start a knowledge base for a project, research topic, team, or personal interest without writing the same setup instructions again.

Plain Markdown, preserved sources, and linked pages. Designed for [Hermes Agent](https://hermes-agent.nousresearch.com/) and usable with any agent that can read and edit local files. No application, database, or Obsidian subscription is required.

**[Use this template](https://github.com/Duskworks-UK/knowledge-base-template/generate)** · **[Everyday use](wiki/README.md)** · **[Wiki rules](wiki/SCHEMA.md)**

## Start here

1. Select **Use this template → Create a new repository**. Give the new knowledge base a name and choose its visibility. This template is public and intended to be shared; each new repository has its own visibility setting.
2. Clone **your new repository** to the machine where your agent runs. Clone that same repository elsewhere to work on the same knowledge base; use the template again for a different one.
3. Open the agent in the cloned repository. For Hermes, select the wiki folder as described below.
4. Paste the initialisation prompt, replacing the subject. The agent records your choices in the schema so you do not need to repeat them.

### Initialisation prompt

```text
Initialise this repository as a knowledge base for [subject or project].

Read AGENTS.md, wiki/SCHEMA.md, and any existing wiki content first. Use this
repository's wiki directory. Report its resolved location before writing.
If using Hermes, load the available llm-wiki skill and verify its selected
location matches. Follow this repository's schema for its specific conventions.

Use what I have already told you. Ask only for missing details that materially
affect setup: purpose, intended audience, scope, and initial sources. Record
the answers in SCHEMA.md and update the wiki introduction. Preserve existing
content and initialise only what is missing. Record the setup in the log.

If I supplied sources, process those first. Otherwise leave the wiki empty
and suggest a few starting sources. Do not invent subject knowledge or file
example content as real knowledge. Keep tracked paths portable and report
what changed, any unresolved setup choices, and the next useful action.
```

## Connect Hermes

Hermes needs filesystem access to the clone and its `llm-wiki` skill available. A GitHub URL alone does not give it a local folder to maintain. If Hermes runs on a server, clone the knowledge base on that server. If Hermes reports that no AI provider is connected, complete `hermes model` before starting.

The `llm-wiki` skill version 2.1.0 inspected for this template uses `WIKI_PATH`; without it, the skill defaults to `~/wiki`. Check the skill installed in your Hermes profile if its configuration differs.

### Select a wiki for one session

Use this approach when your active Hermes profile does not already define `WIKI_PATH`. On macOS or Linux, run this from the root of the cloned knowledge base:

```sh
WIKI_PATH="$PWD/wiki" hermes chat -s llm-wiki
```

This explicitly loads the skill and supplies this wiki's path for the process. Run it from each repository when switching knowledge bases. These commands use the selected Hermes profile's existing provider configuration.

On Windows PowerShell, set the variable before starting Hermes:

```powershell
$env:WIKI_PATH = (Resolve-Path ./wiki).Path
hermes chat -s llm-wiki
```

The PowerShell variable lasts for that shell session; set it again when switching wikis.

**Check for an existing default:** in the Hermes version inspected for this template, the profile's `.env` file takes precedence over shell variables. A saved `WIKI_PATH` can therefore override either command above. Use a profile without a saved wiki path for per-session selection, or a separate profile for each persistent default. Always confirm the resolved location with the agent before the first write.

### Save a default location

For one regular wiki, set `WIKI_PATH` to the absolute wiki folder in your active Hermes profile's `.env` file. The default profile uses `~/.hermes/.env`. Edit that individual setting while preserving the file's other contents. Restart the relevant Hermes session or service after changing its environment.

Keep this machine-specific setting outside the knowledge-base repository. Multiple wikis are easier to manage with the per-session command above or separate Hermes profiles. For a messaging gateway or container, the path must exist inside the environment where Hermes's file tools run.

Ask Hermes to confirm the resolved wiki path and read its schema on first use. Existing `.hermes.md`, `HERMES.md`, or other project context files can affect which instructions Hermes loads; explicitly reading `AGENTS.md` avoids relying on implicit discovery.

Hermes works when you give it a task. This template does not install a folder watcher, schedule background work, or automatically commit and push changes to GitHub. Those are separate choices.

## What is included

```text
knowledge-base-template/
├── README.md                  # Setup and initialisation prompt
├── AGENTS.md                  # Instructions for agents
├── LICENSE                    # MIT license for the template
├── TEMPLATE_VERSION           # Template baseline
├── templates/                 # Blank source, entity, concept and analysis pages
└── wiki/
    ├── README.md              # Everyday requests and wiki introduction
    ├── SCHEMA.md              # This knowledge base's purpose and rules
    ├── index.md               # Content directory
    ├── log.md                 # Meaningful changes
    ├── inbox/                 # Incoming material
    ├── raw/                   # Preserved source captures and attachments
    ├── sources/               # Source summaries and provenance
    ├── entities/              # People, organisations, products and places
    ├── concepts/              # Topics and explanations
    ├── comparisons/           # Comparisons across sources
    └── queries/               # Useful answers worth retaining
```

The content folders start empty. Their `.gitkeep` files only make Git preserve the folders. The blank page templates are scaffolding, not evidence or wiki pages.

Use ordinary relative Markdown links throughout. The files are readable on GitHub, in a text editor, or in Obsidian. When using Obsidian, open the repository root as a vault and select Markdown links with paths relative to each file. Obsidian is optional.

## Reuse and updates

`TEMPLATE_VERSION` identifies the template baseline used by this copy. Repositories created from a GitHub template are independent; updates here do not automatically update your knowledge bases. Apply useful changes selectively and preserve each copy's schema and content.

To incorporate this structure into an existing repository, copy the files without a nested `.git` directory, preserve existing instructions, and add a pointer to this wiki. Do not replace an existing project's `AGENTS.md` wholesale.

The reusable template is [MIT licensed](LICENSE). Imported source material retains its own terms; adding it to a knowledge base does not change its license.

## Background

Inspired by [Andrej Karpathy's LLM Wiki idea](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). The central pattern is a maintained synthesis of preserved sources, governed by written conventions. This repository supplies one practical implementation; it is not an official Karpathy or Hermes project.

The [Hermes wiki skill](https://github.com/NousResearch/hermes-agent/blob/main/skills/research/llm-wiki/SKILL.md) supplies its agent workflow. This template adds project-specific choices: standard Markdown links, versioned source captures, and no minimum page or link quotas. See the schema for the exact rules.

Reference documentation: [Hermes context files](https://hermes-agent.nousresearch.com/docs/user-guide/which-file-does-what), [Hermes skills](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills), [GitHub templates](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template), and [Obsidian links](https://help.obsidian.md/links). Setup references checked on 14 October 2026.

Made by [Duskworks](https://github.com/Duskworks-UK). Improvements and practical feedback are welcome through this repository's issues and pull requests.
