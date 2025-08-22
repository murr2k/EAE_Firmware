# Techniques and Patterns from EAE Firmware Project

## CI/CD Pipeline Insights

### GitHub Actions Compatibility
- Ubuntu 24.04 (latest) has different package names than older versions
- Use version-agnostic packages when possible: `clang` instead of `clang-12`
- Ubuntu 20.04 runners often get stuck in queue - consider removing from matrix

### Workflow Dependencies
```yaml
# Don't make summary jobs wait for slow/optional tests
needs: [cpp-build-test, python-test, static-analysis, documentation]
# NOT: needs: [... sanitizer-tests] if they're slow
```

### Exit Code Handling
```bash
# Ignore non-critical exit codes
lcov --list coverage.info || echo "Coverage report generated (ignoring exit code)"
```

## Git Workflow Patterns

### Comprehensive Commit Messages
```bash
git commit -m "$(cat <<'EOF'
feat: add comprehensive CI/CD results collection

- Implementation details...
- Benefits...

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### Rebasing on Push Conflicts
```bash
git pull --rebase origin main
git push origin main
```

## Testing Strategies

### Python Test Creation
- Create test file inline during CI to ensure imports work
- Test both functionality and data structures
- Use simple assertion-based tests for quick validation

### C++ Testing Patterns
- Use Google Test with FetchContent for automatic download
- Test edge cases: initialization, boundaries, state transitions
- Mock time-based tests with controlled delays

## Documentation Best Practices

### Multiple Documentation Levels
1. README.md - Main project overview
2. REVIEWER_QA.md - Anticipate reviewer questions
3. BUILD_INSTRUCTIONS.md - Quick start for submissions
4. WORKFLOW_FAILURE_ANALYSIS.md - Living troubleshooting doc

### Issue Templates
- Create issues for both bugs and future features
- Use labels: bug, enhancement, documentation
- Reference issues in commits: "fixes #8"

## Build System

### CMake with FetchContent
```cmake
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/release-1.12.1.zip
)
FetchContent_MakeAvailable(googletest)
```

### Static Linking
- Use FetchContent for dependencies
- Build all dependencies from source
- Results in single portable executable

## Code Patterns

### Thread-Safe State Management
```cpp
std::atomic<bool> running_{false};
std::atomic<SystemState> currentState_{SystemState::OFF};
```

### PID Controller with Anti-Windup
- Clamp integral term to prevent windup
- Reset integral on large errors
- Separate output limits from integral limits

## Slack Integration

### Rich Webhook Notifications
- Use color coding: green (success), red (failure), yellow (partial)
- Include clickable links to runs and commits
- Show individual job results
- Only notify on main workflow completion

## Badge Management

### Working Badges
- Release version
- License
- Last commit
- Open issues count
- Static badges (C++ version, platform)

### Problematic Badges
- Tokei (lines of code) - service discontinued
- Duplicate workflow badges
- Branch-specific badges may show "no status"

## Submission Preparation

### Comprehensive Zip Package
```text
Include everything needed:
- Source code
- Build scripts
- Tests
- Documentation
- Simple build instructions
- License file
```

### Dedicated Build Instructions
- Assume minimal knowledge
- Provide copy-paste commands
- Include troubleshooting section
- Show expected output

## Performance Optimizations

### CI/CD Speed
- Remove slow/unreliable OS versions from matrix
- Run independent jobs in parallel
- Cache dependencies when possible
- Use ninja-build for faster compilation

## Error Handling Patterns

### Safety-First Design
```cpp
if (!coolantLevelOk) {
    transitionTo(SystemState::EMERGENCY_STOP);
    return;
}
```

### Graceful Degradation
- Multiple states: OFF, RUNNING, ERROR, EMERGENCY_STOP
- Clear state transitions with guards
- Timeout handling for all operations