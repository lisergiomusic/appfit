# AppFit - Design System & Technical Manifesto

This is a high-performance mobile application for personal trainers, powered by **Supabase**. The UI follows the **Neo-Industrial Glass Console** design language, a premium aesthetic that prioritizes depth, technical precision, and a "hardware-like" feel.

## 💎 The Gold Standard: Neo-Industrial Glass Console
All high-level management pages MUST follow the design patterns established in `lib/features/alunos/personal/pages/personal_aluno_perfil_page.dart`. This is the reference implementation of our Design System.

### 1. Visual Architecture (Depth Stack)
*   **Infinite Background:** Pure Deep Black (`AppColors.surfaceBlack`). Never use dark grays for the main scaffold background.
*   **Atmosferic Depth:** Use a top-down gradient (`AppColors.primary` with `GlassTokens.opacityAtmosphere` to `opacityAtmosphereSubtle`) to create volume.
*   **The Glass Console (Primary Container):** 
    *   Content MUST NOT be scattered in individual cards. 
    *   Use a **SINGLE, continuous glass plate** (`GlassTokens.opacityConsole`) that encapsulates all sections.
    *   **Geometry:** Use `GlassTokens.consoleRadius`. The plate should feel like it's "sculpted" over the black background.
    *   **Infinite Bottom:** For main scrolls, use `SliverFillRemaining` and remove the bottom border of the console to create a feeling of infinite depth.

### 2. "Card-fobia" & Content Flow
*   **STRICT PROHIBITION:** Do not use individual cards for every piece of information. This breaks the Neo-Industrial immersion.
*   **Integration:** Sections (Metrics, Schedules, Management) live inside the Glass Console, separated only by technical spacing or subtle dividers (`GlassTokens.opacityConsole`).

### 3. Typography: Human vs. Machine (Staff-Level)
*   **The Human Touch (Content):** Nomes próprios, títulos de treinos e ações narrativas devem usar **Title Case** (ex: `Sergio Silva`, `Hipertrofia A`). Isso reduz a fadiga visual e traz elegância.
*   **The Machine Label (Technical):** Rótulos de hardware, métricas de telemetria, cabeçalhos de seção e tags de status devem usar **ALL CAPS** com `letterSpacing` (ex: `GESTÃO`, `PLANILHA ATUAL`, `OK`).
*   **Technical Value:** Use `AppTheme.telemetryValue` for numbers and performance data.

### 4. The Neo-Industrial Glass Modal (Bottom Sheets)
*   **Immersive Backdrop:** Always use `BackdropFilter` (`GlassTokens.blurStandard`) with a semi-transparent black overlay.
*   **Volumetric Surface:** Use a `LinearGradient` from `GlassTokens.modalGradientTop` to `modalGradientBottom` to simulate physical mass.
*   **Modular Items:** Options must be "Modular Glass Items" (`GlassTokens.opacityConsole`) with subtle borders.

### 5. Premium Action Components (The Glass Buttons)
*   **Tactile Response:** Mandatory `AnimatedScale` (squish effect) on touch.
*   **Translucent Fill:** Primary actions (`GlassPrimaryButton`) should use `alpha: 0.85`. Secondary/Icon actions (`GlassIconButton`) should use `alpha: 0.08` to `0.1`.
*   **Internal Blur:** Buttons must contain their own `BackdropFilter` to ensure they feel like physical glass pieces floating over the content.
*   **Geometry:** High corner radius (Pills or Circles) to contrast with the more rigid geometry of the Console.

## 🛠 Tech Stack & Design Tokens

*   **Core:** Flutter (Material 3 + Custom Premium Theme).
*   **GlassTokens:** Centralizes all opacities, blurs, and glass geometry. **NEVER use hardcoded alpha values.**
*   **SpacingTokens:** Follow the semantic scale (`xs` to `massive`).
*   **Sliver Architecture:** Mandatory for premium pages. Use `SliverAppBar` with `FlexibleSpaceBar` and `collapseProgress` calculations for spatial transitions.
*   **Tactile Response:** Mandatory `HapticFeedback.lightImpact()` on all interactive elements.

## 📌 Implementation Checklist
Before refactoring any page, the agent must ask:
1. Is the background absolute black?
2. Am I using a Single Glass Console (Card-fobia check)?
3. Is the typography respecting the **Human vs. Machine** hierarchy?
4. Are all visual constants using **Design Tokens** (Glass/Spacing)?
5. (If Scrollable) Is it using a fluid Sliver architecture?
6. (If Modal) Is it using a Volumetric Gradient and Backdrop Blur?
7. (If Action) Is it using **GlassPrimaryButton** or **GlassIconButton** with tactile scale?