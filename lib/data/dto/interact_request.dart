/// Chat request DTO aligned with backend ChatRequest.
/// Backend: POST /interact/chat, JSON body { "user_id": int, "message": string }.
/// See backend/app/schemas/chat.py and frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md.

class InteractRequest {
  final int userId;
  final String message;

  const InteractRequest({
    required this.userId,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'message': message,
    };
  }
}
