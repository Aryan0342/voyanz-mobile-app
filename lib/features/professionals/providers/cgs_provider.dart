import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True once any call has answered `cgs_acceptance_required` (1073).
///
/// The professional space cannot rely on `cgs_accepted` from
/// `GET /web/1.0/professional/profile` alone: that field was observed still
/// reporting `true` while the website gated the same account (2026-09-27). If
/// the gate waited for the boolean, the professional would be left with calls
/// that fail and no way to accept, so the refusal itself opens the gate.
///
/// Cleared once acceptance succeeds.
final cgsRequiredProvider = StateProvider<bool>((ref) => false);
