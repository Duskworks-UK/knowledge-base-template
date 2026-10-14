# Using this knowledge base

This knowledge base has not been initialised yet. Run the [starting prompt](../README.md#initialisation-prompt) to record its subject, purpose, and audience here and in the [schema](SCHEMA.md).

**[Browse the wiki](index.md)** · **[Read its rules](SCHEMA.md)** · **[Recent changes](log.md)**

## Resume work

```text
Read this repository's AGENTS.md, the wiki schema, index, and recent log.
Confirm which knowledge base you are using, then help me with [task].
```

Only relevant pages and source passages need to be loaded. The wiki is durable context; it does not need to be pasted into every conversation.

## Add material

Put files or notes in `inbox/`, or provide a source directly:

```text
Process [these files or this URL] for this wiki. Follow the schema: preserve
the source and its provenance, check for existing coverage, and integrate
useful evidence. Flag extraction gaps, uncertainty, and disagreement.
Report what changed and which inbox items were processed.
```

Original captures live in `raw/`. Summaries and interpretation live in the maintained pages. A changed source becomes a new capture, preserving what earlier conclusions were based on.

## Ask a question

```text
Based on this knowledge base, [question]? Cite the supporting pages and
original evidence. Separate what the evidence says, your interpretation,
and what remains unknown. Identify any outside research explicitly.
```

An answer based on existing material does not become an independent source merely because it has been saved.

## Save useful analysis

```text
Save this analysis in the wiki with its underlying evidence, assumptions,
and unresolved questions. Link it from relevant pages and the index.
```

Keep work that would be useful to revisit. Routine lookups can remain in the conversation.

## Review the wiki

```text
Review this wiki for broken links, missing index entries, duplicate topics,
unsupported claims, conflicting information, and information that may be
outdated. Fix clear organisational problems and report substantive issues
requiring judgment. Record the checks performed and any checks not run.
```

Updating a page's edit date does not mean its claims have been rechecked. Record factual review separately when it happens.

## Keep work across machines

Git records and shares changes when you commit, push, and pull them. Ask the agent to do that explicitly when wanted. This template does not automatically synchronise files or run background maintenance.

Each clone is another working copy of the same knowledge base. Bring it up to date before editing, review changes before publishing, and resolve simultaneous edits deliberately.
