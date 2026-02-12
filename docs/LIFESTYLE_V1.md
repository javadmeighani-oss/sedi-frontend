# Lifestyle Summary v1 (Stage 17.2)

Chat-only display of lifestyle summary. No standalone screen or top-level entrypoint.

## How to Trigger

Send one of these as a chat message:

| Language | Commands |
|----------|----------|
| English | `/lifestyle` or `lifestyle summary` |
| Persian | `/سبک` or `خلاصه سبک زندگی` |
| Arabic | `/نمط` or `ملخص نمط الحياة` |

The summary is shown in a modal bottom sheet. The message is not sent to the backend.

## Behavior

- **Cache**: Latest summary is cached in-memory for the session. Refetch only when user triggers again or taps refresh.
- **Loading**: Shimmer/progress indicator while loading.
- **Empty**: Message when no lifestyle data yet.
- **Error**: Retry button on failure.
- **Sections**: First 2 sections shown by default; expand to show more. Footer shows "Based on X facts and last Y days".
- **"Why this?" (Stage 17.4)**: When the backend returns `sources` for sections, a "Why this?" affordance appears. Tapping it opens a dialog with type-based explanations (e.g., "Your baseline & goals", "Your preferences/settings"). **Safety rule**: Raw memory text, source ids, and labels are never displayed. Only high-level type descriptions and counts are shown. If sources are missing (backward compatible), "Why this?" is hidden.

## API

- `GET /lifestyle/summary?user_id=...&lang=...` — Backend Stage 17.1
