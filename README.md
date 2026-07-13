import { createClient } from "@supabase/supabase-js"; 

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  // eslint-disable-next-line no-console
  console.error(
    "Missing Supabase env vars. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY " +
    "(in a local .env file, or in your Vercel project settings)."
  );
}

const supabase = createClient(supabaseUrl || "", supabaseKey || "");

const LS_PREFIX = "cpa_";

// Mirrors the same shape as the Claude artifact's window.storage API,
// so the rest of the app didn't need to change:
//   shared = false -> stored per-browser in localStorage (e.g. "which account am I on this device")
//   shared = true  -> stored in Supabase, visible to the whole team
export const storage = {
  async get(key, shared = false) {
    if (!shared) {
      const value = localStorage.getItem(LS_PREFIX + key);
      if (value === null) throw new Error("not found");
      return { key, value, shared: false };
    }
    const { data, error } = await supabase
      .from("kv_store")
      .select("value")
      .eq("key", key)
      .maybeSingle();
    if (error) throw error;
    if (!data) throw new Error("not found");
    return { key, value: data.value, shared: true };
  },

  async set(key, value, shared = false) {
    if (!shared) {
      localStorage.setItem(LS_PREFIX + key, value);
      return { key, value, shared: false };
    }
    const { error } = await supabase.from("kv_store").upsert({ key, value });
    if (error) throw error;
    return { key, value, shared: true };
  },

  async delete(key, shared = false) {
    if (!shared) {
      localStorage.removeItem(LS_PREFIX + key);
      return { key, deleted: true, shared: false };
    }
    const { error } = await supabase.from("kv_store").delete().eq("key", key);
    if (error) throw error;
    return { key, deleted: true, shared: true };
  },

  async list(prefix = "", shared = false) {
    if (!shared) {
      const keys = Object.keys(localStorage)
        .filter((k) => k.startsWith(LS_PREFIX + prefix))
        .map((k) => k.slice(LS_PREFIX.length));
      return { keys, prefix, shared: false };
    }
    const { data, error } = await supabase
      .from("kv_store")
      .select("key")
      .ilike("key", `${prefix}%`);
    if (error) throw error;
    return { keys: (data || []).map((d) => d.key), prefix, shared: true };
  },
};
