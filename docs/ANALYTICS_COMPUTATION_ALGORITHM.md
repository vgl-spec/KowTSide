# KOW Admin Analytics Computation and Ranking Algorithm

## 1) Score Normalization

KOW Admin stores and compares performance on a **5-point normalized scale**.

- Easy sessions use `5` total items.
- Average sessions use `8` total items.
- Hard sessions use `10` total items.
- Writing sessions use `1` total item.

Normalization formula:

```text
normalized_score = (raw_score / total_items) * 5
```

Percent formula used in UI/export:

```text
score_percent = (normalized_score / 5) * 100
```

## 2) Passing Rule (New)

Passing is based on **50% threshold rounded up**:

```text
passing_score = ceil(total_items * 0.5)
```

Examples:

- Easy (`5`): `ceil(2.5) = 3` -> pass is `3/5`.
- Average (`8`): `ceil(4.0) = 4` -> pass is `4/8`.
- Hard (`10`): `ceil(5.0) = 5` -> pass is `5/10`.
- Writing (`1`): `ceil(0.5) = 1` -> pass is `1/1`.

## 3) Dashboard and Reports Consistency Rule

To avoid mismatch between dashboard and reports:

- Both should consume the same summary basis (`subject_level_summary`) when available.
- Overall average score and pass rate are computed with **attempt-weighted aggregation**.
- The same normalization rules above are applied in both views before rendering.

Weighted average formula:

```text
weighted_avg = sum(value_i * weight_i) / sum(weight_i)
```

Where:

- `value_i` can be normalized score or pass rate per summary row.
- `weight_i` for overall is `total_attempts`.

## 4) Proficiency Bands

Proficiency is derived from normalized score (5-point scale):

- `< 50%` -> `Needs significant support`
- `>= 50% and < 70%` -> `Needs support`
- `>= 70% and < 90%` -> `On track`
- `>= 90%` -> `Excelling`

## 5) Area Leaderboard Ranking

Area leaderboard rows are sorted in this order:

1. `average_score` descending
2. `highest_unlocked_node_index` descending
3. `sessions` descending
4. stable student-name/id tie-break

Display rank labels:

- Rank `1..3`: `Top 1`, `Top 2`, `Top 3`
- Rank `4+`: numeric rank (`4`, `5`, ...)

## 6) Visit-Date Participant Filtering

In area drilldown:

- Visit chart groups sessions by day (`YYYY-MM-DD`) within selected date range.
- Selecting/clicking a date bar filters participant list to students with sessions on that exact date.
- Ranking still uses the leaderboard order above for deterministic placement.

## 7) Unlocked Display Rule

For participant unlocked status:

- Prefer `highest_node_index` when available -> `Node <n>`.
- Otherwise fall back to highest unlocked difficulty (`Easy`, `Average`, `Hard`).
- If no unlocked progress exists -> `No unlock yet`.

This intentionally avoids placeholder values like `None`.
