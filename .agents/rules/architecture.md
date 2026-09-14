# Architecture Rules: Feature-Sliced Design (FSD v2.1)

Feature-Sliced Design is an architectural methodology for scalable, maintainable frontend applications. All code added or modified in `lib/` must adhere to these rules without exception.

---

## 1. Layer Hierarchy & Strict Unidirectional Imports

```
app        (Entry, providers, theme, global routing)
 └── pages     (Full-screen views / route targets)
      └── widgets   (Composite multi-feature UI blocks)
           └── features  (Discrete user actions & interactions)
                └── entities  (Domain models & business state)
                     └── shared    (Tokens, primitives, storage, utils)
```

### The Cardinal Rule:
A file in a given layer may **ONLY** import code from layers **strictly below it**.
A layer must **NEVER** import from layers above it or beside it.

- `app` can import `pages`, `widgets`, `features`, `entities`, `shared`.
- `pages` can import `widgets`, `features`, `entities`, `shared`. (Cannot import `app`).
- `widgets` can import `features`, `entities`, `shared`. (Cannot import `app` or `pages`).
- `features` can import `entities`, `shared`. (Cannot import `app`, `pages`, or `widgets`).
- `entities` can import `shared`. (Cannot import `app`, `pages`, `widgets`, or `features`).
- `shared` can import **nothing** from the application layers.

---

## 2. Cross-Slice Isolation

Slices residing on the same layer must **NEVER** import directly from one another.

- `features/slice_a` must **never** import `features/slice_b`.
- `entities/slice_a` must **never** import `entities/slice_b`.
- If two features need to interact:
  - Compose them at the `widgets` or `pages` layer using callbacks, builders, or shared entity state.
  - Or elevate shared domain logic to an `entity` or `shared` service.

---

## 3. Automated Architecture Verification

Always run the automated import verifier. It scans `import` and `export` directives and reports upward layer imports and cross-slice imports:
```bash
dart run tool/verify_fsd.dart --strict
```
Any violation fails CI (`.github/workflows/ci.yml`).
