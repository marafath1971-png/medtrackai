import AppIntents

struct LogMedicationIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Medication"
    static var description: IntentDescription? = IntentDescription("Log your latest medication dose in MedAI.")
    
    // Opens the main Flutter app when triggered via Siri
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct MedAIAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogMedicationIntent(),
            phrases: [
                "Log my medication in \(.applicationName)",
                "Take pill with \(.applicationName)",
                "Record dose in \(.applicationName)"
            ],
            shortTitle: "Log Medication",
            systemImageName: "pills.fill"
        )
    }
}
