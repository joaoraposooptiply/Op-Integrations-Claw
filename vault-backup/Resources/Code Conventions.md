---
tags: [standards, code, reference]
updated: 2026-02-24
---

# Code Conventions

## File Structure — Tap
```
tap-<name>/
├── tap_<name>/
│   ├── __init__.py          # EMPTY
│   ├── tap.py               # Tap class definition
│   ├── streams.py           # ALL streams in single file
│   ├── auth.py              # Auth handler (if complex)
│   └── client.py            # HTTP client (optional)
├── setup.py or pyproject.toml
├── config.json              # Sample config
├── meltano.yml              # Meltano config
└── README.md
```

## File Structure — Target
```
target-<name>/
├── target_<name>/
│   ├── __init__.py          # EMPTY
│   ├── target.py            # Target class definition
│   └── sinks.py             # Sink classes
├── setup.py or pyproject.toml
├── config.json
└── README.md
```

## Naming
- Tap package: `tap-<name>` (kebab-case)
- Python module: `tap_<name>` (snake_case)
- Stream classes: `PascalCase` (e.g., `ProductsStream`)
- Config keys: `snake_case`

## SDK Import
```python
# CORRECT
from hotglue_singer_sdk import typing as th
from hotglue_singer_sdk.tap_base import Tap
from hotglue_singer_sdk.streams import RESTStream

# WRONG — never use
from singer_sdk import ...
```

## Config Schema (minimum)
```python
config_jsonschema = th.PropertiesList(
    th.Property("api_url", th.StringType, required=True),
    th.Property("access_token", th.StringType, required=True),
    th.Property("start_date", th.DateTimeType),
).to_dict()
```

## Error Handling Pattern
```python
from hotglue_singer_sdk.exceptions import InvalidCredentialsError
import backoff

@backoff.on_exception(
    backoff.expo,
    (requests.exceptions.RequestException,),
    max_tries=5,
    jitter=backoff.full_jitter,
)
def request(self, ...):
    response = ...
    if response.status_code == 401:
        raise InvalidCredentialsError("Invalid credentials")
    ...
```

## Alerting
```python
from hotglue_singer_sdk.helpers import AlertingLevel

class MyTap(Tap):
    alerting_level = AlertingLevel.WARNING
```
