# Watch Your Money — Comprehensive UI/UX, Design & AI Slop Audit

**Date:** 2026-10-26  
**Auditor Role:** Senior UI/UX Designer, Design Engineer, AI Slop Auditor  
**App Version:** Post-migration (balance tracking, custom dialogs, Dynamic Island alerts)

---

## A. Executive Summary

| Dimension | Score (1–10) | Verdict |
|-----------|--------------|---------|
| **Visual Design & Design Language** | **8.5/10** | Exceptional neumorphic Onyx theme; cohesive dark monochrome identity; sophisticated shadow system |
| **AI Slop Detection & Code Quality** | **7.5/10** | Minimal hallucinated patterns; some copy-paste drift in widgets; hardcoded strings need extraction |
| **UI Consistency & Component Reuse** | **6.5/10** | Core components exist (NeumorphicContainer, DynamicIsland) but underused; repeated inline styling; no design token system |
| **User Experience (Financial App)** | **8.0/10** | Strong offline-first architecture; good balance tracking; some friction in category management; missing recurring tx support |
| **Responsive Design & Accessibility** | **5.5/10** | Fixed breakpoints only; no semantic labels on icon-only buttons; Dynamic Island lacks screen reader support; text scaling untested |
| **Implementation Quality & Architecture** | **8.5/10** | Clean Riverpod + Repository pattern; Hive + Supabase dual-write; proper code generation; build passes clean |

**Overall: 7.5/10** — A polished, opinionated financial app with a distinct visual identity. The foundation is solid but component discipline and accessibility need investment before scale.

---

## B. Visual Design & Design Language

### Strengths
1. **Onyx Neumorphism System** (`app_colors.dart`, `neumorphic_container.dart`)
   - Three elevation states: `raised` (standard), `inset` (pressed), `elevated` (floating)
   - Dual-shadow formula: `shadowLight` (#1E1F26 @ 0.06) + `shadowDark` (#000000 @ 0.6) creates convincing depth
   - Color palette is intentional: `surfaceCanvas` (#0A0A0A) → `surfaceContainer` (#121316) → `surfaceContainerHigh` (#1C1D22)
   - Semantic colors: `positive` (#10B981), `negative` (#F43F5E), `cardColor` (#6366F1), `cashColor` (#10B981), `goldAccent` (#FBBF24)

2. **Typography** (`app_theme.dart`)
   - Google Fonts Inter with `TextTheme` overrides for display/headline/body/label
   - Letter-spacing adjustments (`-0.3` on headlines, `+1.2` on labels) show attention to optical balance
   - `fontWeight.w700`/`w800` used deliberately for hierarchy

3. **Micro-interactions** (`flutter_animate` throughout)
   - Consistent `.fadeIn().slideY(begin: 0.05)` entrance pattern
   - Staggered delays (50ms, 100ms, 150ms) create choreography
   - Pulse animation on AI avatar, scale on press feedback

### Issues
| # | Issue | Location | Severity |
|---|-------|----------|----------|
| B1 | **Hardcoded color literals** bypass design tokens | `ai_assistant_screen.dart:289` (`Color(0x0CFFFFFF)`), `statistics_screen.dart:518` (`Color(0x14FFFFFF)`), `adjust_balance_modal.dart:264` (`Color(0x66000000)`) | Medium |
| B2 | **Inconsistent border radii** — 4, 8, 10, 12, 14, 16, 18, 20, 24, 28, 999 used across screens | Multiple files | Medium |
| B3 | **No elevation token system** — `NeumorphicContainer` has 3 states but screens reimplement shadows inline | `statistics_screen.dart:470`, `adjust_balance_modal.dart:262` | Low |
| B4 | **Chart palette hardcoded** in `AppColors.chartPalette` but not exposed as semantic tokens | `app_colors.dart` | Low |

---

## C. AI Slop Detection & Code Quality

### Findings: Minimal AI Slop — Code is largely hand-crafted with intentional patterns

**Positive Signals:**
- No generic "TODO: implement" comments left in production code
- No hallucinated imports or non-existent APIs
- Riverpod providers follow established patterns (`FutureProvider`, `StateNotifierProvider`)
- Hive adapters properly generated (`build_runner` used correctly)
- Supabase serialization uses explicit `toSupabaseJson()` / `fromJson()` — no reflection magic

**AI Slop Patterns Detected:**
| # | Pattern | Evidence | File |
|---|---------|----------|------|
| C1 | **Copy-paste widget blocks** with minor variations | `_buildPeriodBtn` vs `_buildChartTypeBtn` in `statistics_screen.dart` (lines 311-365) — 90% identical structure | `statistics_screen.dart` |
| C2 | **Magic numbers in animations** | `Duration(milliseconds: 200)`, `300`, `400`, `250` scattered; no `AppDurations` constants | Multiple |
| C3 | **Inline formatters duplicated** | `ThousandsSeparatorInputFormatter` used in `add_transaction_modal.dart` AND `adjust_balance_modal.dart` — same logic, no shared utility | Two files |
| C4 | **Hardcoded Indonesian strings** in UI logic | "Mgg 1", "Penyesuaian Saldo", "DOMPOT KARTU" — not in `AppTranslations` | `statistics_screen.dart:467`, `adjust_balance_modal.dart:108` |
| C5 | **Dead code / commented blocks** | 32-line backfill SQL commented in migration; `if (!_isDev) return const SizedBox.shrink();` hides dev input | `supabase_migration...sql`, `ai_assistant_screen.dart:499` |

**Code Smells (Non-AI but Real):**
- `statistics_screen.dart` = 800 lines — violates single responsibility (chart logic + UI + filtering)
- `ai_assistant_screen.dart` = 940 lines — chat logic, streaming, formatting, UI all in one class
- `adjust_balance_modal.dart` = 670 lines — form, calculation, presets, transaction creation

---

## D. UI Consistency & Component Reuse

### Component Inventory
| Component | Status | Used In | Reuse Score |
|-----------|--------|---------|-------------|
| `NeumorphicContainer` | ✅ Core primitive | 12+ screens | **High** |
| `DynamicIslandAlert` | ✅ Global toast | 6+ screens | **High** |
| `CustomDialog` | ✅ Dialog system | 3 screens (partial) | **Medium** |
| `CurrencyFormatter` | ✅ Utility | All money displays | **High** |
| **Missing: `AppButton`** | ❌ | Buttons reimplemented everywhere | **Critical Gap** |
| **Missing: `AppTextField`** | ❌ | Input decoration repeated 15+ times | **Critical Gap** |
| **Missing: `AppCard` / `SectionContainer`** | ❌ | `NeumorphicContainer` with padding repeated | **High Gap** |
| **Missing: `Chip` / `SegmentedControl`** | ❌ | Period/chart selectors rebuilt in each screen | **High Gap** |

### Inconsistencies Found
1. **Button Styles** — 5 distinct implementations:
   - `NeumorphicContainer(isElevated: true, backgroundColor: AppColors.accentWhite)` — `adjust_balance_modal.dart:589`
   - `NeumorphicContainer(backgroundColor: AppColors.positive)` — `add_transaction_modal.dart`
   - `Container` with `BoxDecoration` + `BoxShadow` — `statistics_screen.dart` (chart legends)
   - `TextButton` with custom style — `dynamic_island_alert.dart:346`
   - `ElevatedButton` — nowhere (good) but `GestureDetector` + `Container` pattern inconsistent

2. **TextField Decoration** — 4 variants:
   - `InputDecoration(border: InputBorder.none, ...)` — `ai_assistant_screen.dart:549`
   - `NeumorphicContainer(isPressed: true, padding: ..., child: TextField(...))` — `feedback_screen.dart:236`
   - Raw `TextField` with `decoration: InputDecoration(...)` — `add_transaction_modal.dart`
   - `TextField` inside `NeumorphicContainer` with `clipBehavior: Clip.antiAlias` — `adjust_balance_modal.dart:556`

3. **List Item Patterns** — Transaction rows built differently in:
   - `history_screen.dart:_buildTxItem` (Dismissible + balance text)
   - `recent_transactions_list.dart` (simpler, no swipe)
   - `wallet_screen.dart:_buildTransactionItem` (different layout)
   - `statistics_screen.dart:_buildCategoryRow` (progress bar variant)

---

## E. User Experience (UX) & Financial App Specifics

### Strengths
1. **Offline-First Architecture** — Hive local cache + Supabase sync; works fully offline
2. **Balance Tracking** — `balanceBefore`/`balanceAfter` on every transaction (local + remote after migration)
3. **Multi-Wallet (Card + Cash)** — Separate balances, toggle in wallet screen, adjustment modal
4. **Guest Mode** — Full functionality without auth; data isolated per user
5. **Quick Actions** — Dashboard has "Tambah Pemasukan/Pengeluaran/Atur Saldo" with icons
6. **AI Assistant (Noir)** — Local-first analysis (6 analysis types); optional Ollama for devs
7. **Dynamic Island Toasts** — Non-intrusive, auto-dismiss, action support

### UX Gaps & Friction Points
| # | Issue | Impact | Location |
|---|-------|--------|----------|
| E1 | **No recurring transactions** | Manual entry for subscriptions/salary | Missing feature |
| E2 | **Category management buried** | Custom categories only via "+" in add modal; no dedicated manager | `add_transaction_modal.dart` |
| E3 | **No budget/limit setting** | Financial health check AI exists but no budget UI | Missing feature |
| E4 | **Delete confirmation uses custom dialog but inconsistent** | `history_screen.dart` uses `showCustomConfirm`; `wallet_screen.dart` uses inline confirm | Two patterns |
| E5 | **Adjust balance creates "fake" transaction** | Pollutes history with "Penyesuaian Saldo" category; no audit trail distinction | `adjust_balance_modal.dart:107` |
| E6 | **No export/backup (CSV, PDF)** | Data portability missing | Missing feature |
| E7 | **AI chat history not persisted** | Sessions lost on app restart | `ai_assistant_screen.dart` |
| E8 | **Date picker uses system dialog** (not custom) — breaks theme | `add_transaction_modal.dart` | Medium |
| E9 | **No pull-to-refresh** on lists | Standard mobile pattern missing | `history_screen.dart`, `dashboard_screen.dart` |
| E10 | **Empty states generic** | "No transactions" — could show guidance/illustration | Multiple screens |

---

## F. Responsive Design & Accessibility

### Responsive Design
| Aspect | Status | Notes |
|--------|--------|-------|
| **Breakpoints** | ❌ None | Fixed `padding: 20`, `width: 36`, `height: 190` throughout |
| **Tablet/Landscape** | ❌ Untested | `PageView` wallet cards may overflow; charts fixed height |
| **Text Scaling** | ⚠️ Partial | `MediaQuery.textScaler` not respected in fixed font sizes (e.g., `fontSize: 11`) |
| **Safe Areas** | ✅ Good | `SafeArea`, `MediaQuery.padding.top` used in Dynamic Island |

### Accessibility (a11y)
| Criterion | Status | Evidence |
|-----------|--------|----------|
| **Semantic Labels** | ❌ Poor | Icon-only buttons (`IconButton`/`GestureDetector` + `Icon`) lack `Semantics` or `tooltip` |
| **Contrast** | ✅ Good | Onyx palette: white on #0A0A0A = 21:1; semantic colors meet WCAG AA |
| **Focus Order** | ⚠️ Unverified | No `FocusTraversalGroup` or explicit ordering; relies on visual order |
| **Screen Reader** | ❌ Missing | Dynamic Island alerts not announced; chat bubbles not marked as live regions |
| **Touch Targets** | ⚠️ Marginal | 36×36 min on back buttons; some chips 42×32 — below 48×48 recommendation |
| **Reduced Motion** | ❌ Ignored | `flutter_animate` runs regardless of `MediaQuery.disableAnimations` |

---

## G. Implementation Quality & Architecture

### Architecture Scorecard
| Layer | Quality | Notes |
|-------|---------|-------|
| **State Management** | ✅ Excellent | Riverpod providers (`transactionsProvider`, `dashboardProvider`, `settingsProvider`) with proper invalidation |
| **Repository Pattern** | ✅ Excellent | `TransactionRepository` interface → `Hive` + `Supabase` implementations; dual-write with offline fallback |
| **Code Generation** | ✅ Correct | Hive adapters via `build_runner`; `part` files; no manual serialization bugs |
| **Dependency Injection** | ✅ Good | Providers in `main.dart`; `ref.read`/`watch` used appropriately |
| **Error Handling** | ✅ Good | Try/catch with Dynamic Island feedback; graceful offline degradation |
| **Testing** | ❌ Absent | No `test/` directory; no widget/integration tests |
| **CI/CD** | ❌ Unknown | No `.github/workflows` visible |
| **Performance** | ✅ Good | `BouncingScrollPhysics`, `ListView.builder`, `const` widgets where possible, `RepaintBoundary` implicit via `animate()` |

### Technical Debt
1. **`statistics_screen.dart`** — 800 lines; chart data computation in `build`; should extract `ChartDataService`
2. **`ai_assistant_screen.dart`** — 940 lines; formatting logic (`_buildRichLine`, `_buildFormattedText`) belongs in separate class
3. **`adjust_balance_modal.dart`** — Creates transaction as side effect; business logic in UI layer
4. **No `freezed`/`json_serializable`** — Manual `fromJson`/`toJson` error-prone (though currently correct)
5. **`developer_config.dart`** — Hardcoded email list for Ollama access; should be feature flag

---

## H. Top 5 Critical Issues (Prioritized)

| Rank | Issue | Why Critical | Effort | Fix Sketch |
|------|-------|--------------|--------|------------|
| **1** | **No shared Button/TextField/Chip components** | 15+ reimplementations; theme changes require 15+ file edits; inconsistency bugs | 2–3 days | Create `lib/core/widgets/app_button.dart`, `app_text_field.dart`, `app_chip.dart`, `app_segmented_control.dart`; migrate all screens |
| **2** | **Accessibility gaps (semantics, screen readers, touch targets)** | Excludes users; legal risk; Dynamic Island invisible to a11y | 2–3 days | Add `Semantics` to all icon buttons; `DynamicIslandAlert` → `LiveRegion`; enforce 48×48 touch targets; respect `disableAnimations` |
| **3** | **Hardcoded Indonesian strings in UI logic** | Blocks i18n; "Mgg 1", "Penyesuaian Saldo" not in `AppTranslations` | 1 day | Move all user-facing strings to `app_translations.dart`; use `t.key` everywhere |
| **4** | **God screens (Statistics, AI Assistant, Adjust Balance)** | Hard to test, maintain, reuse; chart logic in UI layer | 3–5 days | Extract `ChartDataService`, `AIChatFormatter`, `BalanceAdjustmentService`; keep screens <300 lines |
| **5** | **Adjust Balance creates fake transaction** | Pollutes history; no audit trail; confuses AI analysis | 1–2 days | Add `isAdjustment: bool` field to `TransactionModel`; filter in history/analytics; separate "Adjustments" section |

---

## I. Good Parts (What to Keep & Amplify)

| Asset | Why It Works | Amplification Strategy |
|-------|--------------|------------------------|
| **Onyx Neumorphism System** | Distinct brand identity; performs well on OLED; consistent elevation language | Document as design system; export tokens to Figma; add `AppElevation` enum |
| **Dynamic Island Alert** | Modern, non-intrusive, replaces 6 SnackBar implementations; action support | Add queueing (multiple toasts); haptic feedback; persistence option |
| **Custom Dialog System** | Themed, accessible-ready base; replaces `showDialog` cleanly | Add `showCustomBottomSheet`, `showCustomActionSheet`; form validation helpers |
| **Offline-First Dual-Write** | Works on plane; syncs when online; conflict resolution via "last write wins" (acceptable for personal finance) | Add sync status indicator; manual "Push to Cloud" button; conflict UI |
| **Local AI (Noir)** | Zero-cost, private, 6 analysis types; streaming UX; Ollama fallback for devs | Persist chat history; add "Explain this transaction" context action; export insights |
| **Multi-Wallet (Card + Cash)** | Real-world mental model; separate balances; quick adjust modal | Add "Transfer between wallets"; per-wallet budgets; credit limit warning |
| **Riverpod + Repository** | Testable, decoupled, scales; `ref.invalidate` pattern correct | Add repository interface tests; mock implementations for widget tests |

---

## J. Phased Improvement Plan

### Phase 1: Foundation & Consistency (Week 1–2)
**Goal:** Eliminate component duplication; establish design token system

| Task | Owner | Acceptance |
|------|-------|------------|
| Create `AppButton` (primary, secondary, ghost, icon, loading states) | Dev | All 15+ button usages migrated; `flutter analyze` clean |
| Create `AppTextField` (label, hint, error, prefix/suffix, formatter) | Dev | All 12+ text fields migrated; consistent decoration |
| Create `AppChip` / `AppSegmentedControl` | Dev | Period/chart selectors in Statistics & AI use shared component |
| Extract `AppDurations`, `AppRadii`, `AppSpacing` constants | Dev | Zero magic numbers in animation/duration/radius |
| Move all hardcoded strings to `AppTranslations` | Dev | `flutter gen-l10n` works; no Indonesian literals in Dart UI code |

### Phase 2: Accessibility & Polish (Week 3)
**Goal:** WCAG 2.1 AA compliance; screen reader support

| Task | Owner | Acceptance |
|------|-------|------------|
| Audit all icon-only buttons → add `Semantics(label: ...)` | Dev | `flutter analyze --watch` shows no missing semantics warnings |
| Dynamic Island → `LiveRegion` + `Announce` | Dev | TalkBack/VoiceOver reads toasts; queue multiple |
| Enforce 48×48 touch targets (chips, icon buttons) | Dev | All interactive elements meet minimum |
| Respect `MediaQuery.disableAnimations` | Dev | `flutter_animate` disabled when system setting on |
| Text scaling test — verify no overflow at 1.5×, 2.0× | QA | Screens usable at max system font size |

### Phase 3: Architecture & Feature Depth (Week 4–6)
**Goal:** Extract services; add missing financial features

| Task | Owner | Acceptance |
|------|-------|------------|
| Extract `ChartDataService` from StatisticsScreen | Dev | Screen <300 lines; service unit-tested |
| Extract `AIChatFormatter` / `AIStreamHandler` | Dev | AI screen <400 lines; formatting testable |
| Add `isAdjustment` field to TransactionModel + migration | Dev | Adjust Balance creates flagged tx; filtered in history/analytics |
| Implement Recurring Transactions (local + Supabase) | Dev | "Repeat: Weekly/Monthly/Yearly" in add modal; auto-create |
| Add Budget/Limit UI (per category, per wallet) | Dev | Dashboard shows budget bars; AI includes budget health |
| Add CSV Export (transactions, summary) | Dev | Share sheet opens with CSV; date range filter |

### Phase 4: Quality & Scale (Week 7+)
**Goal:** Test coverage; CI; performance monitoring

| Task | Owner | Acceptance |
|------|-------|------------|
| Add widget tests for core screens (Dashboard, History, Add Tx) | Dev | `flutter test` >80% widget coverage |
| Add repository tests (Hive + Supabase mock) | Dev | Offline/online sync scenarios covered |
| GitHub Actions CI (analyze, test, build apk) | Dev | Green on every PR |
| Performance profiling (frame times, memory) | Dev | 60fps on low-end device; no jank on list scroll |
| Design system documentation (Storybook or widget gallery) | Design | Component library reference for onboarding |

---

## Appendix: File-Level Audit Notes

| File | Lines | Issues | Priority |
|------|-------|--------|----------|
| `statistics_screen.dart` | 800 | God screen; copy-paste btn builders; hardcoded "Mgg" | P1 |
| `ai_assistant_screen.dart` | 940 | God screen; formatting logic inline; dev-only input hidden | P1 |
| `adjust_balance_modal.dart` | 670 | Business logic in UI; fake transaction; hardcoded strings | P1 |
| `history_screen.dart` | ~500 | Good Dismissible fix; custom dialog used; balance display works | P2 |
| `wallet_screen.dart` | ~400 | PageView cards; duplicate transaction item logic | P2 |
| `dashboard_screen.dart` | ~350 | Clean; recent transactions widget separate (good) | P3 |
| `add_transaction_modal.dart` | ~600 | Category management inline; date picker system dialog | P2 |
| `feedback_screen.dart` | 350 | Good Dynamic Island usage; mailto + Supabase dual | P3 |
| `custom_dialog.dart` | ~200 | Solid base; needs bottom sheet/action sheet variants | P3 |
| `dynamic_island_alert.dart` | 400 | Excellent; needs a11y + queueing | P2 |
| `neumorphic_container.dart` | 150 | Core primitive; well-designed | Keep |
| `app_colors.dart` | 100 | Good palette; needs token export | Keep |
| `transaction_model.dart` | 85 | Clean; balance fields added; serialization correct | Keep |
| `supabase_transaction_repository.dart` | 83 | Clean dual-write; offline fallback | Keep |

---

*End of Audit Report*