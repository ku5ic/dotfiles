---
name: a11y
description: Focused WCAG 2.2 AA accessibility audit of a component or file
---

Perform a WCAG 2.2 AA accessibility audit on the following. Be precise and actionable.

Check:

1. Semantic HTML - correct element choice, heading hierarchy, landmark regions, list structures
2. ARIA - only where native semantics are insufficient, correct roles/states/properties, no redundant ARIA
3. Keyboard operability - all interactive elements reachable and operable via keyboard, logical tab order, no keyboard traps
4. Focus management - visible focus indicators (2.4.11, 2.4.12), programmatic focus on dynamic content (modals, toasts, route changes)
5. Target size - interactive targets meet minimum 24x24px requirement (2.5.8)
6. Labels and names - all form controls labeled, images have meaningful alt text or are marked decorative, icon buttons have accessible names, consistent labeling for repeated components (2.4.6, 2.5.3)
7. Authentication - if login or auth flows are present, flag any cognitive function tests without alternatives (3.3.8)
8. Dragging alternatives - if drag interactions are present, verify pointer alternative exists (2.5.7)
9. Color and contrast - flag hardcoded color values that may fail contrast requirements, note if contrast cannot be verified statically
10. Motion - check for missing prefers-reduced-motion guards on animations or transitions

For each issue: cite the specific WCAG criterion (e.g. 1.3.1, 4.1.2), describe the problem, and provide the corrected code or markup. Distinguish failures from warnings. Note where a check cannot be performed statically and requires manual or automated tool verification.

$ARGUMENTS
