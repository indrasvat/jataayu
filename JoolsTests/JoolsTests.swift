import Testing
@testable import Jools
import JoolsKit

@Suite("Jools App Tests")
struct JoolsTests {
    @Test("App launches successfully")
    func appLaunches() async throws {
        // Basic smoke test
        #expect(true)
    }

    @Test("State machine maps clarifying agent message to needs input")
    func stateMachineMapsClarifyingMessageToNeedsInput() throws {
        let activities = [
            makeActivity(
                id: "agent-question",
                type: .agentMessaged,
                createdAt: Date(),
                content: ActivityContentDTO(
                    message: "Before I proceed, could you clarify whether you want a chat reply or a file output?"
                )
            )
        ]

        let resolvedState = SessionStateMachine.resolve(apiState: .unspecified, activities: activities)

        #expect(resolvedState == .awaitingUserInput)
        #expect(resolvedState.sessionState == .awaitingUserInput)
    }

    @Test("State machine maps generated plan to awaiting approval")
    func stateMachineMapsGeneratedPlanToAwaitingApproval() throws {
        let activities = [
            makeActivity(
                id: "plan",
                type: .planGenerated,
                createdAt: Date(),
                content: ActivityContentDTO(
                    plan: PlanDTO(
                        id: "plan-1",
                        steps: [
                            PlanStepDTO(
                                id: "step-1",
                                title: "Inspect the repo",
                                description: "Read the code paths first.",
                                status: "PENDING",
                                index: 0
                            )
                        ]
                    )
                )
            )
        ]

        let resolvedState = SessionStateMachine.resolve(apiState: .inProgress, activities: activities)

        #expect(resolvedState == .awaitingPlanApproval)
    }

    @Test("State machine advances from user reply to working and then completed")
    func stateMachineAdvancesToCompletion() throws {
        let baseTime = Date()
        let activities = [
            makeActivity(
                id: "question",
                type: .agentMessaged,
                createdAt: baseTime,
                content: ActivityContentDTO(
                    message: "Could you confirm the preferred output format?"
                )
            ),
            makeActivity(
                id: "reply",
                type: .userMessaged,
                createdAt: baseTime.addingTimeInterval(5),
                content: ActivityContentDTO(message: "Reply directly in chat.")
            ),
            makeActivity(
                id: "progress",
                type: .progressUpdated,
                createdAt: baseTime.addingTimeInterval(10),
                content: ActivityContentDTO(
                    progress: "Reviewing the codebase",
                    progressTitle: "Reviewing the codebase",
                    progressDescription: "Reading the main entry points."
                )
            ),
            makeActivity(
                id: "done",
                type: .sessionCompleted,
                createdAt: baseTime.addingTimeInterval(20),
                content: ActivityContentDTO(summary: "Finished successfully.")
            )
        ]

        let resolvedState = SessionStateMachine.resolve(apiState: .unspecified, activities: activities)

        #expect(resolvedState == .completed)
    }

    @Test("Effective session state prefers timeline over stale starting state")
    func effectiveStatePrefersTimelineOverStartingState() throws {
        let session = SessionEntity(
            id: "session",
            title: "Repository Overview",
            prompt: "Inspect the repository",
            state: .unspecified,
            sourceId: "sources/test",
            sourceBranch: "main",
            automationMode: .unspecified,
            requirePlanApproval: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        let activity = makeActivity(
            id: "agent-question",
            type: .agentMessaged,
            createdAt: Date(),
            content: ActivityContentDTO(
                message: "Would you like the overview in chat, or should I write it to a file?"
            )
        )
        activity.session = session
        session.activities = [activity]

        #expect(session.effectiveDisplayState == .awaitingUserInput)
        #expect(session.effectiveState == .awaitingUserInput)
    }

    private func makeActivity(
        id: String,
        type: ActivityType,
        createdAt: Date,
        content: ActivityContentDTO
    ) -> ActivityEntity {
        let contentJSON = try! JSONEncoder().encode(content)
        return ActivityEntity(
            id: id,
            type: type,
            createdAt: createdAt,
            contentJSON: contentJSON
        )
    }
}
