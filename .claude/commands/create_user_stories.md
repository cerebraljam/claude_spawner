Your role is to extract user stories from project documentation and create a comprehensive user story tracking file with test coverage requirements.

## User Story Extraction Requirements

**CRITICAL**: User stories must cover complete user journeys from start to finish, not just technical features.

### User Story Identification Process:
1. **Read all project documentation** - especially user interaction flows, workflow descriptions, and example scenarios
2. **Identify distinct user journeys** - complete flows from user action to final outcome
3. **Extract interaction patterns** - how users communicate with the system and what responses they expect
4. **Map dependencies** - which user stories depend on others being implemented first
5. **Define test criteria** - how each user story can be validated end-to-end

### User Story Structure Requirements:
- **User Story ID**: Unique identifier (US001, US002, etc.)
- **User Journey Title**: Clear description of the complete flow
- **Trigger**: What initiates this user story (user action, system event, etc.)
- **Steps**: Detailed step-by-step flow from trigger to completion
- **Expected Outcome**: What the user should experience at the end
- **Test Criteria**: How to validate this story works correctly
- **Prerequisites**: Which other user stories or technical foundations must be complete first
- **Foundation Layer**: Which technical foundation layers this story depends on

## User Story File Creation Process

To achieve this goal:
1. Read all project documentation files (PROJECT.md, PROJECT_CLEAN.md, SPECS.md, etc.)
2. **Identify user interaction flows** described in the documentation
3. **Extract complete user journeys** - from initial user action to final system response
4. **Map story dependencies** - which stories must work before others can be tested
5. **Create test validation criteria** - specific ways to verify each story works
6. Create the `TASK-USER-STORY.md` file with comprehensive user story coverage

### User Story Writing Rules:
- **Each story = one complete user journey** from start to finish
- **Include realistic test scenarios**: Actual messages/actions users would take
- **No partial flows**: Story must be testable end-to-end independently
- **Foundation dependencies**: Specify which technical layers must be working first
- **Test validation**: Clear criteria for how to verify the story works correctly

### Foundation Test Integration:
- **Map to foundation layers**: Which foundation tests must pass before user story testing
- **Integration test criteria**: How user stories integrate with technical foundation
- **End-to-end validation**: Complete workflows that prove the system works as intended

### Example User Story Structure:
```
**US001: First User Contact & Introduction**
- **Trigger**: User sends "hi" message to the Slack bot
- **Steps**: 
  1. User initiates DM with the Slack bot
  2. The bot detects first contact 
  3. The bot sends introduction message
  4. The bot creates profile creation thread
  5. User completes onboarding questions
- **Expected Outcome**: User has complete profile and understands how to use the bot
- **Test Criteria**: Simulate user saying "hi" → verify introduction → complete profile creation → confirm help instructions sent
- **Prerequisites**: Slack integration, user management, LLM integration foundations
- **Foundation Layers**: 1-8 (Database through LLM Integration)
```

### Validation Requirements:
- **Every user interaction** mentioned in project docs should have a corresponding user story
- **Complete coverage** of all user-facing workflows
- **Testable scenarios** with specific validation criteria
- **Foundation mapping** showing technical dependencies

A user story test system will read this `TASK-USER-STORY.md` file and create end-to-end validation tests that prove the complete user experience works as intended, building on top of the technical foundation tests.

# Finally
Insert reminders in the TASKS.md between laeyrs to ensure that the user stories are implemented before moving to the following layer