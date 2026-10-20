import { assertEquals } from "jsr:@std/assert@1";
import {
  fetchAllPages,
  partitionSubscriptionRecipients,
} from "./notification_recipients.ts";

Deno.test("recipient pagination visits every stable keyset page once", async () => {
  const rows = Array.from({ length: 1_205 }, (_, index) => ({
    id: `id-${String(index).padStart(4, "0")}`,
  }));
  const cursors: Array<string | null> = [];
  const result = await fetchAllPages(async (afterId, limit) => {
    cursors.push(afterId);
    const page = rows.filter((row) => afterId === null || row.id > afterId)
      .slice(0, limit);
    return { data: page, error: null };
  });

  assertEquals(cursors, [null, "id-0499", "id-0999"]);
  assertEquals(result.length, 1_205);
  assertEquals(new Set(result.map((row) => row.id)).size, 1_205);
});

Deno.test("recipient page failures stop collection", async () => {
  let calls = 0;
  await fetchAllPages(async () => {
    calls++;
    return { data: null, error: new Error("database unavailable") };
  }).then(
    () => {
      throw new Error("expected pagination to reject");
    },
    (error) => assertEquals(error.message, "database unavailable"),
  );
  assertEquals(calls, 1);
});

Deno.test("recipient partition keeps authenticated and guest targets isolated", () => {
  assertEquals(
    partitionSubscriptionRecipients([
      {
        id: "auth-row",
        user_id: "auth-user",
        guest_device_id: "should-not-leak",
        onesignal_subscription_id: "auth-subscription",
      },
      {
        id: "guest-row",
        user_id: null,
        guest_device_id: "guest-device",
        onesignal_subscription_id: "guest-subscription",
      },
    ]),
    {
      userIds: ["auth-user"],
      guestIds: ["guest-device"],
      externalIds: ["auth-user"],
      subscriptionIds: ["guest-subscription"],
    },
  );
});
