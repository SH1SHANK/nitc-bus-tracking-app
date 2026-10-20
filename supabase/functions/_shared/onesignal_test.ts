import { assertEquals } from "jsr:@std/assert@1";
import {
  buildTargetBatches,
  sendOneSignalNotificationToTargets,
} from "./onesignal.ts";

Deno.test("OneSignal targeting keeps aliases and subscriptions in separate requests", () => {
  assertEquals(
    buildTargetBatches(["user-b", "user-a", "user-a"], [
      "device-b",
      "device-a",
    ]),
    [
      { kind: "external_id", ids: ["user-a", "user-b"] },
      { kind: "subscription_id", ids: ["device-a", "device-b"] },
    ],
  );
});

Deno.test("OneSignal targeting chunks batches at the documented API limit", () => {
  const batches = buildTargetBatches(
    Array.from({ length: 20_001 }, (_, index) => `user-${index}`),
    [],
  );

  assertEquals(batches.map(({ ids }) => ids.length), [20_000, 1]);
});

Deno.test("targeted sends split users and guests and reuse idempotency keys", async () => {
  const appId = Deno.env.get("ONESIGNAL_APP_ID");
  const apiKey = Deno.env.get("ONESIGNAL_REST_API_KEY");
  const originalFetch = globalThis.fetch;
  const requests: Record<string, unknown>[] = [];

  Deno.env.set("ONESIGNAL_APP_ID", "test-app");
  Deno.env.set("ONESIGNAL_REST_API_KEY", "test-key");
  globalThis.fetch = async (_input, init) => {
    requests.push(JSON.parse(String(init?.body)));
    return new Response(
      JSON.stringify({ id: `message-${requests.length}`, recipients: 1 }),
    );
  };

  try {
    const payload = { headings: { en: "Test" }, contents: { en: "Test body" } };
    const targets = {
      externalIds: ["user-1", "user-1"],
      subscriptionIds: ["device-1"],
      idempotencyKey: "event-1",
    };
    const result = await sendOneSignalNotificationToTargets(payload, targets);

    assertEquals(result.success, true);
    assertEquals(requests.length, 2);
    assertEquals("include_aliases" in requests[0], true);
    assertEquals("include_subscription_ids" in requests[0], false);
    assertEquals("include_aliases" in requests[1], false);
    assertEquals("include_subscription_ids" in requests[1], true);
    assertEquals(typeof requests[0].idempotency_key, "string");
    assertEquals(typeof requests[1].idempotency_key, "string");
    const firstKeys = requests.map((request) => request.idempotency_key);

    await sendOneSignalNotificationToTargets(payload, targets);
    assertEquals(
      requests.slice(2).map((request) => request.idempotency_key),
      firstKeys,
    );
  } finally {
    globalThis.fetch = originalFetch;
    if (appId === undefined) Deno.env.delete("ONESIGNAL_APP_ID");
    else Deno.env.set("ONESIGNAL_APP_ID", appId);
    if (apiKey === undefined) Deno.env.delete("ONESIGNAL_REST_API_KEY");
    else Deno.env.set("ONESIGNAL_REST_API_KEY", apiKey);
  }
});
