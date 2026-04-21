/// Categorical user state derived by the BehavioralStateMachine (Story 5.2).
///
/// Transitions (Story 5.2):
///   active → fatigued  : RPE avg > 8 for last 2 sessions (FR23)
///   fatigued → atRisk  : missedSessions >= 2 (FR23)
///   atRisk/fatigued → recovering : 2 consecutive sessions, RPE ≤ 7 (FR23)
///   recovering → active : 3 sessions, RPE avg ≤ 6.5, streak ≥ 3 (FR23)
enum BehavioralState { active, fatigued, atRisk, recovering }
