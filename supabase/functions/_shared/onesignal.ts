// ============================================================================
// OneSignal REST API Client (Server-Side Only)
// Note: App ID and REST API Key are loaded strictly from server-side environment
// variables (ONESIGNAL_APP_ID, ONESIGNAL_REST_API_KEY).
// ============================================================================

export interface OneSignalNotificationPayload {
  contents: { en: string };
  headings?: { en: string };
  data?: Record<string, unknown>;
  // Delivery targeting options
  include_aliases?: {
    external_id?: string[];
    onesignal_id?: string[];
  };
  include_subscription_ids?: string[];
  included_segments?: string[];
  // Platform specific
  android_channel_id?: string;
  url?: string;
  ttl?: number;
  idempotency_key?: string;
}

export interface OneSignalDispatchResult {
  // `success` means OneSignal accepted every request; it does not confirm device delivery.
  success: boolean;
  id?: string;
  recipients?: number;
  errors?: unknown;
  rawResponse?: unknown;
}

const MAX_TARGETS_PER_REQUEST = 20_000;

export function buildTargetBatches(
  externalIds: string[],
  subscriptionIds: string[],
): Array<{ kind: "external_id" | "subscription_id"; ids: string[] }> {
  const batches: Array<
    { kind: "external_id" | "subscription_id"; ids: string[] }
  > = [];
  for (
    const [kind, values] of [
      ["external_id", externalIds],
      ["subscription_id", subscriptionIds],
    ] as const
  ) {
    const uniqueIds = [...new Set(values.filter(Boolean))].sort();
    for (
      let offset = 0;
      offset < uniqueIds.length;
      offset += MAX_TARGETS_PER_REQUEST
    ) {
      batches.push({
        kind,
        ids: uniqueIds.slice(offset, offset + MAX_TARGETS_PER_REQUEST),
      });
    }
  }
  return batches;
}

async function requestIdempotencyKey(key: string): Promise<string> {
  const digest = new Uint8Array(
    await crypto.subtle.digest("SHA-256", new TextEncoder().encode(key)),
  );
  digest[6] = (digest[6] & 0x0f) | 0x50;
  digest[8] = (digest[8] & 0x3f) | 0x80;
  const hex = [...digest.slice(0, 16)].map((value) =>
    value.toString(16).padStart(2, "0")
  ).join("");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${
    hex.slice(16, 20)
  }-${hex.slice(20)}`;
}

export async function sendOneSignalNotification(
  payload: OneSignalNotificationPayload,
): Promise<OneSignalDispatchResult> {
  if (payload.include_aliases && payload.include_subscription_ids) {
    return {
      success: false,
      errors: [
        "OneSignal does not allow aliases and subscription IDs in the same request",
      ],
    };
  }
  const appId = Deno.env.get("ONESIGNAL_APP_ID");
  const restApiKey = Deno.env.get("ONESIGNAL_REST_API_KEY");

  if (!appId || !restApiKey) {
    console.warn(
      "[OneSignal] Missing ONESIGNAL_APP_ID or ONESIGNAL_REST_API_KEY. Simulating delivery failure.",
    );
    return {
      success: false,
      errors: [
        "Missing OneSignal environment credentials (ONESIGNAL_APP_ID or ONESIGNAL_REST_API_KEY)",
      ],
    };
  }

  const body = {
    app_id: appId,
    target_channel: "push",
    ...payload,
  };

  try {
    const response = await fetch("https://api.onesignal.com/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        Authorization: `Key ${restApiKey}`,
      },
      body: JSON.stringify(body),
    });

    const data = await response.json().catch(() => null);

    if (!response.ok) {
      console.error(
        "[OneSignal] REST API request failed with status",
        response.status,
      );
      return {
        success: false,
        errors: data?.errors ||
          [`HTTP ${response.status}: ${JSON.stringify(data)}`],
        rawResponse: data,
      };
    }

    return {
      success: Boolean(data?.id),
      id: data?.id,
      recipients: data?.recipients ?? 0,
      errors: data?.id
        ? data?.errors
        : ["OneSignal returned no notification ID"],
      rawResponse: data,
    };
  } catch (error) {
    console.error("[OneSignal] Network or execution error:", error);
    return {
      success: false,
      errors: [error instanceof Error ? error.message : String(error)],
    };
  }
}

export async function sendOneSignalNotificationToTargets(
  payload: OneSignalNotificationPayload,
  targets: {
    externalIds: string[];
    subscriptionIds: string[];
    idempotencyKey: string;
  },
): Promise<OneSignalDispatchResult> {
  const batches = buildTargetBatches(
    targets.externalIds,
    targets.subscriptionIds,
  );
  if (batches.length === 0) return { success: true, recipients: 0 };

  const results: OneSignalDispatchResult[] = [];
  for (const [index, batch] of batches.entries()) {
    const target = batch.kind === "external_id"
      ? { include_aliases: { external_id: batch.ids } }
      : { include_subscription_ids: batch.ids };
    const idempotencyKey = await requestIdempotencyKey(
      `${targets.idempotencyKey}:${batch.kind}:${index}:${batch.ids.join(",")}`,
    );
    results.push(
      await sendOneSignalNotification({
        ...payload,
        ...target,
        idempotency_key: idempotencyKey,
      }),
    );
  }

  return {
    success: results.every((result) => result.success),
    id: results.find((result) => result.id)?.id,
    recipients: results.reduce(
      (total, result) => total + (result.recipients ?? 0),
      0,
    ),
    errors: results.flatMap((result) => result.errors ? [result.errors] : []),
    rawResponse: results.map(({ rawResponse }) => rawResponse),
  };
}
