# SEDI - NATURAL CONVERSATION FLOW
## User-Friendly, Security-Aware Chat System
## Date: 2024

---

## OVERVIEW

This document describes the new natural conversation flow where:
- **Sedi starts the conversation** (proactive)
- **No hard onboarding** (no forced name/password at start)
- **Natural name collection** (AI-driven, during conversation)
- **Security password setup** (after familiarity, for security)
- **Suspicious behavior detection** (AI-based, triggers security check)

---

## CONVERSATION FLOW

### Phase 1: Initial Contact (Proactive Start)

```
1. User opens app
   ↓
2. Sedi proactively starts conversation:
   - "Hello! I'm Sedi, your intelligent health companion 🌿"
   - "I'm happy to talk with you! Would you like to get to know each other better?"
   ↓
3. User can respond naturally
   ↓
4. Conversation continues without requiring name/password
```

### Phase 2: Natural Name Collection (AI-Driven)

```
After 2+ conversations:
   ↓
Sedi naturally asks (if name not collected):
   - "Would you like to tell me your name? I'd love to call you by name 😊"
   ↓
User provides name (naturally in conversation)
   ↓
Sedi acknowledges:
   - "Nice to meet you [name]! 😊"
```

### Phase 3: Security Password Setup (After Familiarity)

```
After 3+ conversations (user is familiar):
   ↓
Sedi explains security need:
   - "Now that we know each other better, for better security, 
      it's good to set a security password. If I ever notice 
      suspicious behavior, I'll ask you for the password. 
      Would you like to choose a password?"
   ↓
User sets password
   ↓
Password saved in UserProfile
```

### Phase 4: Suspicious Behavior Detection

```
During conversation:
   ↓
Backend AI detects suspicious behavior:
   - Sudden language change
   - Unusual request patterns
   - Inconsistent behavior
   ↓
Backend returns: requires_security_check = true
   ↓
Frontend triggers security verification:
   - "To verify your identity, please enter your security password:"
   ↓
User enters password
   ↓
If correct: Continue conversation
If incorrect: Ask again
```

---

## DATA STRUCTURE

### UserProfile Model

```dart
class UserProfile {
  String? name;                    // Optional - collected naturally
  String? securityPassword;       // Optional - set after familiarity
  String preferredLanguage;        // Auto-detected
  bool hasSecurityPassword;        // Whether password is set
  DateTime? securityPasswordSetAt; // When password was set
  int conversationCount;           // Number of conversations
  bool requiresSecurityCheck;      // Security check needed?
}
```

### Storage

- **Location**: `lib/data/models/user_profile.dart`
- **Manager**: `lib/core/utils/user_profile_manager.dart`
- **Persistence**: SharedPreferences (JSON)

---

## BACKEND CHANGES

### Endpoint: POST /interact/chat

**Before:**
- `name` and `secret_key` were required
- Returned 404 if user not found

**After:**
- `name` and `secret_key` are **optional**
- New users can chat without credentials
- Returns `requires_security_check` flag for suspicious behavior

**Response:**
```json
{
  "message": "Sedi's response",
  "language": "en",
  "user_id": null,  // null for new users
  "timestamp": "2024-...",
  "requires_security_check": false  // true if suspicious
}
```

---

## FRONTEND CHANGES

### ChatController

**Removed:**
- Hard onboarding (askingName, askingPassword states)
- Forced name/password collection at start

**Added:**
- Proactive conversation start
- Natural name collection (AI-driven)
- Security password setup (after familiarity)
- Security verification (when suspicious behavior detected)

**New States:**
- `initializing` - Sedi starting conversation
- `chatting` - Normal conversation
- `askingName` - Natural name collection
- `askingSecurityPassword` - Security password setup
- `verifyingSecurity` - Security verification

### ChatService

**Changed:**
- `sendMessage()` now accepts optional `userName` and `userPassword`
- Returns `SECURITY_CHECK_REQUIRED` if backend detects suspicious behavior
- Works without credentials for new users

---

## AI INTEGRATION

### Name Collection Timing

- Triggered after 2+ conversations
- Natural in conversation flow
- User can decline or provide name

### Security Password Setup Timing

- Triggered after 3+ conversations (user is familiar)
- Explained naturally by Sedi
- User understands the security need

### Suspicious Behavior Detection

**Backend AI analyzes:**
- Message patterns
- Language consistency
- Request patterns
- Behavioral changes

**Triggers security check when:**
- Sudden language change
- Unusual requests
- Inconsistent behavior patterns

---

## SECURITY MODEL

### Password Purpose

- **NOT for initial authentication**
- **FOR suspicious behavior verification**
- Set **after** user familiarity
- Used **only when** suspicious behavior detected

### Flow

```
Normal Conversation
   ↓
AI detects suspicious behavior
   ↓
Security check triggered
   ↓
User enters password
   ↓
If correct: Continue
If incorrect: Ask again (max 3 attempts)
```

---

## USER EXPERIENCE

### Benefits

1. **Natural Start**: No forced forms, Sedi starts talking
2. **Friendly**: Name collection feels natural, not like a form
3. **Secure**: Password setup explained, user understands why
4. **Trust**: Security check only when needed, not intrusive

### Example Flow

```
User: Opens app
Sedi: "Hello! I'm Sedi, your intelligent health companion 🌿"
Sedi: "I'm happy to talk with you! Would you like to get to know each other better?"
User: "Yes, I'd like that"
Sedi: "Great! What would you like to talk about?"
[After 2 conversations]
Sedi: "Would you like to tell me your name? I'd love to call you by name 😊"
User: "My name is Ahmad"
Sedi: "Nice to meet you Ahmad! 😊"
[After 3 conversations]
Sedi: "Now that we know each other better, for better security, 
       it's good to set a security password..."
User: "Okay, my password is..."
Sedi: "Great! Your security password is set. Now we can continue with more confidence 😊"
```

---

## IMPLEMENTATION STATUS

### ✅ Completed

- UserProfile model created
- UserProfileManager for persistence
- ChatController updated for proactive start
- ChatService updated for optional credentials
- Backend endpoint updated for optional auth
- Security verification flow implemented

### ⏳ Pending (Future Enhancements)

- AI-based name collection timing (currently after 2 messages)
- AI-based suspicious behavior detection (backend placeholder)
- Advanced security patterns (language change, request patterns)

---

## FILES MODIFIED

### Frontend
- `lib/data/models/user_profile.dart` (created)
- `lib/core/utils/user_profile_manager.dart` (created)
- `lib/features/chat/state/chat_controller.dart` (major refactor)
- `lib/features/chat/chat_service.dart` (updated)

### Backend
- `app/routers/interact.py` (optional auth)
- `app/schemas.py` (security flag added)

---

## END OF DOCUMENT

