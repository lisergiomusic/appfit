This is a Flutter project named `appfit`. It's a mobile application for personal trainers to manage their clients' workouts. The app uses Firebase for authentication and Firestore as its database.

## Project Overview

The application is structured with a clear separation of concerns, with features organized into directories like `auth`, `dashboard`, `alunos` (students), and `treinos` (workouts).

The main user flow is as follows:

1.  **Authentication:** Users can sign up and log in as either a "personal" (personal trainer) or "aluno" (student).
2.  **Dashboard:** After logging in, users are taken to a dashboard with a bottom navigation bar.
3.  **Features:** The dashboard provides access to the following features:
    *   **Home:** A home screen (not fully implemented in the analyzed files).
    *   **Alunos:** A section for personal trainers to manage their students (not fully implemented in the analyzed files).
    *   **Treinos:** The core feature of the app, allowing personal trainers to create, manage, and assign workout routines to their students.
    *   **Ajustes:** A settings screen (not fully implemented in the analyzed files).

The workout (`treino`) feature is well-developed and allows for a high degree of customization:

*   **Routines (`Rotinas`):** Personal trainers can create workout routines, which are essentially workout plans. Each routine has a name, an objective, and a duration.
*   **Workout Sessions:** Each routine consists of one or more workout sessions. A session has a name (e.g., "Push Day", "Leg Day") and can be assigned to a specific day of the week.
*   **Exercises:** Each workout session is made up of a list of exercises. The app provides a library of exercises to choose from, and personal trainers can add them to a session.
*   **Exercise Details:** For each exercise, the personal trainer can specify the number of series, reps, weight, and rest time. There are different types of series: warm-up, feeder, and work.

The project uses the following main dependencies:

*   `flutter`
*   `google_fonts`
*   `cupertino_icons`
*   `firebase_core`
*   `firebase_auth`
*   `cloud_firestore`

## Building and Running

To build and run this project, you will need to have Flutter installed and configured on your machine. You will also need to set up a Firebase project and add the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) files to the project.

Once the project is set up, you can run it using the following command:

```bash
flutter run
```

## Developer Mindset and UI/UX Principles

As the AI developer for this project, I must adhere to the following principles:

*   **Senior Developer Mindset:** Always think and code like a senior developer. This means prioritizing maintainability, scalability, clean code architecture, and robust error handling.
*   **UI/UX Expert:** Every change or new feature must be designed with a high level of UI/UX expertise. Interfaces should be intuitive, accessible, and follow modern design standards.
*   **Professional Design:** Avoid designs that feel like "vibecoding" (amateurish or purely aesthetic without functional depth). Every design choice should be deliberate, professional, and consistent with the app's established theme.

## Development Conventions

The code follows the standard Flutter conventions and uses the `flutter_lints` package to enforce good coding practices. The code is well-structured and uses a feature-based organization. The UI is built using Material Design components, with a custom theme defined in `lib/core/theme/app_theme.dart`.

The project makes good use of Flutter's state management capabilities, with `StatefulWidget`s being used to manage the state of the various screens. It also uses `StreamBuilder` and `FutureBuilder` to work with asynchronous data from Firebase.
