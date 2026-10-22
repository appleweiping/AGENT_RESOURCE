# literature-to-manga

Turns a novel, biography or other prose text into a manga adaptation package: a
candidate ranking, an adaptation brief, a manga bible (cast, world, visual motifs),
page-by-page panel scripts and a JSONL pack of image prompts.

The agent does the writing; the three Python scripts handle the boring parts
(listing books in a folder, pulling plain text out of TXT/Markdown, ZIP archives of
text files or PDF, splitting long text into chunks). Pass the book folder as an
argument, or set `LITERATURE_BOOKS_DIR` once and the skill uses it as the default.

Needs: Python 3.10+. Plain text works with the standard library; PDF needs `pypdf`.

## Example

```text
$ python scripts/inventory_books.py ./books --format markdown --limit 5
# Book Inventory

- Root: `./books`
- Count: 1

| # | Title | Format | Size MB | Relative path |
| ---: | --- | --- | ---: | --- |
| 1 | the keeper | txt | 0.0 | `the-keeper.txt` |

$ python scripts/extract_text.py ./books/the-keeper.txt --output ./work/keeper.txt
$ python scripts/chunk_source.py ./work/keeper.txt --output-dir ./work/chunks
```

Then ask the agent: "Adapt the-keeper into a 3-chapter manga, quiet horror tone."
