# Notification Contract (Frontend Reference)

> **⚠️ IMPORTANT:** This is a reference copy. The **single source of truth** is located at:
> **`backend/docs/notification_contract.md`**
>
> Always refer to the backend version for the latest contract definition.

---

## Quick Reference

This document provides a quick reference for frontend developers. For the complete contract specification, see `../../backend/docs/notification_contract.md`.

### Notification Object Structure

```json
{
  "id": "string (required)",
  "type": "info" | "alert" | "reminder" | "check_in" | "achievement",
  "priority": "low" | "normal" | "high" | "urgent",
  "title": "string | null",
  "message": "string",
  "actions": [Action] | null,
  "metadata": NotificationMetadata | null,
  "created_at": "ISO 8601 datetime string",
  "is_read": boolean
}
```

### Action Object

```json
{
  "id": "string",
  "label": "string",
  "type": "quick_reply" | "navigate" | "dismiss" | "custom",
  "payload": object | null
}
```

### Feedback Payload

```json
{
  "notification_id": "string",
  "action_id": "string | null",
  "reaction": "seen" | "interact" | "dismiss" | "like" | "dislike",
  "feedback_text": "string | null",
  "timestamp": "ISO 8601 datetime string"
}
```

### API Endpoints

- **GET** `/notifications?user_id={user_id}&limit={limit}&offset={offset}`
- **POST** `/notifications/feedback`

---

For complete documentation, see: `../../backend/docs/notification_contract.md`

