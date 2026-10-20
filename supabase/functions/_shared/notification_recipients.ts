export const RECIPIENT_PAGE_SIZE = 500;

export interface NotificationSubscription {
  id: string;
  user_id: string | null;
  guest_device_id: string | null;
  onesignal_subscription_id: string | null;
}

export function partitionSubscriptionRecipients(
  subscriptions: NotificationSubscription[],
) {
  const userIds = new Set<string>();
  const guestIds = new Set<string>();
  const externalIds = new Set<string>();
  const subscriptionIds = new Set<string>();

  for (const subscription of subscriptions) {
    if (subscription.user_id) {
      userIds.add(subscription.user_id);
      externalIds.add(subscription.user_id);
    } else if (subscription.guest_device_id) {
      guestIds.add(subscription.guest_device_id);
      if (subscription.onesignal_subscription_id) {
        subscriptionIds.add(subscription.onesignal_subscription_id);
      }
    } else if (subscription.onesignal_subscription_id) {
      subscriptionIds.add(subscription.onesignal_subscription_id);
    }
  }

  return {
    userIds: [...userIds].sort(),
    guestIds: [...guestIds].sort(),
    externalIds: [...externalIds].sort(),
    subscriptionIds: [...subscriptionIds].sort(),
  };
}

export async function fetchAllPages<T extends { id: string }>(
  fetchPage: (
    afterId: string | null,
    limit: number,
  ) => Promise<{ data: T[] | null; error: unknown | null }>,
): Promise<T[]> {
  const rows: T[] = [];
  const seen = new Set<string>();
  let afterId: string | null = null;

  while (true) {
    const { data, error } = await fetchPage(afterId, RECIPIENT_PAGE_SIZE);
    if (error) throw error;

    const page = data ?? [];
    for (const row of page) {
      if (!seen.has(row.id)) {
        seen.add(row.id);
        rows.push(row);
      }
    }

    if (page.length < RECIPIENT_PAGE_SIZE) return rows;

    const nextAfterId = page[page.length - 1]?.id;
    if (!nextAfterId || (afterId !== null && nextAfterId <= afterId)) {
      throw new Error("Notification recipient pagination did not advance");
    }
    afterId = nextAfterId;
  }
}
