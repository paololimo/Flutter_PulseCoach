/* @ds-bundle: {"format":4,"namespace":"PulseCoachDesignSystem_923364","components":[{"name":"SessionCatalogCard","sourcePath":"components/catalog/SessionCatalogCard.jsx"},{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Card","sourcePath":"components/core/Card.jsx"},{"name":"Chip","sourcePath":"components/core/Chip.jsx"},{"name":"Icon","sourcePath":"components/core/Icon.jsx"},{"name":"Switch","sourcePath":"components/core/Switch.jsx"},{"name":"ProUpsellSheet","sourcePath":"components/feedback/ProUpsellSheet.jsx"},{"name":"SessionHistoryTile","sourcePath":"components/feedback/SessionHistoryTile.jsx"},{"name":"SignInSheet","sourcePath":"components/feedback/SignInSheet.jsx"},{"name":"CountdownOverlay","sourcePath":"components/session/CountdownOverlay.jsx"},{"name":"RPEInput","sourcePath":"components/session/RPEInput.jsx"},{"name":"ShimmerPlaceholder","sourcePath":"components/session/ShimmerPlaceholder.jsx"},{"name":"ActivityFeedCard","sourcePath":"components/social/ActivityFeedCard.jsx"},{"name":"ComparisonRow","sourcePath":"components/social/ComparisonRow.jsx"},{"name":"FriendRow","sourcePath":"components/social/FriendRow.jsx"},{"name":"JoinCodeCard","sourcePath":"components/social/JoinCodeCard.jsx"},{"name":"LeaderboardRow","sourcePath":"components/social/LeaderboardRow.jsx"},{"name":"VisibilityTierSelector","sourcePath":"components/social/VisibilityTierSelector.jsx"},{"name":"CompactSessionCard","sourcePath":"components/today/CompactSessionCard.jsx"},{"name":"CompletedSessionCard","sourcePath":"components/today/CompletedSessionCard.jsx"},{"name":"CompletionRing","sourcePath":"components/today/CompletionRing.jsx"},{"name":"HeroSessionCard","sourcePath":"components/today/HeroSessionCard.jsx"},{"name":"StateIndicator","sourcePath":"components/today/StateIndicator.jsx"},{"name":"WeeklyGoalIndicator","sourcePath":"components/today/WeeklyGoalIndicator.jsx"},{"name":"SESSION_ACCENT","sourcePath":"components/today/session-meta.js"},{"name":"SESSION_ICON","sourcePath":"components/today/session-meta.js"}],"sourceHashes":{"components/catalog/SessionCatalogCard.jsx":"aec9d7e2eadc","components/core/Badge.jsx":"0dc7b272df89","components/core/Button.jsx":"aac3885e0c5b","components/core/Card.jsx":"6bfde3e02c50","components/core/Chip.jsx":"77a7b9675ecf","components/core/Icon.jsx":"46b45939397d","components/core/Switch.jsx":"fa4b1c5e5658","components/feedback/ProUpsellSheet.jsx":"a1bf81486cf5","components/feedback/SessionHistoryTile.jsx":"805da3f23b0a","components/feedback/SignInSheet.jsx":"3f3cbc6f82e8","components/session/CountdownOverlay.jsx":"7f56ae311e31","components/session/RPEInput.jsx":"1f47cc10baf7","components/session/ShimmerPlaceholder.jsx":"d881271d3972","components/social/ActivityFeedCard.jsx":"19700a9c4dfc","components/social/ComparisonRow.jsx":"7fc1c0f92866","components/social/FriendRow.jsx":"9c86b35afad4","components/social/JoinCodeCard.jsx":"a46e650948fd","components/social/LeaderboardRow.jsx":"04e0a107591e","components/social/VisibilityTierSelector.jsx":"68db23b5afae","components/today/CompactSessionCard.jsx":"8753213353e8","components/today/CompletedSessionCard.jsx":"47f59317ddcc","components/today/CompletionRing.jsx":"d28607fb25ec","components/today/HeroSessionCard.jsx":"fdc22449f7fe","components/today/StateIndicator.jsx":"251d943e9be6","components/today/WeeklyGoalIndicator.jsx":"263674d0cfb8","components/today/session-meta.js":"8b6612d8ee65","ui_kits/pulsecoach_app/app.jsx":"1f42400471d7","ui_kits/pulsecoach_app/screens.jsx":"c948d00d0291"},"inlinedExternals":[],"unexposedExports":[{"name":"intensityLabel","sourcePath":"components/today/session-meta.js"},{"name":"sessionAccent","sourcePath":"components/today/session-meta.js"},{"name":"sessionIcon","sourcePath":"components/today/session-meta.js"}]} */

(() => {

const __ds_ns = (window.PulseCoachDesignSystem_923364 = window.PulseCoachDesignSystem_923364 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Badge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Badge — a small status pill. Pairs an accent with a text label (color is
 * never the sole carrier of meaning). Used for the hero "● Attivo" badge,
 * "Piano di gruppo", the "Pro" pill, and relative-time metadata.
 *  - soft (default): tinted fill + accent text
 *  - solid: accent fill + on-primary/dark text (rare)
 */
function Badge({
  children,
  tone = 'primary',
  variant = 'soft',
  dot = false,
  icon = null,
  style,
  ...rest
}) {
  const toneColor = {
    primary: 'var(--pc-primary)',
    secondary: 'var(--pc-secondary)',
    tertiary: 'var(--pc-tertiary)',
    coral: 'var(--pc-coral)',
    neutral: 'var(--pc-on-surface-variant)',
    error: 'var(--pc-error)'
  }[tone] || 'var(--pc-primary)';
  const soft = {
    color: toneColor,
    background: `color-mix(in srgb, ${toneColor} 14%, transparent)`
  };
  const solid = {
    color: tone === 'primary' ? 'var(--pc-on-primary)' : 'var(--pc-surface)',
    background: toneColor
  };
  const base = {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '6px',
    padding: '3px 9px',
    fontFamily: 'var(--pc-font-sans)',
    fontSize: '11px',
    fontWeight: 600,
    lineHeight: 1.4,
    letterSpacing: '0.01em',
    borderRadius: 'var(--pc-radius-full)',
    ...(variant === 'solid' ? solid : soft),
    ...style
  };
  return /*#__PURE__*/React.createElement("span", _extends({
    style: base
  }, rest), dot && /*#__PURE__*/React.createElement("span", {
    style: {
      width: 7,
      height: 7,
      borderRadius: 9999,
      background: variant === 'solid' ? base.color : toneColor,
      flex: '0 0 auto'
    }
  }), icon, children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Button — PulseCoach's primary action control.
 *
 * Variants map to the app's calm hierarchy:
 *  - filled   Aqua primary. On-primary dark-teal label (never white on aqua).
 *  - tonal    surface-container-high fill, on-surface label (Apple/Google/Email rows).
 *  - text     transparent, muted label ("non ora", "End session").
 *  - danger   transparent, error label (destructive only).
 * Radius 12 (button). Font 15/600. Press = gentle darken + 0.98 scale.
 */
function Button({
  children,
  variant = 'filled',
  size = 'md',
  fullWidth = false,
  disabled = false,
  leadingIcon = null,
  onClick,
  style,
  ...rest
}) {
  const [pressed, setPressed] = React.useState(false);
  const [hover, setHover] = React.useState(false);
  const pads = size === 'sm' ? {
    padding: '9px 16px',
    font: '13px'
  } : size === 'lg' ? {
    padding: '15px 24px',
    font: '16px'
  } : {
    padding: '13px 20px',
    font: '15px'
  };
  const palette = {
    filled: {
      bg: 'var(--pc-primary)',
      fg: 'var(--pc-on-primary)',
      border: 'transparent'
    },
    tonal: {
      bg: 'var(--pc-surface-container-high)',
      fg: 'var(--pc-on-surface)',
      border: 'transparent'
    },
    text: {
      bg: 'transparent',
      fg: 'var(--pc-on-surface-variant)',
      border: 'transparent'
    },
    danger: {
      bg: 'transparent',
      fg: 'var(--pc-error)',
      border: 'transparent'
    }
  }[variant] || {};
  const base = {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '8px',
    width: fullWidth ? '100%' : 'auto',
    padding: pads.padding,
    fontFamily: 'var(--pc-font-sans)',
    fontSize: pads.font,
    fontWeight: variant === 'text' ? 500 : 600,
    lineHeight: 1,
    color: palette.fg,
    background: palette.bg,
    border: '1px solid ' + palette.border,
    borderRadius: 'var(--pc-radius-button)',
    cursor: disabled ? 'not-allowed' : 'pointer',
    opacity: disabled ? 0.45 : 1,
    minHeight: '48px',
    transition: 'transform 120ms ease, filter 120ms ease, background 120ms ease',
    transform: pressed ? 'scale(0.98)' : 'scale(1)',
    filter: hover && !disabled ? variant === 'filled' ? 'brightness(1.05)' : 'brightness(1.15)' : 'none',
    WebkitTapHighlightColor: 'transparent',
    ...style
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    disabled: disabled,
    onClick: onClick,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => {
      setHover(false);
      setPressed(false);
    },
    onMouseDown: () => setPressed(true),
    onMouseUp: () => setPressed(false),
    style: base
  }, rest), leadingIcon, children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Card — the base PulseCoach surface. Flat (elevation 0, no shadow); depth is
 * expressed as surface tint. Radius 16, md (16) internal padding by default.
 *  - variant "container"  → surface-container (default card)
 *  - variant "high"       → surface-container-high (active/selected, inputs, sheets)
 *  - variant "hero"       → the single soft hero-zone gradient wash (Today only)
 * Pass `accent` with variant="hero" to tint the wash to a session color.
 */
function Card({
  children,
  variant = 'container',
  accent = 'var(--pc-primary)',
  interactive = false,
  selected = false,
  onClick,
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  let background = 'var(--pc-surface-container)';
  if (variant === 'high') background = 'var(--pc-surface-container-high)';
  if (variant === 'hero') {
    background = `linear-gradient(160deg, color-mix(in srgb, ${accent} 12%, transparent) 0%, var(--pc-surface-container) 55%)`;
  }
  const base = {
    position: 'relative',
    background,
    borderRadius: 'var(--pc-radius-card)',
    padding: 'var(--pc-card-pad)',
    color: 'var(--pc-on-surface)',
    border: selected ? `1px solid color-mix(in srgb, ${accent} 40%, transparent)` : '1px solid transparent',
    cursor: interactive ? 'pointer' : 'default',
    transition: 'filter 120ms ease, transform 120ms ease',
    filter: interactive && hover ? 'brightness(1.08)' : 'none',
    ...style
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    onClick: onClick,
    onMouseEnter: () => interactive && setHover(true),
    onMouseLeave: () => interactive && setHover(false),
    style: base
  }, rest), children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Card.jsx", error: String((e && e.message) || e) }); }

// components/core/Chip.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Chip — a compact label / selectable filter. `radius/chip` (8) by default,
 * or fully rounded via `pill`. Used for session-type tags, catalog filters,
 * segmented-style selects, and lobby participant chips.
 *  - selectable + selected: raised fill + on-surface text (FilterChip)
 *  - default: quiet outline with muted text
 */
function Chip({
  children,
  selected = false,
  selectable = false,
  pill = false,
  tone = 'default',
  leadingDot = null,
  leadingIcon = null,
  onClick,
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const toneColor = {
    default: 'var(--pc-primary)',
    primary: 'var(--pc-primary)',
    secondary: 'var(--pc-secondary)',
    tertiary: 'var(--pc-tertiary)',
    coral: 'var(--pc-coral)'
  }[tone] || 'var(--pc-primary)';
  const base = {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '6px',
    padding: '6px 12px',
    fontFamily: 'var(--pc-font-sans)',
    fontSize: '12px',
    fontWeight: 600,
    lineHeight: 1.2,
    borderRadius: pill ? 'var(--pc-radius-full)' : 'var(--pc-radius-chip)',
    color: selected ? 'var(--pc-on-surface)' : selectable ? 'var(--pc-on-surface-variant)' : toneColor,
    background: selected ? 'var(--pc-surface-container-high)' : 'transparent',
    border: '1px solid ' + (selected ? 'var(--pc-outline)' : selectable ? 'var(--pc-hairline)' : 'transparent'),
    cursor: selectable ? 'pointer' : 'default',
    transition: 'filter 120ms ease, background 120ms ease',
    filter: selectable && hover ? 'brightness(1.2)' : 'none',
    ...style
  };

  // Type chip (non-selectable) gets a tonal fill rather than a bare label.
  if (!selectable && tone !== 'default') {
    base.background = 'var(--pc-surface-container-high)';
  }
  return /*#__PURE__*/React.createElement("span", _extends({
    onClick: onClick,
    onMouseEnter: () => selectable && setHover(true),
    onMouseLeave: () => selectable && setHover(false),
    style: base
  }, rest), leadingDot && /*#__PURE__*/React.createElement("span", {
    style: {
      width: 8,
      height: 8,
      borderRadius: 9999,
      background: toneColor,
      flex: '0 0 auto'
    }
  }), leadingIcon, children);
}
Object.assign(__ds_scope, { Chip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Chip.jsx", error: String((e && e.message) || e) }); }

// components/core/Icon.jsx
try { (() => {
/**
 * Convert a lucide icon name (kebab-case or PascalCase) to PascalCase,
 * which is how the lucide UMD global keys its icon node table.
 */
function toPascal(name) {
  if (!name) return '';
  if (/^[A-Z]/.test(name) && !name.includes('-')) return name;
  return name.split(/[-_\s]+/).map(p => p.charAt(0).toUpperCase() + p.slice(1)).join('');
}

/** Normalize a lucide icon node into a flat array of [tag, attrs] child tuples. */
function normalize(node) {
  if (!Array.isArray(node)) return null;
  // Modern lucide: ['svg', {..}, [[tag, attrs], ...]]
  if (typeof node[0] === 'string' && node[0].toLowerCase() === 'svg' && Array.isArray(node[2])) {
    return node[2];
  }
  // UMD icons table: [[tag, attrs], [tag, attrs], ...]
  if (Array.isArray(node[0])) return node;
  // Single tuple: [tag, attrs]
  if (typeof node[0] === 'string') return [node];
  return null;
}

/**
 * Icon — the PulseCoach icon primitive. Renders a Lucide glyph.
 *
 * PulseCoach uses the Lucide icon set exclusively (Material Icons are
 * explicitly NOT used). Load the Lucide UMD once per page from CDN
 * (https://unpkg.com/lucide@latest) before mounting; this component reads
 * the real Lucide geometry from `window.lucide`. If Lucide is unavailable it
 * degrades to a small filled dot so the UI never breaks.
 */
function Icon({
  name,
  size = 24,
  color = 'currentColor',
  strokeWidth = 2,
  title,
  className,
  style,
  ...rest
}) {
  const lib = typeof window !== 'undefined' ? window.lucide : null;
  const pascal = toPascal(name);
  const raw = lib && lib.icons ? lib.icons[pascal] : lib ? lib[pascal] : null;
  const children = normalize(raw);
  const svgProps = {
    xmlns: 'http://www.w3.org/2000/svg',
    width: size,
    height: size,
    viewBox: '0 0 24 24',
    fill: 'none',
    stroke: color,
    strokeWidth,
    strokeLinecap: 'round',
    strokeLinejoin: 'round',
    className,
    style,
    role: title ? 'img' : undefined,
    'aria-hidden': title ? undefined : true,
    'aria-label': title,
    ...rest
  };
  if (!children) {
    // Fallback: filled dot in the current color.
    return React.createElement('svg', {
      ...svgProps,
      fill: color,
      stroke: 'none'
    }, React.createElement('circle', {
      cx: 12,
      cy: 12,
      r: 5
    }));
  }
  return React.createElement('svg', svgProps, children.map((c, i) => React.createElement(c[0], {
    key: i,
    ...c[1]
  })));
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Icon.jsx", error: String((e && e.message) || e) }); }

// components/catalog/SessionCatalogCard.jsx
try { (() => {
/**
 * SessionCatalogCard — a browse-catalog card (Sessions tab). Type chip +
 * difficulty dots, session name, duration, chevron. Radius 8 (chip) — the
 * catalog's tighter rounding. Ground-truthed against session_catalog_card.dart.
 */
function SessionCatalogCard({
  name,
  category = 'Mobility',
  difficulty = 'low',
  durationMinutes = 5,
  onTap,
  style
}) {
  const [hover, setHover] = React.useState(false);
  const active = {
    low: 1,
    medium: 2,
    high: 3
  }[String(difficulty).toLowerCase()] || 0;
  return /*#__PURE__*/React.createElement("div", {
    role: onTap ? 'button' : undefined,
    onClick: onTap,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => setHover(false),
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: 16,
      borderRadius: 'var(--pc-radius-chip)',
      background: 'var(--pc-surface-container)',
      cursor: onTap ? 'pointer' : 'default',
      filter: onTap && hover ? 'brightness(1.08)' : 'none',
      transition: 'filter 120ms ease',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      padding: '5px 10px',
      borderRadius: 'var(--pc-radius-full)',
      background: 'var(--pc-surface-container-high)',
      color: 'var(--pc-primary)',
      fontSize: 11,
      fontWeight: 700,
      letterSpacing: '0.02em'
    }
  }, category), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      gap: 3
    }
  }, [0, 1, 2].map(i => /*#__PURE__*/React.createElement("span", {
    key: i,
    style: {
      width: 8,
      height: 8,
      borderRadius: 9999,
      background: i < active ? 'var(--pc-tertiary)' : 'color-mix(in srgb, var(--pc-on-surface-variant) 35%, transparent)'
    }
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 10,
      fontSize: 17,
      fontWeight: 700,
      color: 'var(--pc-on-surface)'
    }
  }, name), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8,
      fontSize: 15,
      color: 'var(--pc-on-surface-variant)'
    }
  }, durationMinutes, " min")), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "chevron-right",
    size: 22,
    color: "var(--pc-on-surface-variant)"
  }));
}
Object.assign(__ds_scope, { SessionCatalogCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/catalog/SessionCatalogCard.jsx", error: String((e && e.message) || e) }); }

// components/core/Switch.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Switch — Material-3 style toggle in PulseCoach tokens. On = aqua track with
 * a dark-teal knob; off = surface-container-high track with a muted knob.
 * Used for backup / consent toggles in Settings.
 */
function Switch({
  checked = false,
  disabled = false,
  onChange,
  style,
  ...rest
}) {
  const track = {
    position: 'relative',
    width: 44,
    height: 26,
    flex: '0 0 auto',
    borderRadius: 9999,
    background: checked ? 'var(--pc-primary)' : 'var(--pc-surface-container-high)',
    border: checked ? '1px solid transparent' : '1px solid var(--pc-outline)',
    cursor: disabled ? 'not-allowed' : 'pointer',
    opacity: disabled ? 0.45 : 1,
    transition: 'background 160ms ease',
    padding: 0,
    ...style
  };
  const knob = {
    position: 'absolute',
    top: '50%',
    left: checked ? 'calc(100% - 22px)' : 3,
    width: 18,
    height: 18,
    borderRadius: 9999,
    background: checked ? 'var(--pc-on-primary)' : 'var(--pc-on-surface-variant)',
    transform: 'translateY(-50%)',
    transition: 'left 160ms cubic-bezier(0.2, 0, 0, 1)'
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    role: "switch",
    "aria-checked": checked,
    disabled: disabled,
    onClick: () => !disabled && onChange && onChange(!checked),
    style: track
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: knob
  }));
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Switch.jsx", error: String((e && e.message) || e) }); }

// components/feedback/ProUpsellSheet.jsx
try { (() => {
/**
 * ProUpsellSheet — the contextual, silent Pro prompt. Appears ONLY on a
 * locked-feature tap. One calm line + `Scopri Pro` + `non ora`, then resolves.
 * No persistent badges elsewhere. Renders the sheet panel (surface-container-
 * high, rounded top). Wrap in a scrim to present it. Ground-truthed against
 * pro_upsell_sheet.dart.
 */
function ProUpsellSheet({
  message = 'Lo storico completo è una funzione Pro.',
  detail = 'Sblocca la cronologia e tutti i grafici. Il core resta gratuito.',
  onDiscover,
  onDismiss,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--pc-surface-container-high)',
      borderRadius: '20px 20px 0 0',
      padding: '22px 18px 24px',
      boxShadow: 'var(--pc-shadow-sheet)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 4,
      borderRadius: 999,
      background: 'var(--pc-outline)',
      margin: '0 auto 16px'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 17,
      fontWeight: 600,
      color: 'var(--pc-on-surface)'
    }
  }, message), detail && /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      lineHeight: 1.45,
      color: 'var(--pc-on-surface-variant)',
      marginTop: 6
    }
  }, detail), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 18
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "filled",
    fullWidth: true,
    onClick: onDiscover
  }, "Scopri Pro"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "text",
    fullWidth: true,
    onClick: onDismiss
  }, "non ora"))));
}
Object.assign(__ds_scope, { ProUpsellSheet });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/ProUpsellSheet.jsx", error: String((e && e.message) || e) }); }

// components/feedback/SignInSheet.jsx
try { (() => {
/**
 * SignInSheet — optional account entry. Three calm stacked options (Apple,
 * Google, Email) + a "continua senza account" escape. No imagery, no marketing;
 * the free core works without it. Ground-truthed against sign_in_sheet.dart.
 */
function SignInSheet({
  title = 'Accedi',
  subtitle = 'Serve solo per backup, social e Pro. L\u2019app resta completa senza account.',
  onApple,
  onGoogle,
  onEmail,
  onSkip,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 24,
      fontWeight: 600,
      color: 'var(--pc-on-surface)'
    }
  }, title, " ", /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 15,
      fontWeight: 400,
      color: 'var(--pc-on-surface-variant)'
    }
  }, "(opzionale)")), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      lineHeight: 1.45,
      color: 'var(--pc-on-surface-variant)',
      marginBottom: 10
    }
  }, subtitle), /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "tonal",
    fullWidth: true,
    leadingIcon: /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: "apple",
      size: 18
    }),
    onClick: onApple
  }, "Continua con Apple"), /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "tonal",
    fullWidth: true,
    leadingIcon: /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: "chrome",
      size: 18
    }),
    onClick: onGoogle
  }, "Continua con Google"), /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "tonal",
    fullWidth: true,
    leadingIcon: /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: "mail",
      size: 18
    }),
    onClick: onEmail
  }, "Email"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 4
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "text",
    fullWidth: true,
    onClick: onSkip
  }, "Continua senza account")));
}
Object.assign(__ds_scope, { SignInSheet });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/SignInSheet.jsx", error: String((e && e.message) || e) }); }

// components/session/CountdownOverlay.jsx
try { (() => {
/**
 * CountdownOverlay — the 3-2-1 start ritual. Full-screen aqua surface with a
 * huge Mono numeral (72), each beat fading + scaling in, then "GO". Calm, no
 * aggressive color; non-skippable by design. White numeral on aqua.
 * Ground-truthed against countdown_overlay.dart.
 */
function CountdownOverlay({
  sessionTitle,
  onComplete,
  autoStart = true,
  style
}) {
  const [count, setCount] = React.useState(3);
  const [go, setGo] = React.useState(false);
  const [beat, setBeat] = React.useState(0); // bump to retrigger the animation

  React.useEffect(() => {
    if (!autoStart) return;
    let alive = true;
    const seq = [3, 2, 1];
    let i = 0;
    setCount(3);
    setGo(false);
    setBeat(b => b + 1);
    const tick = () => {
      if (!alive) return;
      i += 1;
      if (i < seq.length) {
        setCount(seq[i]);
        setBeat(b => b + 1);
        timer = setTimeout(tick, 1000);
      } else {
        setGo(true);
        setBeat(b => b + 1);
        timer = setTimeout(() => {
          if (alive) onComplete && onComplete();
        }, 700);
      }
    };
    let timer = setTimeout(tick, 1000);
    return () => {
      alive = false;
      clearTimeout(timer);
    };
  }, [autoStart]);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'var(--pc-primary)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 16,
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    key: beat,
    style: {
      fontFamily: 'var(--pc-font-mono)',
      fontSize: 72,
      lineHeight: 1,
      color: '#FFFFFF',
      animation: 'pc-count 400ms ease-in-out'
    }
  }, go ? 'GO' : count), sessionTitle && /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      color: 'rgba(255,255,255,0.85)'
    }
  }, sessionTitle), /*#__PURE__*/React.createElement("style", null, `@keyframes pc-count { from { opacity: 0; transform: scale(0.7); } to { opacity: 1; transform: scale(1); } }`));
}
Object.assign(__ds_scope, { CountdownOverlay });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/session/CountdownOverlay.jsx", error: String((e && e.message) || e) }); }

// components/session/RPEInput.jsx
try { (() => {
/**
 * RPEInput — Rate-of-Perceived-Exertion selector. A single row of 10 full-round
 * buttons (Mono 20). Selection IS submission — no submit button; once a value is
 * chosen the row locks. 44px visible / ≥48px hit target; degrades to two rows of
 * five when the surface is too narrow. Ground-truthed against rpe_input_widget.dart.
 */
function RPEInput({
  value = null,
  onSelect,
  style
}) {
  const wrapRef = React.useRef(null);
  const [twoRows, setTwoRows] = React.useState(false);
  React.useEffect(() => {
    const el = wrapRef.current;
    if (!el || typeof ResizeObserver === 'undefined') return;
    const ro = new ResizeObserver(entries => {
      const w = entries[0].contentRect.width;
      // 10 × 48 + 9 × 4 gaps = 516px single-row floor.
      setTwoRows(w < 516);
    });
    ro.observe(el);
    return () => ro.disconnect();
  }, []);
  const locked = value != null;
  const Btn = n => {
    const selected = value === n;
    return /*#__PURE__*/React.createElement("button", {
      key: n,
      type: "button",
      role: "button",
      "aria-pressed": selected,
      "aria-label": `RPE ${n}`,
      disabled: locked,
      onClick: () => !locked && onSelect && onSelect(n),
      style: {
        width: 44,
        height: 44,
        flex: '0 0 auto',
        borderRadius: 'var(--pc-radius-full)',
        fontFamily: 'var(--pc-font-mono)',
        fontSize: 20,
        lineHeight: 1,
        color: selected ? 'var(--pc-on-primary)' : 'var(--pc-on-surface)',
        background: selected ? 'var(--pc-primary)' : 'transparent',
        border: `1px solid ${selected ? 'var(--pc-primary)' : 'var(--pc-outline)'}`,
        cursor: locked ? 'default' : 'pointer',
        opacity: locked && !selected ? 0.5 : 1,
        transform: selected ? 'scale(1.12)' : 'scale(1)',
        transition: 'transform 150ms ease, background 150ms ease, opacity 150ms ease'
      }
    }, n);
  };
  const rowStyle = {
    display: 'flex',
    justifyContent: 'center',
    gap: 4
  };
  const nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  return /*#__PURE__*/React.createElement("div", {
    ref: wrapRef,
    style: {
      width: '100%',
      ...style
    }
  }, twoRows ? /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: rowStyle
  }, nums.slice(0, 5).map(Btn)), /*#__PURE__*/React.createElement("div", {
    style: rowStyle
  }, nums.slice(5).map(Btn))) : /*#__PURE__*/React.createElement("div", {
    style: rowStyle
  }, nums.map(Btn)));
}
Object.assign(__ds_scope, { RPEInput });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/session/RPEInput.jsx", error: String((e && e.message) || e) }); }

// components/session/ShimmerPlaceholder.jsx
try { (() => {
/**
 * ShimmerPlaceholder — skeleton loader matching content layout. surface-container
 * base with an on-surface-variant @ .1 highlight sweeping across. Used instead of
 * spinners everywhere (never a CircularProgressIndicator). Ground-truthed against
 * shimmer_placeholder.dart.
 */
function ShimmerPlaceholder({
  height = 16,
  width = '100%',
  borderRadius = 8,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height,
      width,
      borderRadius,
      background: 'var(--pc-shimmer-base)',
      backgroundImage: 'linear-gradient(90deg, transparent 0%, var(--pc-shimmer-highlight) 50%, transparent 100%)',
      backgroundSize: '200% 100%',
      animation: 'pc-shimmer 1.4s ease-in-out infinite',
      ...style
    }
  }, /*#__PURE__*/React.createElement("style", null, `@keyframes pc-shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }`));
}
Object.assign(__ds_scope, { ShimmerPlaceholder });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/session/ShimmerPlaceholder.jsx", error: String((e && e.message) || e) }); }

// components/social/ComparisonRow.jsx
try { (() => {
/**
 * ComparisonRow — a friend-progress comparison row (friends-only, no biometric
 * detail). @handle left; sessions "N/3" and minutes right. Own row uses
 * surface-container-high. Ground-truthed against comparison_row.dart.
 */
function ComparisonRow({
  handle,
  sessionsThisWeek = 0,
  minutesThisWeek = 0,
  weeklyTarget = 3,
  isOwn = false,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: 16,
      borderRadius: 'var(--pc-radius-card)',
      background: isOwn ? 'var(--pc-surface-container-high)' : 'var(--pc-surface-container)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      minWidth: 0,
      fontSize: 15,
      color: 'var(--pc-on-surface)',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, "@", handle), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'right'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      color: 'var(--pc-on-surface)'
    }
  }, sessionsThisWeek, "/", weeklyTarget, " sessioni"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'var(--pc-on-surface-variant)'
    }
  }, minutesThisWeek, " min")));
}
Object.assign(__ds_scope, { ComparisonRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/social/ComparisonRow.jsx", error: String((e && e.message) || e) }); }

// components/social/FriendRow.jsx
try { (() => {
function Avatar({
  label,
  size = 36
}) {
  return /*#__PURE__*/React.createElement("span", {
    style: {
      width: size,
      height: size,
      flex: '0 0 auto',
      borderRadius: 9999,
      background: 'var(--pc-surface-container-high)',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontSize: size * 0.4,
      color: 'var(--pc-on-surface-variant)'
    }
  }, (label || '?').charAt(0).toUpperCase());
}

/**
 * FriendRow — a social relationship row. Variants: searchResult (Aggiungi /
 * "Richiesta inviata"), receivedRequest (Accetta / Rifiuta), sentRequest
 * ("In attesa"), friend (Rimuovi). Hairline divider, no fill.
 * Ground-truthed against friend_row.dart.
 */
function FriendRow({
  handle,
  variant = 'friend',
  requestSent = false,
  onPrimary,
  onSecondary,
  style
}) {
  let trailing = null;
  if (variant === 'searchResult') {
    trailing = requestSent ? /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 13,
        color: 'var(--pc-on-surface-variant)'
      }
    }, "Richiesta inviata") : /*#__PURE__*/React.createElement(__ds_scope.Button, {
      variant: "text",
      size: "sm",
      onClick: onPrimary
    }, "Aggiungi");
  } else if (variant === 'receivedRequest') {
    trailing = /*#__PURE__*/React.createElement("span", {
      style: {
        display: 'inline-flex',
        gap: 8
      }
    }, /*#__PURE__*/React.createElement(__ds_scope.Button, {
      variant: "filled",
      size: "sm",
      onClick: onPrimary
    }, "Accetta"), /*#__PURE__*/React.createElement(__ds_scope.Button, {
      variant: "text",
      size: "sm",
      onClick: onSecondary
    }, "Rifiuta"));
  } else if (variant === 'sentRequest') {
    trailing = /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 13,
        color: 'var(--pc-on-surface-variant)'
      }
    }, "In attesa");
  } else {
    trailing = /*#__PURE__*/React.createElement(__ds_scope.Button, {
      variant: "danger",
      size: "sm",
      onClick: onPrimary
    }, "Rimuovi");
  }
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '12px 4px',
      borderBottom: '1px solid var(--pc-hairline)',
      minHeight: 48,
      ...style
    }
  }, /*#__PURE__*/React.createElement(Avatar, {
    label: handle
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      minWidth: 0,
      fontSize: 15,
      color: 'var(--pc-on-surface)',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, "@", handle), trailing);
}
Object.assign(__ds_scope, { FriendRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/social/FriendRow.jsx", error: String((e && e.message) || e) }); }

// components/social/JoinCodeCard.jsx
try { (() => {
// Deterministic pseudo-QR matrix from the join code — a placeholder standing in
// for the real scannable QR (the app renders a true QR via qr_flutter).
function matrix(code, n = 21) {
  let h = 2166136261;
  for (let i = 0; i < code.length; i++) {
    h ^= code.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  const rand = () => {
    h ^= h << 13;
    h ^= h >>> 17;
    h ^= h << 5;
    return (h >>> 0) / 4294967296;
  };
  const cells = [];
  const finder = (r, c) => r < 7 && c < 7 || r < 7 && c >= n - 7 || r >= n - 7 && c < 7;
  for (let r = 0; r < n; r++) for (let c = 0; c < n; c++) {
    if (finder(r, c)) {
      const rr = r >= n - 7 ? r - (n - 7) : r;
      const cc = c >= n - 7 ? c - (n - 7) : c;
      const on = rr === 0 || rr === 6 || cc === 0 || cc === 6 || rr >= 2 && rr <= 4 && cc >= 2 && cc <= 4;
      if (on) cells.push([r, c]);
    } else if (rand() > 0.55) cells.push([r, c]);
  }
  return {
    cells,
    n
  };
}

/**
 * JoinCodeCard — the shared-session join display. QR (placeholder) + the large
 * join code in Mono with wide tracking + a refresh action. Calm, no expiry
 * countdown pressure. Ground-truthed against join_code_card.dart.
 */
function JoinCodeCard({
  joinCode = 'PULSE-4821',
  onRefresh,
  size = 180,
  style
}) {
  const {
    cells,
    n
  } = React.useMemo(() => matrix(joinCode), [joinCode]);
  const cell = size / n;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      padding: 20,
      borderRadius: 'var(--pc-radius-card)',
      background: 'var(--pc-surface-container)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: 12,
      background: '#FFFFFF',
      borderRadius: 'var(--pc-radius-chip)'
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: size,
    height: size,
    viewBox: `0 0 ${size} ${size}`,
    role: "img",
    "aria-label": `QR per il codice ${joinCode}`
  }, cells.map(([r, c], i) => /*#__PURE__*/React.createElement("rect", {
    key: i,
    x: c * cell,
    y: r * cell,
    width: cell,
    height: cell,
    fill: "#0F1119"
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--pc-font-mono)',
      fontSize: 28,
      fontWeight: 700,
      letterSpacing: '0.18em',
      color: 'var(--pc-on-surface)',
      marginTop: 16
    }
  }, joinCode), /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onRefresh,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 8,
      marginTop: 12,
      padding: '8px 12px',
      background: 'transparent',
      border: 'none',
      color: 'var(--pc-on-surface-variant)',
      fontFamily: 'var(--pc-font-sans)',
      fontSize: 13,
      fontWeight: 500,
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "refresh-cw",
    size: 16
  }), " Rigenera codice"));
}
Object.assign(__ds_scope, { JoinCodeCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/social/JoinCodeCard.jsx", error: String((e && e.message) || e) }); }

// components/social/LeaderboardRow.jsx
try { (() => {
// Medal shape + color per rank (UX-DR23): shape-distinct glyph, never color alone.
// star=gold, hexagon=silver, diamond=bronze. Matches medal_colors.dart.
const MEDAL = {
  1: {
    icon: 'star',
    color: 'var(--pc-medal-gold)',
    label: 'oro'
  },
  2: {
    icon: 'hexagon',
    color: 'var(--pc-medal-silver)',
    label: 'argento'
  },
  3: {
    icon: 'diamond',
    color: 'var(--pc-medal-bronze)',
    label: 'bronzo'
  }
};
function Avatar({
  label,
  size = 30
}) {
  return /*#__PURE__*/React.createElement("span", {
    style: {
      width: size,
      height: size,
      flex: '0 0 auto',
      borderRadius: 9999,
      background: 'var(--pc-surface-container-high)',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontSize: size * 0.4,
      color: 'var(--pc-on-surface-variant)'
    }
  }, (label || '?').charAt(0).toUpperCase());
}

/**
 * LeaderboardRow — a friends-only ranking row. The rank number (Mono) is the
 * primary carrier of standing; top-3 add a shape-distinct medal glyph + text
 * label; points (Mono) sit on the right. The current user's row uses
 * surface-container-high. No overtaken alerts, no points-delta animation.
 * Ground-truthed against leaderboard_row.dart + medal_colors.dart.
 */
function LeaderboardRow({
  rank,
  handle,
  points,
  isOwn = false,
  style
}) {
  const medal = MEDAL[rank];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: '12px 14px',
      borderRadius: 'var(--pc-radius-card)',
      background: isOwn ? 'var(--pc-surface-container-high)' : 'var(--pc-surface-container)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 28,
      fontFamily: 'var(--pc-font-mono)',
      fontSize: 16,
      color: 'var(--pc-on-surface)'
    }
  }, rank, "\xB0"), medal ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: medal.icon,
    size: 20,
    color: medal.color
  }) : /*#__PURE__*/React.createElement("span", {
    style: {
      width: 20
    }
  }), /*#__PURE__*/React.createElement(Avatar, {
    label: handle
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      minWidth: 0,
      fontSize: 15,
      color: 'var(--pc-on-surface)',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, "@", handle), medal && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      color: 'var(--pc-on-surface-variant)'
    }
  }, medal.label), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--pc-font-mono)',
      fontSize: 15,
      color: 'var(--pc-on-surface)',
      minWidth: 34,
      textAlign: 'right'
    }
  }, points));
}
Object.assign(__ds_scope, { LeaderboardRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/social/LeaderboardRow.jsx", error: String((e && e.message) || e) }); }

// components/social/VisibilityTierSelector.jsx
try { (() => {
/**
 * VisibilityTierSelector — a privacy segmented control. Defaults to Privato
 * (privacy-by-default is visually pre-selected). Radius 8 (chip).
 * Ground-truthed against visibility_tier_selector.dart.
 */
function VisibilityTierSelector({
  value = 'private',
  options = [{
    value: 'private',
    label: 'Privato'
  }, {
    value: 'friendsOnly',
    label: 'Solo amici'
  }],
  onChange,
  disabled = false,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    role: "tablist",
    style: {
      display: 'inline-flex',
      padding: 3,
      gap: 3,
      borderRadius: 'var(--pc-radius-chip)',
      background: 'var(--pc-surface-container)',
      border: '1px solid var(--pc-hairline)',
      opacity: disabled ? 0.5 : 1,
      ...style
    }
  }, options.map(opt => {
    const selected = value === opt.value;
    return /*#__PURE__*/React.createElement("button", {
      key: opt.value,
      type: "button",
      role: "tab",
      "aria-selected": selected,
      disabled: disabled,
      onClick: () => !disabled && !selected && onChange && onChange(opt.value),
      style: {
        padding: '8px 16px',
        fontFamily: 'var(--pc-font-sans)',
        fontSize: 13,
        fontWeight: selected ? 600 : 400,
        color: selected ? 'var(--pc-on-surface)' : 'var(--pc-on-surface-variant)',
        background: selected ? 'var(--pc-surface-container-high)' : 'transparent',
        border: '1px solid ' + (selected ? 'var(--pc-outline)' : 'transparent'),
        borderRadius: 'calc(var(--pc-radius-chip) - 2px)',
        cursor: disabled ? 'not-allowed' : 'pointer',
        whiteSpace: 'nowrap'
      }
    }, opt.label);
  }));
}
Object.assign(__ds_scope, { VisibilityTierSelector });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/social/VisibilityTierSelector.jsx", error: String((e && e.message) || e) }); }

// components/today/CompletedSessionCard.jsx
try { (() => {
/**
 * CompletedSessionCard — a done session. Muted (surface-container @ .6,
 * on-surface-variant text), check-circle in primary, no Start. Stays visible
 * (progress made visible); excluded from focus order.
 * Ground-truthed against completed_session_card.dart.
 */
function CompletedSessionCard({
  title,
  durationMinutes = 5,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '10px 16px',
      borderRadius: 'var(--pc-radius-card)',
      background: 'color-mix(in srgb, var(--pc-surface-container) 60%, transparent)',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "check-circle",
    size: 24,
    color: "var(--pc-primary)"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      minWidth: 0,
      fontSize: 15,
      color: 'var(--pc-on-surface-variant)',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, title), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: 'var(--pc-on-surface-variant)'
    }
  }, durationMinutes, " min"));
}
Object.assign(__ds_scope, { CompletedSessionCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/today/CompletedSessionCard.jsx", error: String((e && e.message) || e) }); }

// components/today/CompletionRing.jsx
try { (() => {
/**
 * CompletionRing — 48px progress ring. Track = on-surface-variant @ .2, arc =
 * primary (round cap), center counter in JetBrains Mono 11/500. Informational
 * on Today (n/total); pulses once on the first crossing into fully-complete.
 * Ground-truthed against completion_ring.dart.
 */
function CompletionRing({
  completed = 0,
  total = 3,
  size = 48,
  style
}) {
  const prev = React.useRef(completed >= total && total > 0);
  const [pulse, setPulse] = React.useState(false);
  React.useEffect(() => {
    const isComplete = total > 0 && completed >= total;
    if (isComplete && !prev.current) {
      setPulse(true);
      const t = setTimeout(() => setPulse(false), 600);
      prev.current = true;
      return () => clearTimeout(t);
    }
    prev.current = isComplete;
  }, [completed, total]);
  const stroke = 4;
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const progress = total > 0 ? Math.min(Math.max(completed, 0), total) / total : 0;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: size,
      height: size,
      position: 'relative',
      transform: pulse ? 'scale(1.08)' : 'scale(1)',
      transition: 'transform 300ms ease-in-out',
      ...style
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: size,
    height: size,
    viewBox: `0 0 ${size} ${size}`,
    style: {
      transform: 'rotate(-90deg)'
    }
  }, /*#__PURE__*/React.createElement("circle", {
    cx: size / 2,
    cy: size / 2,
    r: r,
    fill: "none",
    stroke: "var(--pc-track)",
    strokeWidth: stroke
  }), /*#__PURE__*/React.createElement("circle", {
    cx: size / 2,
    cy: size / 2,
    r: r,
    fill: "none",
    stroke: "var(--pc-primary)",
    strokeWidth: stroke,
    strokeLinecap: "round",
    strokeDasharray: c,
    strokeDashoffset: c * (1 - progress),
    style: {
      transition: 'stroke-dashoffset 400ms ease-in-out'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'var(--pc-font-mono)',
      fontSize: Math.max(11, Math.round(size * 0.23)),
      fontWeight: 500,
      color: 'var(--pc-on-surface)'
    }
  }, completed, "/", total));
}
Object.assign(__ds_scope, { CompletionRing });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/today/CompletionRing.jsx", error: String((e && e.message) || e) }); }

// components/today/StateIndicator.jsx
try { (() => {
// Behavioral-state visual map — ground-truthed against state_indicator.dart.
// active=primary/dot · fatigued=secondary/dot · atRisk=tertiary/alert-triangle ·
// recovering=secondary@70%/refresh-cw. The text label is mandatory (Fatigued vs
// Recovering differ only by violet opacity — never hue alone).
const STATE = {
  active: {
    color: 'var(--pc-primary)',
    label: 'Attivo',
    icon: null
  },
  fatigued: {
    color: 'var(--pc-secondary)',
    label: 'Affaticato',
    icon: null
  },
  atRisk: {
    color: 'var(--pc-tertiary)',
    label: 'A rischio',
    icon: 'alert-triangle'
  },
  recovering: {
    color: 'color-mix(in srgb, var(--pc-secondary) 70%, transparent)',
    label: 'In recupero',
    icon: 'refresh-cw'
  }
};

/**
 * StateIndicator — the behavioral-state header on Today. Always pairs the
 * state color with a text label and a one-line plain-language message.
 */
function StateIndicator({
  state = 'active',
  label,
  message,
  style
}) {
  const s = STATE[state] || STATE.active;
  const resolvedLabel = label || s.label;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      ...style
    }
  }, s.icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: s.icon,
    size: 20,
    color: s.color
  }) : /*#__PURE__*/React.createElement("span", {
    style: {
      width: 10,
      height: 10,
      borderRadius: 9999,
      background: s.color,
      flex: '0 0 auto'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 17,
      fontWeight: 500,
      lineHeight: 1.35,
      color: s.color
    }
  }, resolvedLabel), message && /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      lineHeight: 1.45,
      color: 'var(--pc-on-surface-variant)'
    }
  }, message)));
}
Object.assign(__ds_scope, { StateIndicator });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/today/StateIndicator.jsx", error: String((e && e.message) || e) }); }

// components/today/WeeklyGoalIndicator.jsx
try { (() => {
/**
 * WeeklyGoalIndicator — "N di M sessioni questa settimana" over an aqua
 * progress bar. Adds an encouraging line at 0 and a quiet "Obiettivo raggiunto"
 * when complete. Ground-truthed against weekly_goal_indicator.dart.
 */
function WeeklyGoalIndicator({
  completedThisWeek = 0,
  weeklyTarget = 5,
  style
}) {
  const progress = weeklyTarget > 0 ? Math.min(completedThisWeek / weeklyTarget, 1) : 0;
  const isComplete = completedThisWeek >= weeklyTarget && weeklyTarget > 0;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '12px 16px',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      fontWeight: 500,
      color: 'var(--pc-on-surface)'
    }
  }, completedThisWeek, " di ", weeklyTarget, " sessioni questa settimana"), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 8,
      borderRadius: 4,
      background: 'var(--pc-surface-container-high)',
      marginTop: 6,
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      width: `${progress * 100}%`,
      borderRadius: 4,
      background: 'var(--pc-primary)',
      transition: 'width 400ms ease'
    }
  })), completedThisWeek === 0 && /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'var(--pc-on-surface-variant)',
      marginTop: 6
    }
  }, "Inizia la tua prima sessione questa settimana."), isComplete && /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      fontWeight: 700,
      color: 'var(--pc-primary)',
      marginTop: 6
    }
  }, "Obiettivo raggiunto."));
}
Object.assign(__ds_scope, { WeeklyGoalIndicator });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/today/WeeklyGoalIndicator.jsx", error: String((e && e.message) || e) }); }

// components/today/session-meta.js
try { (() => {
// Session-type visual metadata — ground-truthed against session_card_helpers.dart.
// mobility → primary/aqua + leaf; cardio → coral + heart; breathing → secondary/violet + wind.
const SESSION_ACCENT = {
  mobility: 'var(--pc-primary)',
  cardio: 'var(--pc-coral)',
  breathing: 'var(--pc-secondary)'
};
const SESSION_ICON = {
  mobility: 'leaf',
  cardio: 'heart',
  breathing: 'wind'
};
function sessionAccent(type) {
  return SESSION_ACCENT[type] || 'var(--pc-on-surface-variant)';
}
function sessionIcon(type) {
  return SESSION_ICON[type] || 'dumbbell';
}

// Intensity: 1–3 low, 4–7 medium, 8–10 high (Italian labels, per intensityLabel()).
function intensityLabel(intensity) {
  if (typeof intensity === 'string') return intensity;
  if (intensity >= 1 && intensity <= 3) return 'Bassa';
  if (intensity >= 8 && intensity <= 10) return 'Alta';
  return 'Media';
}
Object.assign(__ds_scope, { SESSION_ACCENT, SESSION_ICON, sessionAccent, sessionIcon, intensityLabel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/today/session-meta.js", error: String((e && e.message) || e) }); }

// components/feedback/SessionHistoryTile.jsx
try { (() => {
const LABEL = {
  mobility: 'Mobilità',
  cardio: 'Cardio',
  breathing: 'Respirazione'
};

/**
 * SessionHistoryTile — a row in the Pro session history. Circular type icon,
 * session label, "date · duration" (or "date · Nmin (abbandonata)"), and an RPE
 * badge (or "—"). Abandoned rows render at 0.45 opacity. Ground-truthed against
 * session_history_tile.dart.
 */
function SessionHistoryTile({
  sessionType = 'mobility',
  date,
  durationMinutes = 5,
  rpe = null,
  abandoned = false,
  style
}) {
  const subtitle = abandoned ? `${date} · ${durationMinutes}min (abbandonata)` : `${date} · ${durationMinutes}min`;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '10px 4px',
      opacity: abandoned ? 0.45 : 1,
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 40,
      height: 40,
      flex: '0 0 auto',
      borderRadius: 9999,
      background: 'color-mix(in srgb, var(--pc-primary) 22%, var(--pc-surface-container))',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: __ds_scope.sessionIcon(sessionType),
    size: 20,
    color: "var(--pc-primary)"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      color: 'var(--pc-on-surface)'
    }
  }, LABEL[sessionType] || sessionType), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'var(--pc-on-surface-variant)'
    }
  }, subtitle)), rpe == null ? /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 15,
      color: 'var(--pc-outline)'
    }
  }, "\u2014") : /*#__PURE__*/React.createElement("span", {
    style: {
      padding: '4px 8px',
      borderRadius: 12,
      background: 'color-mix(in srgb, var(--pc-secondary) 22%, var(--pc-surface-container))',
      color: 'var(--pc-secondary)',
      fontSize: 11,
      fontWeight: 600
    }
  }, "RPE ", rpe));
}
Object.assign(__ds_scope, { SessionHistoryTile });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/SessionHistoryTile.jsx", error: String((e && e.message) || e) }); }

// components/social/ActivityFeedCard.jsx
try { (() => {
/**
 * ActivityFeedCard — a friend's explicitly-shared completion. Session icon +
 * @handle + duration + relative time. A single light reaction tap (heart, NO
 * count shown) on others' entries; a revoke (x) on your own. No biometric
 * detail, ever. Ground-truthed against activity_feed_card.dart.
 */
function ActivityFeedCard({
  handle,
  sessionType = 'mobility',
  durationMinutes = 5,
  relativeTime = '2h fa',
  isOwn = false,
  reacted = false,
  onReact,
  onRevoke,
  style
}) {
  const [pulse, setPulse] = React.useState(false);
  const react = () => {
    setPulse(true);
    setTimeout(() => setPulse(false), 300);
    onReact && onReact();
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: 16,
      borderRadius: 'var(--pc-radius-card)',
      background: 'var(--pc-surface-container)',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: __ds_scope.sessionIcon(sessionType),
    size: 32,
    color: __ds_scope.sessionAccent(sessionType)
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      fontWeight: 500,
      color: 'var(--pc-on-surface)'
    }
  }, "@", handle), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'var(--pc-on-surface-variant)',
      marginTop: 2
    }
  }, durationMinutes, " min \xB7 ", relativeTime)), isOwn ? /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": "Revoca",
    onClick: onRevoke,
    style: {
      width: 40,
      height: 40,
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'transparent',
      border: 'none',
      color: 'var(--pc-on-surface-variant)',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "x",
    size: 20
  })) : /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": "Bravo",
    onClick: react,
    style: {
      width: 40,
      height: 40,
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'transparent',
      border: 'none',
      color: reacted ? 'var(--pc-primary)' : 'var(--pc-on-surface-variant)',
      cursor: 'pointer',
      transform: pulse ? 'scale(1.4)' : 'scale(1)',
      transition: 'transform 200ms ease, color 200ms ease'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: reacted ? 'heart' : 'heart',
    size: 22,
    color: reacted ? 'var(--pc-primary)' : 'currentColor'
  })));
}
Object.assign(__ds_scope, { ActivityFeedCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/social/ActivityFeedCard.jsx", error: String((e && e.message) || e) }); }

// components/today/CompactSessionCard.jsx
try { (() => {
/**
 * CompactSessionCard — the "COMING UP / PROSSIME" list item. 56px min height,
 * session-type icon + title + duration + chevron. Tap swaps it into the hero
 * slot in place (no navigation). Selected state tints the fill and shows an
 * accent leading bar. Ground-truthed against compact_session_card.dart.
 */
function CompactSessionCard({
  sessionType = 'mobility',
  title,
  durationMinutes = 5,
  selected = false,
  onTap,
  style
}) {
  const [hover, setHover] = React.useState(false);
  const accent = __ds_scope.sessionAccent(sessionType);
  return /*#__PURE__*/React.createElement("div", {
    role: onTap ? 'button' : undefined,
    onClick: onTap,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => setHover(false),
    style: {
      position: 'relative',
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      minHeight: 56,
      padding: '10px 16px',
      borderRadius: 'var(--pc-radius-card)',
      overflow: 'hidden',
      background: selected ? `color-mix(in srgb, ${accent} 15%, var(--pc-surface-container))` : 'var(--pc-surface-container)',
      cursor: onTap ? 'pointer' : 'default',
      filter: onTap && hover && !selected ? 'brightness(1.08)' : 'none',
      transition: 'filter 120ms ease, background 120ms ease',
      ...style
    }
  }, selected && /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      insetInlineStart: 0,
      top: 0,
      bottom: 0,
      width: 4,
      background: accent
    }
  }), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: __ds_scope.sessionIcon(sessionType),
    size: 24,
    color: accent
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      minWidth: 0,
      fontSize: 15,
      color: 'var(--pc-on-surface)',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, title), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: 'var(--pc-on-surface-variant)'
    }
  }, durationMinutes, " min"), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "chevron-right",
    size: 20,
    color: "var(--pc-on-surface-variant)"
  }));
}
Object.assign(__ds_scope, { CompactSessionCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/today/CompactSessionCard.jsx", error: String((e && e.message) || e) }); }

// components/today/HeroSessionCard.jsx
try { (() => {
/**
 * HeroSessionCard — the primary "today" session card. Carries the one soft
 * hero-zone gradient wash (accent @ .12 → surface-container), the session icon,
 * title, a meta row (duration · intensity), the always-visible ExplanationLine,
 * an optional regenerate action, and a full-width Start button.
 *
 * Ground-truthed against hero_session_card.dart.
 */
function HeroSessionCard({
  sessionType = 'mobility',
  title,
  durationMinutes = 5,
  intensity = 'Bassa',
  location = 'Indoor',
  explanation,
  onStart,
  onRegenerate,
  startLabel = 'Inizia sessione',
  style
}) {
  const accent = __ds_scope.sessionAccent(sessionType);
  const meta = [durationMinutes + ' min', location].filter(Boolean).join(' · ');
  return /*#__PURE__*/React.createElement("div", {
    style: {
      borderRadius: 'var(--pc-radius-card)',
      background: `linear-gradient(135deg, color-mix(in srgb, ${accent} 12%, transparent) 0%, var(--pc-surface-container) 60%)`,
      padding: 'var(--pc-card-pad)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-start',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: __ds_scope.sessionIcon(sessionType),
    size: 32,
    color: accent
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--pc-font-sans)',
      fontSize: 20,
      fontWeight: 600,
      lineHeight: 1.3,
      color: 'var(--pc-on-surface)'
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 12,
      marginTop: 6
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: 'var(--pc-on-surface-variant)'
    }
  }, meta), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: accent
    }
  }, __ds_scope.intensityLabel(intensity)))), onRegenerate && /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onRegenerate,
    "aria-label": "Rigenera",
    title: "Rigenera",
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      width: 40,
      height: 40,
      borderRadius: 'var(--pc-radius-full)',
      background: 'transparent',
      border: 'none',
      color: 'var(--pc-on-surface-variant)',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "refresh-cw",
    size: 20
  }))), explanation && /*#__PURE__*/React.createElement("p", {
    style: {
      margin: '10px 0 0',
      fontSize: 13,
      lineHeight: 1.45,
      color: 'var(--pc-on-surface-variant)'
    }
  }, explanation), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "filled",
    fullWidth: true,
    onClick: onStart
  }, startLabel)));
}
Object.assign(__ds_scope, { HeroSessionCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/today/HeroSessionCard.jsx", error: String((e && e.message) || e) }); }

// ui_kits/pulsecoach_app/app.jsx
try { (() => {
/* PulseCoach UI kit — app shell, bottom nav, and the self-resolving session flow.
   Renders into #root. */
(function () {
  const NS = window.PulseCoachDesignSystem_923364;
  const {
    CountdownOverlay,
    RPEInput,
    Button,
    Icon,
    Badge
  } = NS;
  const INITIAL_PLAN = [{
    type: 'mobility',
    title: 'Mobilità mattutina',
    min: 5,
    intensity: 'Bassa',
    location: 'Indoor',
    explanation: 'Sonno breve + HR a riposo elevata. Partiamo piano.'
  }, {
    type: 'breathing',
    title: 'Respirazione',
    min: 3,
    intensity: 'Bassa',
    location: 'Indoor',
    explanation: 'Un momento per rallentare il respiro.'
  }, {
    type: 'cardio',
    title: 'Cardio serale',
    min: 7,
    intensity: 'Media',
    location: 'Indoor',
    explanation: 'Se hai energia, chiudi la giornata in movimento.'
  }];
  const STEPS = [{
    title: 'Respiro iniziale',
    instruction: 'Inspira lentamente dal naso, espira dalla bocca.'
  }, {
    title: 'Cerchi con le anche',
    instruction: 'Movimento lento e controllato. Respira.'
  }, {
    title: 'Allungo laterale',
    instruction: 'Apri il fianco, senza forzare.'
  }, {
    title: 'Ritorno al respiro',
    instruction: 'Rallenta. Lascia scendere le spalle.'
  }];

  // In-session full-screen view.
  function InSessionView({
    session,
    onEnd
  }) {
    const [stepIdx, setStepIdx] = React.useState(0);
    const [secs, setSecs] = React.useState(8);
    const [hr, setHr] = React.useState(108);
    React.useEffect(() => {
      const t = setInterval(() => {
        setSecs(s => {
          if (s <= 1) {
            setStepIdx(i => {
              if (i >= STEPS.length - 1) {
                clearInterval(t);
                setTimeout(onEnd, 300);
                return i;
              }
              return i + 1;
            });
            return 8;
          }
          return s - 1;
        });
        setHr(h => Math.max(96, Math.min(124, h + (Math.random() * 6 - 3) | 0)));
      }, 1000);
      return () => clearInterval(t);
    }, []);
    const step = STEPS[stepIdx];
    const mm = String(Math.floor(secs / 60)).padStart(2, '0');
    const ss = String(secs % 60).padStart(2, '0');
    const progress = (stepIdx + 1) / STEPS.length;
    return /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        inset: 0,
        background: 'var(--pc-surface)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        padding: '32px 24px 24px'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        top: 16,
        right: 16,
        fontFamily: 'var(--pc-font-mono)',
        fontSize: 14,
        color: 'var(--pc-coral)'
      }
    }, "\u2665 ", hr), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 20,
        fontWeight: 600,
        textAlign: 'center',
        marginTop: 8
      }
    }, step.title), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 13,
        color: 'var(--pc-on-surface-variant)',
        marginTop: 6
      }
    }, "Passo ", stepIdx + 1, " di ", STEPS.length), /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: 'var(--pc-font-mono)',
        fontSize: 48,
        color: 'var(--pc-primary)',
        marginTop: 32
      }
    }, mm, ":", ss), /*#__PURE__*/React.createElement("div", {
      style: {
        width: '100%',
        height: 4,
        borderRadius: 999,
        background: 'var(--pc-surface-container-high)',
        marginTop: 24,
        overflow: 'hidden'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        height: '100%',
        width: `${progress * 100}%`,
        background: 'var(--pc-primary)',
        borderRadius: 999,
        transition: 'width 400ms ease'
      }
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 15,
        color: 'var(--pc-on-surface-variant)',
        textAlign: 'center',
        marginTop: 32
      }
    }, step.instruction), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement(Button, {
      variant: "text",
      onClick: onEnd
    }, "Termina sessione"));
  }
  function MiniSummary({
    session,
    rpe,
    onDone
  }) {
    React.useEffect(() => {
      const t = setTimeout(onDone, 3000);
      return () => clearTimeout(t);
    }, []);
    return /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        inset: 0,
        background: 'var(--pc-scrim)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 24
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'var(--pc-surface-container-high)',
        borderRadius: 16,
        padding: 24,
        textAlign: 'center',
        width: '100%'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "check-circle",
      size: 32,
      color: "var(--pc-primary)"
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 17,
        fontWeight: 600,
        marginTop: 10
      }
    }, session.title), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 13,
        color: 'var(--pc-on-surface-variant)',
        marginTop: 4
      }
    }, session.min, " min \xB7 RPE ", rpe), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 13,
        color: 'var(--pc-on-surface-variant)',
        marginTop: 12
      }
    }, "Fatto. Domani regolo l\u2019intensit\xE0.")));
  }
  function SessionFlow({
    session,
    onFinish
  }) {
    const [phase, setPhase] = React.useState('countdown');
    const [rpe, setRpe] = React.useState(null);
    return /*#__PURE__*/React.createElement(React.Fragment, null, phase === 'countdown' && /*#__PURE__*/React.createElement(CountdownOverlay, {
      sessionTitle: session.title,
      onComplete: () => setPhase('active')
    }), phase === 'active' && /*#__PURE__*/React.createElement(InSessionView, {
      session: session,
      onEnd: () => setPhase('rpe')
    }), phase === 'rpe' && /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        inset: 0,
        background: 'var(--pc-surface)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 24,
        gap: 8
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 20,
        fontWeight: 600
      }
    }, "Com\u2019\xE8 andata?"), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 13,
        color: 'var(--pc-on-surface-variant)',
        marginBottom: 20
      }
    }, "Tocca lo sforzo percepito."), /*#__PURE__*/React.createElement(RPEInput, {
      value: rpe,
      onSelect: v => {
        setRpe(v);
        setTimeout(() => setPhase('summary'), 250);
      }
    })), phase === 'summary' && /*#__PURE__*/React.createElement(MiniSummary, {
      session: session,
      rpe: rpe,
      onDone: onFinish
    }));
  }

  // Bottom navigation — Sessions · Today · Social · Progress (Today default).
  const TABS = [{
    key: 'sessions',
    label: 'Sessions',
    icon: 'dumbbell'
  }, {
    key: 'today',
    label: 'Today',
    icon: 'sun'
  }, {
    key: 'social',
    label: 'Social',
    icon: 'users'
  }, {
    key: 'progress',
    label: 'Progress',
    icon: 'bar-chart-3'
  }];
  function NavBar({
    active,
    onChange
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        borderTop: '1px solid var(--pc-hairline)',
        padding: '10px 4px 14px',
        background: 'var(--pc-surface)'
      }
    }, TABS.map(t => {
      const on = active === t.key;
      return /*#__PURE__*/React.createElement("button", {
        key: t.key,
        type: "button",
        onClick: () => onChange(t.key),
        style: {
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 4,
          background: 'transparent',
          border: 'none',
          cursor: 'pointer',
          color: on ? 'var(--pc-primary)' : 'var(--pc-on-surface-variant)'
        }
      }, /*#__PURE__*/React.createElement(Icon, {
        name: t.icon,
        size: 22,
        color: "currentColor"
      }), /*#__PURE__*/React.createElement("span", {
        style: {
          fontSize: 11
        }
      }, t.label));
    }));
  }
  function App() {
    const [tab, setTab] = React.useState('today');
    const [plan, setPlan] = React.useState(INITIAL_PLAN);
    const [completed, setCompleted] = React.useState(1);
    const [flow, setFlow] = React.useState(null);
    const [upsell, setUpsell] = React.useState(false);
    const promote = idx => setPlan(p => {
      const n = [...p];
      const [s] = n.splice(idx, 1);
      return [s, ...n];
    });
    const finishSession = () => {
      setFlow(null);
      setCompleted(c => Math.min(3, c + 1));
      setPlan(p => p.length > 1 ? [...p.slice(1)] : p);
    };
    let screen = null;
    if (tab === 'today') screen = /*#__PURE__*/React.createElement(window.TodayScreen, {
      plan: plan,
      completed: completed,
      onStart: () => setFlow(plan[0]),
      onPromote: promote
    });else if (tab === 'sessions') screen = /*#__PURE__*/React.createElement(window.SessionsScreen, null);else if (tab === 'social') screen = /*#__PURE__*/React.createElement(window.SocialScreen, null);else if (tab === 'progress') screen = /*#__PURE__*/React.createElement(window.ProgressScreen, {
      onLocked: () => setUpsell(true)
    });
    return /*#__PURE__*/React.createElement("div", {
      className: "phone"
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        padding: '14px 16px 8px'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "menu",
      size: 22,
      color: "var(--pc-on-surface-variant)"
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 17,
        fontWeight: 600
      }
    }, "PulseCoach")), /*#__PURE__*/React.createElement("div", {
      className: "screen"
    }, screen), /*#__PURE__*/React.createElement(NavBar, {
      active: tab,
      onChange: setTab
    }), flow && /*#__PURE__*/React.createElement(SessionFlow, {
      session: flow,
      onFinish: finishSession
    }), upsell && /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        inset: 0,
        background: 'var(--pc-scrim)',
        display: 'flex',
        alignItems: 'flex-end'
      },
      onClick: () => setUpsell(false)
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: '100%'
      },
      onClick: e => e.stopPropagation()
    }, /*#__PURE__*/React.createElement(NS.ProUpsellSheet, {
      onDiscover: () => setUpsell(false),
      onDismiss: () => setUpsell(false)
    }))));
  }
  ReactDOM.createRoot(document.getElementById('root')).render(/*#__PURE__*/React.createElement(App, null));
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/pulsecoach_app/app.jsx", error: String((e && e.message) || e) }); }

// ui_kits/pulsecoach_app/screens.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* PulseCoach UI kit — tab screens. Composes the design-system primitives.
   Exposes TodayScreen, SessionsScreen, SocialScreen, ProgressScreen on window. */
(function () {
  const NS = window.PulseCoachDesignSystem_923364;
  const {
    HeroSessionCard,
    CompactSessionCard,
    CompletedSessionCard,
    StateIndicator,
    CompletionRing,
    WeeklyGoalIndicator,
    SessionCatalogCard,
    Chip,
    LeaderboardRow,
    ActivityFeedCard,
    ComparisonRow,
    VisibilityTierSelector,
    ProUpsellSheet,
    SessionHistoryTile,
    Badge,
    Icon
  } = NS;
  const SecLabel = ({
    children,
    style
  }) => /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      letterSpacing: '.14em',
      textTransform: 'uppercase',
      color: 'var(--pc-on-surface-variant)',
      margin: '18px 2px 10px',
      ...style
    }
  }, children);
  const H1 = ({
    children
  }) => /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 24,
      fontWeight: 600,
      color: 'var(--pc-on-surface)'
    }
  }, children);

  // ── TODAY ──────────────────────────────────────────────────────────────
  function TodayScreen({
    plan,
    completed,
    onStart,
    onPromote
  }) {
    const [hero, ...upcoming] = plan;
    return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: 14
      }
    }, /*#__PURE__*/React.createElement(StateIndicator, {
      state: "active",
      message: "Buon ritmo questa settimana."
    }), /*#__PURE__*/React.createElement(CompletionRing, {
      completed: completed,
      total: 3
    })), /*#__PURE__*/React.createElement(HeroSessionCard, {
      sessionType: hero.type,
      title: hero.title,
      durationMinutes: hero.min,
      intensity: hero.intensity,
      location: hero.location,
      explanation: hero.explanation,
      onStart: onStart,
      onRegenerate: () => {}
    }), upcoming.length > 0 && /*#__PURE__*/React.createElement(SecLabel, null, "Prossime"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 10
      }
    }, upcoming.map((s, i) => /*#__PURE__*/React.createElement(CompactSessionCard, {
      key: s.title,
      sessionType: s.type,
      title: s.title,
      durationMinutes: s.min,
      onTap: () => onPromote(i + 1)
    }))), completed > 0 && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(SecLabel, null, "Completate"), /*#__PURE__*/React.createElement(CompletedSessionCard, {
      title: "Risveglio del corpo",
      durationMinutes: 4
    })));
  }

  // ── SESSIONS ───────────────────────────────────────────────────────────
  function SessionsScreen() {
    const cats = ['Tutte', 'Mobility', 'Cardio', 'Breathing'];
    const [cat, setCat] = React.useState('Tutte');
    const all = [{
      name: 'Risveglio del corpo',
      category: 'Mobility',
      difficulty: 'low',
      durationMinutes: 5
    }, {
      name: 'Anche & colonna',
      category: 'Mobility',
      difficulty: 'medium',
      durationMinutes: 6
    }, {
      name: 'Camminata a intervalli',
      category: 'Cardio',
      difficulty: 'medium',
      durationMinutes: 7
    }, {
      name: 'Circuito completo',
      category: 'Cardio',
      difficulty: 'high',
      durationMinutes: 10
    }, {
      name: 'Respiro quadrato',
      category: 'Breathing',
      difficulty: 'low',
      durationMinutes: 3
    }];
    const items = cat === 'Tutte' ? all : all.filter(i => i.category === cat);
    return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(H1, null, "Sessioni"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 8,
        flexWrap: 'wrap',
        margin: '14px 0 4px'
      }
    }, cats.map(c => /*#__PURE__*/React.createElement(Chip, {
      key: c,
      selectable: true,
      selected: cat === c,
      onClick: () => setCat(c)
    }, c))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 10,
        marginTop: 12
      }
    }, items.map(it => /*#__PURE__*/React.createElement(SessionCatalogCard, _extends({
      key: it.name
    }, it, {
      onTap: () => {}
    })))));
  }

  // ── SOCIAL ─────────────────────────────────────────────────────────────
  function SocialScreen() {
    const [reacted, setReacted] = React.useState(false);
    return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(H1, null, "Social"), /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'var(--pc-surface-container)',
        borderRadius: 16,
        padding: 14,
        marginTop: 14
      }
    }, /*#__PURE__*/React.createElement(SecLabel, {
      style: {
        margin: '0 0 8px'
      }
    }, "Classifica amici \xB7 questa settimana"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 6
      }
    }, /*#__PURE__*/React.createElement(LeaderboardRow, {
      rank: 1,
      handle: "giulia",
      points: 120
    }), /*#__PURE__*/React.createElement(LeaderboardRow, {
      rank: 2,
      handle: "tu",
      points: 110,
      isOwn: true
    }), /*#__PURE__*/React.createElement(LeaderboardRow, {
      rank: 3,
      handle: "marco",
      points: 90
    }), /*#__PURE__*/React.createElement(LeaderboardRow, {
      rank: 4,
      handle: "luca",
      points: 55
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 11,
        color: 'var(--pc-on-surface-variant)',
        marginTop: 8
      }
    }, "Le sessioni condivise valgono pi\xF9 di quelle in solo.")), /*#__PURE__*/React.createElement(SecLabel, null, "Feed"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 8
      }
    }, /*#__PURE__*/React.createElement(ActivityFeedCard, {
      handle: "giulia",
      sessionType: "breathing",
      durationMinutes: 4,
      relativeTime: "2h fa",
      reacted: reacted,
      onReact: () => setReacted(true)
    }), /*#__PURE__*/React.createElement(ActivityFeedCard, {
      handle: "tu",
      sessionType: "mobility",
      durationMinutes: 5,
      isOwn: true,
      onRevoke: () => {}
    })));
  }

  // ── PROGRESS (free + Pro gate) ─────────────────────────────────────────
  function ProgressScreen({
    onLocked
  }) {
    const Gate = ({
      title
    }) => /*#__PURE__*/React.createElement("div", {
      onClick: onLocked,
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        background: 'var(--pc-surface-container)',
        borderRadius: 16,
        padding: 16,
        cursor: 'pointer'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "lock",
      size: 18,
      color: "var(--pc-on-surface-variant)"
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 15,
        color: 'var(--pc-on-surface)'
      }
    }, title), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 11,
        color: 'var(--pc-on-surface-variant)'
      }
    }, "Funzione Pro")), /*#__PURE__*/React.createElement(Badge, {
      tone: "primary",
      variant: "solid"
    }, "Pro"));
    return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(H1, null, "Progressi"), /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'var(--pc-surface-container)',
        borderRadius: 16,
        padding: 16,
        marginTop: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 12,
        color: 'var(--pc-on-surface-variant)'
      }
    }, "Ultima sessione"), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 17,
        fontWeight: 600
      }
    }, "Mobilit\xE0 \xB7 5 min"), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 11,
        color: 'var(--pc-on-surface-variant)',
        marginTop: 4
      }
    }, "RPE 4 \xB7 oggi")), /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'var(--pc-surface-container)',
        borderRadius: 16,
        marginTop: 12
      }
    }, /*#__PURE__*/React.createElement(WeeklyGoalIndicator, {
      completedThisWeek: 3,
      weeklyTarget: 5
    })), /*#__PURE__*/React.createElement(SecLabel, null, "Sblocca con Pro"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 12
      }
    }, /*#__PURE__*/React.createElement(Gate, {
      title: "Storico completo"
    }), /*#__PURE__*/React.createElement(Gate, {
      title: "Amici & confronto"
    })));
  }
  Object.assign(window, {
    TodayScreen,
    SessionsScreen,
    SocialScreen,
    ProgressScreen
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/pulsecoach_app/screens.jsx", error: String((e && e.message) || e) }); }

__ds_ns.SessionCatalogCard = __ds_scope.SessionCatalogCard;

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Chip = __ds_scope.Chip;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.Switch = __ds_scope.Switch;

__ds_ns.ProUpsellSheet = __ds_scope.ProUpsellSheet;

__ds_ns.SessionHistoryTile = __ds_scope.SessionHistoryTile;

__ds_ns.SignInSheet = __ds_scope.SignInSheet;

__ds_ns.CountdownOverlay = __ds_scope.CountdownOverlay;

__ds_ns.RPEInput = __ds_scope.RPEInput;

__ds_ns.ShimmerPlaceholder = __ds_scope.ShimmerPlaceholder;

__ds_ns.ActivityFeedCard = __ds_scope.ActivityFeedCard;

__ds_ns.ComparisonRow = __ds_scope.ComparisonRow;

__ds_ns.FriendRow = __ds_scope.FriendRow;

__ds_ns.JoinCodeCard = __ds_scope.JoinCodeCard;

__ds_ns.LeaderboardRow = __ds_scope.LeaderboardRow;

__ds_ns.VisibilityTierSelector = __ds_scope.VisibilityTierSelector;

__ds_ns.CompactSessionCard = __ds_scope.CompactSessionCard;

__ds_ns.CompletedSessionCard = __ds_scope.CompletedSessionCard;

__ds_ns.CompletionRing = __ds_scope.CompletionRing;

__ds_ns.HeroSessionCard = __ds_scope.HeroSessionCard;

__ds_ns.StateIndicator = __ds_scope.StateIndicator;

__ds_ns.WeeklyGoalIndicator = __ds_scope.WeeklyGoalIndicator;

__ds_ns.SESSION_ACCENT = __ds_scope.SESSION_ACCENT;

__ds_ns.SESSION_ICON = __ds_scope.SESSION_ICON;

})();
