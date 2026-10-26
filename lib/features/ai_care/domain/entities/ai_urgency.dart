/// Re-exports the shared urgency enum so code within this feature can
/// `import '.../domain/entities/ai_urgency.dart'` without needing to know
/// it's physically defined in `shared/models` — see the note in
/// `shared/models/ai_urgency.dart` for why it lives there.
library;

export '../../../../shared/models/ai_urgency.dart';
