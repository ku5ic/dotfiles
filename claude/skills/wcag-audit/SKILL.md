---
name: wcag-audit
description: WCAG 2.2 AA audit checklist, severity rubric, and stack adaptation for accessibility review. Use whenever the user asks about accessibility, a11y, WCAG, screen readers, keyboard navigation, focus management, ARIA, contrast, semantic HTML, alt text, form labels, or audits a component, page, or template for accessibility issues regardless of stack (React, Next.js, Django templates, plain HTML), even if WCAG is not mentioned by name.
---

# WCAG 2.2 AA audit

Target: WCAG 2.2 Level AA. Includes all Level A. Does not include AAA unless explicitly requested.

## How to apply

Go through the checklist in order. Skip criteria that do not apply to the scope (e.g. no forms -> skip form labeling). Record what was checked, what passed, what failed. Note items that require runtime or user testing.

## Checklist

### 1. Perceivable

- 1.1.1 Non-text Content (A): images have alt or are marked decorative; icon only buttons have an accessible name.
- 1.3.1 Info and Relationships (A): semantic HTML over ARIA, correct heading hierarchy, lists use `ul`/`ol`/`li`, tables use `th`/`caption`, form fields have `label`.
- 1.3.4 Orientation (AA): no forced orientation lock.
- 1.3.5 Identify Input Purpose (AA): autocomplete tokens on personal data fields.
- 1.4.3 Contrast Minimum (AA): 4.5:1 body, 3:1 large text. Flag hardcoded colors that may fail; note where runtime theming prevents static verification.
- 1.4.10 Reflow (AA): content works at 320 CSS px without horizontal scroll.
- 1.4.11 Non-text Contrast (AA): UI component and graphical object boundaries 3:1.
- 1.4.12 Text Spacing (AA): content survives line-height 1.5, letter spacing 0.12em.
- 1.4.13 Content on Hover or Focus (AA): dismissible, hoverable, persistent.

### 2. Operable

- 2.1.1 Keyboard (A): all interactive elements reachable and operable via keyboard.
- 2.1.2 No Keyboard Trap (A): focus does not get stuck.
- 2.4.3 Focus Order (A): tab order follows visual and logical order.
- 2.4.4 Link Purpose in Context (A): link text describes destination or purpose.
- 2.4.6 Headings and Labels (AA): headings and labels describe topic.
- 2.4.7 Focus Visible (AA): visible focus indicator on all interactive elements.
- 2.4.11 Focus Not Obscured Minimum (AA): focused element not fully hidden by sticky headers, toasts, etc. (new in 2.2).
- 2.5.3 Label in Name (A): accessible name contains the visible label.
- 2.5.7 Dragging Movements (AA): drag interactions have a single pointer alternative (new in 2.2).
- 2.5.8 Target Size Minimum (AA): interactive targets at least 24x24 CSS px or have adequate spacing (new in 2.2).

### 3. Understandable

- 3.2.3 Consistent Navigation (AA): repeated navigation in consistent order.
- 3.2.4 Consistent Identification (AA): components with the same function labeled consistently.
- 3.2.6 Consistent Help (A): help mechanisms in consistent location across pages (new in 2.2).
- 3.3.1 Error Identification (A): errors identified in text.
- 3.3.2 Labels or Instructions (A): controls have labels or instructions.
- 3.3.3 Error Suggestion (AA): suggestions offered when known.
- 3.3.4 Error Prevention (AA): for legal, financial, data submissions: reversible, checkable, or confirmable.
- 3.3.7 Redundant Entry (A): do not ask the same info twice in a process (new in 2.2).
- 3.3.8 Accessible Authentication Minimum (AA): no cognitive function test without alternative (new in 2.2).

### 4. Robust

- 4.1.2 Name, Role, Value (A): custom widgets expose correct role, state, properties via ARIA where native semantics insufficient.
- 4.1.3 Status Messages (AA): live regions for async status without focus change.

## Severity rubric

- **failure**: a direct Level AA violation that will block certification or cause a usable defect.
- **warning**: likely to cause issues in some assistive tech configurations, or violates A level and relied on by AA.
- **info**: best practice not required at AA, or a pattern likely to regress if not fixed now.

## Cannot be verified statically

Note these in the "Cannot be verified statically" section of the report:

- Runtime focus behavior (modals, route changes, async content)
- Color contrast when colors come from CSS variables with runtime theming
- Screen reader announcement quality (requires AT testing)
- Motion sensitivity (`prefers-reduced-motion` paths need runtime verification)
- Keyboard-only operation flows (need actual keyboard testing)
- Cognitive load of authentication flows

## Stack adaptation

- **React / Next.js**: check ARIA patterns on custom components, effect based focus management, `sr-only` usage, Next.js `Link` composition.
- **Django templates**: check template inheritance patterns for consistent nav, form field rendering via `{{ form.field }}`, crispy-forms or equivalent output.
- **Plain HTML**: no framework quirks, but watch for missing `<main>`, heading hierarchy across included partials.

## References

- WCAG 2.2 spec: https://www.w3.org/TR/WCAG22/
- Understanding docs: https://www.w3.org/WAI/WCAG22/Understanding/
