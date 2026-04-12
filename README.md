# dnrdb

Seminar paper on the relational database design of a sports activity reservation platform for the University of Split.

## Output

- `SEMINAR.md` — paper

## Data

- `data/schema.sql` — relational schema
- `data/seed.sql` — seed data
- `data/nuke.sql` — drop all tables
- `data/setup.sh` — run schema + seed in one step

## Prompts

Helper LLM prompts used during writing and compilation:

| File                        | Purpose                                 |
| --------------------------- | --------------------------------------- |
| `prompts/PROMPT_PDF.md`     | Compile SEMINAR.md → PDF via Claude CLI |
| `prompts/PROMPT_EDIT.md`    | Style editing pipeline                  |
| `prompts/PROMPT_CHARTS.md`  | Generate charts                         |
| `prompts/PROMPT_MERMAID.md` | Generate Mermaid diagrams               |
