import { corsHeaders } from "./cors.ts";

/**
 * Validates that an incoming worker request is authorized to perform privileged tasks.
 * Authorized callers must provide either:
 *  1. An `x-scheduler-secret` header matching `Deno.env.get("SCHEDULER_SECRET")`, OR
 *  2. An `Authorization: Bearer <service_role_key>` header matching `Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")`.
 *
 * Regular authenticated user JWTs will fail this check and receive 403 Forbidden.
 */
export function verifySchedulerOrServiceRole(req: Request): Response | null {
  const schedulerSecret = Deno.env.get("SCHEDULER_SECRET");
  const providedSchedulerSecret = req.headers.get("x-scheduler-secret");

  if (schedulerSecret && providedSchedulerSecret && providedSchedulerSecret === schedulerSecret) {
    return null; // Authorized via scheduler secret
  }

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const authHeader = req.headers.get("authorization") || req.headers.get("Authorization");

  if (serviceRoleKey && authHeader) {
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (token === serviceRoleKey) {
      return null; // Authorized via service role bearer token
    }
  }

  return new Response(
    JSON.stringify({
      error: "Forbidden: Caller is not an authorized scheduler or service role worker",
    }),
    {
      status: 403,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
}
