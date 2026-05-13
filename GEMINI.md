# AppFit - Design System & Technical Manifesto

This is a high-performance mobile application for personal trainers, powered by **Supabase**. The UI follows the **Neo-Industrial Glass Console** design language, a premium aesthetic that prioritizes depth, technical precision, and a "hardware-like" feel.

## 💎 The Gold Standard: Neo-Industrial Glass Console
All high-level management pages MUST follow the design patterns established in `lib/features/alunos/personal/pages/personal_aluno_perfil_page.dart`. This is the reference implementation of our Design System.

### 1. Visual Architecture (Depth Stack)
*   **Infinite Background:** Pure Deep Black (`#000000`). Never use dark grays for the main scaffold background.
*   **Atmosferic Depth:** Use a subtle top-down gradient (`AppColors.primary` with `alpha: 0.15` to `0.05` to `transparent`) to create atmospheric volume.
*   **The Glass Console (Primary Container):** 
    *   Content MUST NOT be scattered in individual cards. 
    *   Use a **SINGLE, continuous glass plate** (`Colors.white.withValues(alpha: 0.03)`) that encapsulates all sections.
    *   **Geometry:** `radius: 32` only on Top-Left and Top-Right. The plate should feel like it's "sculpted" over the black background.
    *   **Border:** A razor-thin stroke (`white.withValues(alpha: 0.05)`) to define the edge of the glass.

### 2. "Card-fobia" & Content Flow
*   **STRICT PROHIBITION:** Do not use individual cards for every piece of information. This creates "visual islands" and breaks the flow.
*   **Integration:** Sections (Metrics, Schedules, Management) live inside the Glass Console, separated only by technical spacing or subtle dividers (`alpha: 0.03`).
*   **The Performance Feed:** In workout logs, use a vertical timeline "rail" (ruler effect) to connect data points.

### 3. Typography & Micro-UX (Staff-Level)
*   **Hierarchy:** ExtraBold titles with negative letter-spacing (`-1.0` to `-1.2`) for a premium editorial look.
*   **Technical Metrics:** Use `monospace` fonts or high-weight fonts for numbers. Labels should be small (`fontSize: 9-11`) and `UPPERCASE` with high letter-spacing.
*   **Glass Pills:** Actions (like WhatsApp) must be "Pills" with low-opacity backgrounds (`alpha: 0.08`) and subtle borders. Avoid solid, high-saturation buttons unless they are primary "Call to Action" (CTA).
*   **Tactile Response:** Mandatory `HapticFeedback.lightImpact()` on all interactive elements.

### 4. The Neo-Industrial Glass Modal (Bottom Sheets)
*   **Immersive Backdrop:** Always use `BackdropFilter` (`sigma: 10-15`) with a semi-transparent black overlay to isolate the decision.
*   **Volumetric Surface:** Never use flat solid colors. Use a `LinearGradient` from a slightly illuminated dark top (`0xFF121212`) to an absolute black bottom.
*   **Modular Items:** Options must be "Modular Glass Items" (`alpha: 0.03`) with subtle borders, leading icons, and technical hierarchy (Title/Subtitle).
*   **Handle:** Include a technical "pull-handle" at the top (`white.withValues(alpha: 0.1)`) to reinforce the hardware metaphor.

## 🛠 Tech Stack & Dev Conventions

*   **Core:** Flutter (Material 3 + Custom Premium Theme).
*   **Backend:** Supabase (Auth, DB, Storage).
*   **Sliver Pattern:** Use `SliverAppBar` with `expandedHeight: 110-150` for pages that require dynamic headers.
*   **Auto-Save:** Implement "Save on Pop" logic. No manual save buttons in detail views.
*   **Alpha Values:** Use `color.withValues(alpha: ...)` instead of `withOpacity`.

## 📌 Implementation Checklist
Before refactoring any page, the agent must ask:
1. Is the background #000000?
2. Am I using a Single Glass Console instead of multiple cards?
3. Is the typography following the ExtraBold/Monospace hierarchy?
4. Are secondary actions implemented as Glass Pills?
5. (If Modal) Is it using a Volumetric Gradient and Backdrop Blur?