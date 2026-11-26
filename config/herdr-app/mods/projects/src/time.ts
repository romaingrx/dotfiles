const MINUTE = 60_000;

/** A short age for a row: "now", "5m", "2h", "3d". */
export function age(elapsed: number): string {
  const minutes = Math.floor(elapsed / MINUTE);
  if (minutes < 1) return "now";
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  return hours < 24 ? `${hours}h` : `${Math.floor(hours / 24)}d`;
}
