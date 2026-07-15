/** ISO range covering seeded slots (next few days from "today"). */
export function slotRangeQuery(): { from: string; to: string } {
  const from = new Date();
  const to = new Date();
  to.setUTCDate(to.getUTCDate() + 7);

  return {
    from: from.toISOString(),
    to: to.toISOString(),
  };
}
