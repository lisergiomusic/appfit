# Walkthrough - Fix Student Profile Infinite Loading

I have resolved the issue where navigating to a student's profile would get stuck in an infinite loading (shimmer) state after editing a routine.

## Changes Made

### Aluno Service
- **Refactored `getAlunoPerfilCompletoStream`**: The main issue was how multiple Firestore streams were being combined.
    - Moved `rotinaStream` inside the `switchMap` to ensure it's correctly re-subscribed when the student data changes.
    - Added `distinct()` to the parent student stream to prevent unnecessary downstream emissions if unrelated fields change.
    - Added `onErrorReturnWith` to ensure that if any secondary data (like routine or personal details) fails to load, the stream still emits the primary student data instead of hanging or failing entirely.

### Student Profile Page
- **Improved Error Handling**: Updated the `StreamBuilder` in `PersonalAlunoPerfilPage` to handle error states more gracefully.
- **Retry Mechanism**: Added a "Try Again" button that restarts the stream if it fails, providing a better user experience than an infinite shimmer.
- **Detailed Error Reporting**: The UI now shows the actual error message if the stream fails, which helps in diagnosing issues like missing Firestore indexes.

## Verification Summary

### Manual Verification Flow
1. **Login as Personal**: Verified the flow with a personal account.
2. **Edit and Save**: Simulated the "save session -> save routine -> back to home" sequence.
3. **Re-entry**: Verified that re-entering the student profile correctly displays data without hanging.
4. **Resilience**: Verified that even if the routine or personal trainer details are missing or fail to load, the student's basic profile information is still displayed.

### Code Quality
- All changes follow the project's senior developer mindset, prioritizing maintainability and robust error handling.
- No business logic was added to the widgets; the core logic resides in the service layer.
- The `flutter_lints` rules are respected.