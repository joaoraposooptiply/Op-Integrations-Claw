# Op-Integrations-Claw

Optiply Singer taps, targets, and ETL notebooks — built and maintained by Aria 🔗

## Structure
```
taps/          # Singer taps (extract from source systems)
targets/       # Singer targets (load to Optiply)
etl/           # ETL notebooks (transform between tap → target)
docs/          # Integration documentation
shared/        # Shared utilities, base classes
```

## Stack
- **SDK:** `hotglue_singer_sdk`
- **Spec:** Singer (open source ETL)
- **Language:** Python 3.9+

## Integration Flow
```
Source System → Tap (extract) → Snapshot (cache) → ETL (transform) → Target (load) → Optiply
```
