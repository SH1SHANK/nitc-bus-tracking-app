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
}

export interface OneSignalDispatchResult {
  success: boolean;
  id?: string;
  recipients?: number;
  errors?: unknown;
  rawResponse?: unknown;
}

export async function sendOneSignalNotification(
  payload: OneSignalNotificationPayload
): Promise<OneSignalDispatchResult> {
  const appId = Deno.env.get("ONESIGNAL_APP_ID");
  const restApiKey = Deno.env.get("ONESIGNAL_REST_API_KEY");

  if (!appId || !restApiKey) {
    console.warn(
      "[OneSignal] Missing ONESIGNAL_APP_ID or ONESIGNAL_REST_API_KEY. Simulating delivery failure."
    );
    return {
      success: false,
      errors: ["Missing OneSignal environment credentials (ONESIGNAL_APP_ID or ONESIGNAL_REST_API_KEY)"],
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
      console.error("[OneSignal] REST API error response:", response.status, data);
      return {
        success: false,
        errors: data?.errors || [`HTTP ${response.status}: ${JSON.stringify(data)}`],
        rawResponse: data,
      };
    }

    return {
      success: true,
      id: data?.id,
      recipients: data?.recipients ?? 0,
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
