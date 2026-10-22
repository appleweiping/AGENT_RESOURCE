# project-hardness

Tells an agent to build a small model of a project (architecture, constraints, module
blast radius) under `<project>/.agent/` before editing, and to turn a vague request into
a task spec with edit paths, risks and test commands.

This folder is only the instructions. The engine that writes `.agent/` lives in my wiki
repo, [appleweiping/WEIPING_WIKI](https://github.com/appleweiping/WEIPING_WIKI)
(`scripts/hardness/`, run through `scripts/wiki.py`).

Needs: Python 3 and a checkout of WEIPING_WIKI.

## Example

From the WEIPING_WIKI checkout:

```bash
python scripts/wiki.py hardness scan ../my-project
python scripts/wiki.py hardness harden ../my-project "add CSV export to the report page"
python scripts/wiki.py hardness impact ../my-project reports
```

Then read `../my-project/.agent/architecture.md` and the generated `tasks/<id>.md`
before changing code.
