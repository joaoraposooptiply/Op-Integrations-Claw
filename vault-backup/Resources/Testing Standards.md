---
tags: [standards, testing, reference]
updated: 2026-02-24
---

# Testing Standards

## Pre-Ship Verification (mandatory)

### Tap
```bash
# 1. Install
cd tap-<name> && pip install -e .

# 2. Discover — must produce valid JSON with streams[]
tap-<name> --config config.json --discover | python3 -m json.tool

# 3. Import test
python3 -c "from tap_<name>.tap import Tap<Name>; print('OK')"

# 4. Sync test (optional, needs live credentials)
tap-<name> --config config.json --catalog catalog.json
```

### Target
```bash
# 1. Install
cd target-<name> && pip install -e .

# 2. Import test
python3 -c "from target_<name>.target import Target<Name>; print('OK')"

# 3. Write test (with sample input)
echo '{"type":"RECORD",...}' | target-<name> --config config.json
```

### ETL Notebook
- Run with sample tap output
- Verify entity mappings produce valid Optiply API payloads
- Verify snapshot diff detects: new, updated, deleted records
- Check summary cell outputs counts

## Automated Checks
- [ ] No `TODO` or `FIXME` in code
- [ ] No `singer_sdk` imports (must be `hotglue_singer_sdk`)
- [ ] No `streams/` directory (must be single `streams.py`)
- [ ] `__init__.py` files are empty
- [ ] `alerting_level = AlertingLevel.WARNING` present
- [ ] `_write_state_message` fix present
