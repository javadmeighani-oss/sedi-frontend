# SEDI NOTIFICATION CONTRACT
## Version: 1.0.0
## Last Updated: 2024

---

## PURPOSE

This contract defines the **single source of truth** for notification communication between Backend and Frontend.

**Core Principle:** Backend and Frontend MUST communicate ONLY through this contract. No direct coupling allowed.

---

## 1. NOTIFICATION OBJECT

### Structure

```json
{
  "id": "string (required)",
  "type": "string (required, enum)",
  "priority": "string (required, enum)",
  "title": "string (optional)",
  "message": "string (required)",
  "actions": "array of Action objects (optional)",
  "metadata": "object (optional)",
  "created_at": "ISO 8601 datetime string (required)",
  "is_read": "boolean (required, default: false)"
}
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | ✅ | Unique notification identifier |
| `type` | string (enum) | ✅ | Notification category (see Section 2) |
| `priority` | string (enum) | ✅ | Urgency level (see Section 3) |
| `title` | string | ❌ | Short notification title |
| `message` | string | ✅ | Main notification content |
| `actions` | array | ❌ | Available user actions (see Section 4) |
| `metadata` | object | ❌ | Additional context data |
| `created_at` | ISO 8601 | ✅ | Timestamp of creation |
| `is_read` | boolean | ✅ | Read status (default: false) |

---

## 2. NOTIFICATION TYPES

### Enum Values

| Value | Description | Use Case |
|-------|-------------|----------|
| `info` | Informational message | General updates, tips |
| `alert` | Health or safety alert | Critical health data, warnings |
| `reminder` | Scheduled reminder | Medication, exercise, check-in |
| `check_in` | User engagement prompt | "How are you feeling?" |
| `achievement` | Milestone or goal reached | Goal completion, streak |

**Rules:**
- Backend MUST use only these values
- Frontend MUST handle all values gracefully
- Unknown types MUST be treated as `info`

---

## 3. PRIORITY LEVELS

### Enum Values

| Value | Description | Display Behavior |
|-------|-------------|------------------|
| `low` | Non-urgent | Standard display |
| `normal` | Standard priority | Standard display |
| `high` | Important | Emphasized display |
| `urgent` | Critical | Immediate attention required |

**Rules:**
- Backend MUST assign priority based on notification type and context
- Frontend MUST respect priority for display (no business logic)
- Default: `normal`

---

## 4. ACTIONS & CTA

### Action Object Structure

```json
{
  "id": "string (required)",
  "label": "string (required)",
  "type": "string (required, enum)",
  "payload": "object (optional)"
}
```

### Action Type Enum

| Value | Description |
|-------|-------------|
| `quick_reply` | Simple text response button |
| `navigate` | Navigate to specific screen |
| `dismiss` | Dismiss notification |
| `custom` | Custom action (defined in payload) |

### Example Actions Array

```json
{
  "actions": [
    {
      "id": "reply_yes",
      "label": "Yes",
      "type": "quick_reply",
      "payload": {
        "text": "Yes"
      }
    },
    {
      "id": "reply_no",
      "label": "No",
      "type": "quick_reply",
      "payload": {
        "text": "No"
      }
    }
  ]
}
```

**Rules:**
- Actions are optional (empty array or null = no actions)
- Frontend MUST render actions as provided (no transformation)
- Backend MUST provide valid action structures

---

## 5. FEEDBACK PAYLOAD

### Structure

When user interacts with notification, Frontend sends:

```json
{
  "notification_id": "string (required)",
  "action_id": "string (optional)",
  "reaction": "string (required, enum)",
  "feedback_text": "string (optional)",
  "timestamp": "ISO 8601 datetime string (required)"
}
```

### Reaction Enum

| Value | Description |
|-------|-------------|
| `seen` | User viewed notification |
| `interact` | User clicked an action |
| `dismiss` | User dismissed notification |
| `like` | User liked notification |
| `dislike` | User disliked notification |

**Rules:**
- `action_id` required when `reaction` is `interact`
- `feedback_text` optional but recommended for `dislike`
- Backend MUST accept all reaction types
- Frontend MUST send valid reaction values

---

## 6. METADATA OBJECT

### Structure

```json
{
  "language": "string (optional, ISO 639-1)",
  "tone": "string (optional)",
  "context": "string (optional)",
  "source": "string (optional)"
}
```

### Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `language` | string | ISO 639-1 code (e.g., "en", "fa", "ar") |
| `tone` | string | Tone indicator (e.g., "friendly", "urgent") |
| `context` | string | Context identifier (e.g., "health_check", "reminder") |
| `source` | string | Source system identifier |

**Rules:**
- All metadata fields are optional
- Frontend MUST NOT depend on metadata for core functionality
- Backend MAY include metadata for future use

---

## 7. API ENDPOINTS

### GET /notifications

**Request:**
```
GET /notifications?user_id={user_id}&limit={limit}&offset={offset}
```

**Response:**
```json
{
  "ok": true,
  "data": {
    "notifications": [
      { /* Notification Object */ }
    ],
    "total": 0,
    "unread_count": 0
  }
}
```

### POST /notifications/feedback

**Request Body:**
```json
{
  "notification_id": "string",
  "action_id": "string (optional)",
  "reaction": "string",
  "feedback_text": "string (optional)",
  "timestamp": "ISO 8601"
}
```

**Response:**
```json
{
  "ok": true,
  "data": {
    "feedback_received": true,
    "message": "Feedback recorded"
  }
}
```

---

## 8. VERSIONING

### Current Version: 1.0.0

**Version Format:** `MAJOR.MINOR.PATCH`

- **MAJOR:** Breaking changes (contract structure changes)
- **MINOR:** New fields added (backward compatible)
- **PATCH:** Clarifications, fixes (backward compatible)

### Backward Compatibility

- Frontend MUST handle missing optional fields gracefully
- Backend MUST NOT remove fields without major version bump
- New fields MUST be optional until next major version

---

## 9. VALIDATION RULES

### Backend Responsibilities

- ✅ Validate all required fields
- ✅ Ensure enum values are valid
- ✅ Return contract-compliant payloads
- ✅ Accept feedback payloads as defined

### Frontend Responsibilities

- ✅ Parse payloads without transformation
- ✅ Handle missing optional fields
- ✅ Render based on contract fields only
- ✅ Send feedback payloads as defined

---

## 10. FUTURE EXTENSIBILITY

This contract is designed to support future additions:

- **Personality injection:** Metadata fields can carry personality hints
- **Voice adaptation:** Language and tone fields support voice customization
- **Rich media:** Actions can be extended with media payloads
- **Scheduling:** Metadata can include scheduling hints (not implementation)

**Important:** Future extensions MUST maintain backward compatibility.

---

## END OF CONTRACT

