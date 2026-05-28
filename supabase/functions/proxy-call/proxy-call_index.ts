import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ─── Types ────────────────────────────────────────────────────────────────────
interface ProxyCallRequest {
  ticket_id: string
  technician_id: string
  user_id: string
  caller_role: 'user' | 'technician'
  caller_id: string
}

// ─── Main handler ─────────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const body: ProxyCallRequest = await req.json()
    const { ticket_id, technician_id, user_id, caller_role, caller_id } = body

    // ─── 1. ยืนยันว่า caller เป็น user หรือช่างของ ticket นี้จริง ──────────
    const { data: ticket, error: ticketErr } = await supabase
      .from('tickets')
      .select('id, created_by, assigned_to, status')
      .eq('id', ticket_id)
      .single()

    if (ticketErr || !ticket) {
      return jsonError('ticket not found', 404)
    }

    const isLegitCaller =
      (caller_role === 'user' && caller_id === ticket.created_by) ||
      (caller_role === 'technician' && caller_id === ticket.assigned_to)

    if (!isLegitCaller) {
      return jsonError('unauthorized caller', 403)
    }

    // ─── 2. ดึงเบอร์จริงของฝ่ายตรงข้าม (ไม่ส่งกลับ client) ────────────────
    const targetId = caller_role === 'user' ? technician_id : user_id
    const { data: profile } = await supabase
      .from('profiles')
      .select('phone')
      .eq('id', targetId)
      .single()

    const targetPhone = profile?.phone as string | null

    // ─── 3. บันทึก call log ──────────────────────────────────────────────────
    const sessionToken = crypto.randomUUID()
    await supabase.from('call_logs').insert({
      id: sessionToken,
      ticket_id,
      caller_id,
      caller_role,
      technician_id,
      user_id,
      started_at: new Date().toISOString(),
      status: 'initiated',
    })

    // ─── 4. ถ้ามี Twilio / VOIP provider — สร้าง proxy number ───────────────
    //    ตัวอย่าง: ใช้ Twilio Proxy API
    const twilioSid = Deno.env.get('TWILIO_ACCOUNT_SID')
    const twilioToken = Deno.env.get('TWILIO_AUTH_TOKEN')
    const twilioProxyService = Deno.env.get('TWILIO_PROXY_SERVICE_SID')

    if (twilioSid && twilioToken && twilioProxyService && targetPhone) {
      try {
        // สร้าง Twilio Proxy Session
        const twilioRes = await fetch(
          `https://proxy.twilio.com/v1/Services/${twilioProxyService}/Sessions`,
          {
            method: 'POST',
            headers: {
              Authorization: 'Basic ' + btoa(`${twilioSid}:${twilioToken}`),
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
              UniqueName: sessionToken,
              Ttl: '3600', // 1 ชั่วโมง
            }),
          }
        )

        if (twilioRes.ok) {
          const session = await twilioRes.json()

          // เพิ่ม participant ฝั่ง caller (ได้ proxy number)
          const callerPhone = await getCallerPhone(supabase, caller_id)
          if (callerPhone) {
            const partRes = await fetch(
              `https://proxy.twilio.com/v1/Services/${twilioProxyService}/Sessions/${session.sid}/Participants`,
              {
                method: 'POST',
                headers: {
                  Authorization: 'Basic ' + btoa(`${twilioSid}:${twilioToken}`),
                  'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: new URLSearchParams({ Identifier: callerPhone }),
              }
            )

            if (partRes.ok) {
              const part = await partRes.json()
              // proxy_number คือเบอร์ที่ caller จะโทรไป (ไม่ใช่เบอร์จริงของฝั่งตรงข้าม)
              return new Response(
                JSON.stringify({
                  proxy_number: part.proxy_identifier,
                  session_token: sessionToken,
                }),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
              )
            }
          }
        }
      } catch (_) {
        // Twilio error → fallback ต่อ
      }
    }

    // ─── 5. Fallback: ส่ง session_token กลับ → app แสดง in-app call UI ──────
    return new Response(
      JSON.stringify({ session_token: sessionToken }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    return jsonError(`internal error: ${err}`, 500)
  }
})

// ─── Helpers ──────────────────────────────────────────────────────────────────
async function getCallerPhone(supabase: ReturnType<typeof createClient>, userId: string) {
  const { data } = await supabase
    .from('profiles')
    .select('phone')
    .eq('id', userId)
    .single()
  return (data?.phone as string) ?? null
}

function jsonError(message: string, status: number) {
  return new Response(
    JSON.stringify({ error: message }),
    { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
}
