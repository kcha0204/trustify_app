import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL!,
  import.meta.env.VITE_SUPABASE_ANON_KEY!
)


import { supabase } from './lib/supabase'

// Helper: panic on error
function assertOk<T>(data: T | null, error: any): T {
  if (error) throw error
  if (data === null || data === undefined) throw new Error('Empty result')
  return data
}

export async function runDemo() {
  // 1) Upsert a text item (BOM/ï»¿ will be stripped by DB trigger; content_hash auto-filled)
  const { data: insertedId, error: upsertErr } = await supabase.rpc('upsert_text_item', {
    p_session_id: 'sess-ui-demo',
    p_text: 'Hello from UI',
    p_preview: 'Hello from UI',
    p_source: 'web'
  })
  const id = assertOk(insertedId, upsertErr)
  console.log('Inserted ID:', id)

  // 2) (Optional) Store model label/score for that item
  const { error: aiErr } = await supabase.rpc('update_item_ai_result', {
    p_id: id,
    p_provider: 'azure',
    p_label: 'safe',
    p_score: 0.97
  })
  if (aiErr) throw aiErr
  console.log('AI result saved.')

  // 3) (Optional) Update embedding (must be a 1536-d float array already normalized or not)
  // If you DON'T have embeddings on the client (recommended to keep keys server-side),
  // skip this step and just use keyword/metadata flows.
  const demoEmbedding: number[] = Array.from({ length: 1536 }, (_, i) => (i === 0 ? 0.12 : i === 1 ? -0.03 : i === 2 ? 0.08 : 0))
  const { error: embErr } = await supabase.rpc('update_item_embedding_normalized', {
    p_id: id,
    p_vec: demoEmbedding
  })
  if (embErr) throw embErr
  console.log('Embedding saved.')

  // 4) Top-K cosine search (requires target items to have non-zero embeddings)
  const queryEmbedding: number[] = demoEmbedding // replace with real query vector
  const { data: hits, error: searchErr } = await supabase.rpc('search_topk', {
    p_session_id: 'sess-ui-demo',   // pass null to search across all sessions
    p_vec: queryEmbedding,
    p_k: 5,
    p_only_nonzero: true            // ignore rows with zero vectors
  })
  const results = assertOk(hits, searchErr)
  console.table(results) // [{ id, session_id, kind, preview, distance }, ...]
}

