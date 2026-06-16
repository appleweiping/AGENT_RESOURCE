# Source Handling

Use this reference when working with local book archives, unusual encodings, or extracted text.

## Default Archive

Default root:

```text
D:\Company\anime\literature-books
```

Run inventory:

```powershell
python scripts\inventory_books.py "D:\Company\anime\literature-books" --format markdown --limit 80
```

Extract a file:

```powershell
python scripts\extract_text.py "D:\Company\anime\literature-books\some-book.txt" --output ".\work\some-book.extracted.txt"
```

Chunk extracted text:

```powershell
python scripts\chunk_source.py ".\work\some-book.extracted.txt" --output-dir ".\work\chunks" --chunk-chars 6000
```

## Format Notes

- `.txt`: try UTF-8 first, then common Chinese encodings such as GB18030 and Big5.
- `.pdf`: extraction requires an optional Python PDF package such as `pypdf` or `PyPDF2`.
- `.zip`: extract readable text-like members and keep member names in headers.
- `.mobi`: treat as unsupported unless a local ebook converter is available. Record the limitation.
- `.rar`: not supported by the bundled scripts. Ask for extraction or use a local archive tool if available.

## Intake Metadata

Record:

- Source path
- Format
- File size
- Extraction method
- Encoding or parser used
- Extraction confidence: high, medium, low, or failed
- Missing pages, unreadable sections, OCR issues, or archive members skipped

## Text Hygiene

- Remove obvious site headers, duplicate download ads, and repeated boilerplate only after noting the cleanup.
- Do not rewrite source during intake.
- Preserve chapter headings if they exist.
- Keep an untouched extracted copy when doing substantial cleanup.
- For unclear encodings, inspect a sample before trusting the entire file.

## Quotation Policy

- Use short quotes only when needed to anchor style, theme, or a key line.
- Prefer paraphrase for plot and character extraction.
- Keep public-facing adaptation outputs focused on transformed material: scripts, summaries, and original panel descriptions.
