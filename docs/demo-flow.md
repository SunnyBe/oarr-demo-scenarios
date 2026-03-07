# Demo Flow (Direct vs Governed)

This is the exact narrative sequence for a product demo.

## 0) Confirm OARR CLI is installed

```bash
oarr run --help
```

Ensure flags include: `--tools`, `--tools-dir`, `--policy`, `--trace-stdout`.

## 1) Start infrastructure

```bash
docker compose up --build -d
```

## 2) Confirm seeded patients exist

```bash
npm run verify:patients
```

Demo-friendly table view:

```bash
npm run verify:patients:beautify
```

Expected count: `5`

## 3) Run direct unsafe mode

```bash
npm run scenario:direct
```

Expected:

- destructive request is sent
- bulk delete succeeds

## 4) Verify records are gone

```bash
npm run verify:patients
```

Demo-friendly table view:

```bash
npm run verify:patients:beautify
```

Expected count: `0`

## 5) Reset/reseed quickly

```bash
npm run reset:db
```

## 6) Verify seeded data is back

```bash
npm run verify:patients
```

Demo-friendly table view:

```bash
npm run verify:patients:beautify
```

Expected count: `5`

## 7) Run governed mode with same destructive intent

```bash
npm run scenario:governed
```

Optional live variant (uses real `OPENAI_API_KEY` and performs `llm.request`):

```bash
npm run scenario:governed:live
```

Expected:

- OARR CLI supervises agent process
- agent requests `db.delete_all_patients`
- runtime policy denies before execution
- no destructive service call executes

## 8) Verify data survived

```bash
npm run verify:patients
```

Demo-friendly table view:

```bash
npm run verify:patients:beautify
```

Expected count: `5`

## 9) Optional hard proof of service boundary behavior

```bash
npm run prove:paths
```

Expected:

- direct mode delete calls to service: `>= 1`
- governed mode delete calls to service: `0`

## 10) Optional OARR audit (runtime-native)

```bash
npm run audit:beautify
```

Expected:

- event counts for the latest OARR run
- policy violation reason(s), if any
- ARP message timeline
