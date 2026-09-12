// Indian Standard Time (IST) utility: (UTC+05:30) Chennai, Kolkata, Mumbai, New Delhi
export const IST_TIMEZONE = 'Asia/Kolkata';

/**
 * Format date and time in Indian Standard Time (UTC+05:30)
 * Example: "12 Sep 2026, 08:48 AM"
 */
export function formatDateTimeIST(dateInput) {
  if (!dateInput) return '—';
  const date = typeof dateInput === 'string' || typeof dateInput === 'number'
    ? new Date(dateInput)
    : dateInput;

  if (isNaN(date.getTime())) return '—';

  return date.toLocaleString('en-IN', {
    timeZone: IST_TIMEZONE,
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  });
}

/**
 * Format time only in Indian Standard Time (UTC+05:30)
 * Example: "08:48 AM"
 */
export function formatTimeIST(dateInput) {
  if (!dateInput) return '—';
  const date = typeof dateInput === 'string' || typeof dateInput === 'number'
    ? new Date(dateInput)
    : dateInput;

  if (isNaN(date.getTime())) return '—';

  return date.toLocaleTimeString('en-IN', {
    timeZone: IST_TIMEZONE,
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  });
}

/**
 * Format date only in Indian Standard Time (UTC+05:30)
 * Example: "12 Sep 2026"
 */
export function formatDateIST(dateInput) {
  if (!dateInput) return '—';
  const date = typeof dateInput === 'string' || typeof dateInput === 'number'
    ? new Date(dateInput)
    : dateInput;

  if (isNaN(date.getTime())) return '—';

  return date.toLocaleDateString('en-IN', {
    timeZone: IST_TIMEZONE,
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}
