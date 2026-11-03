/**
 * ============================================================================
 * TALUK LIBRARY COUNCIL - SUPABASE CLOUD CONFIGURATION
 * ============================================================================
 * Fill in your Supabase Project URL and Anon Public Key below so every device
 * opening your hosted site connects automatically to your SQL database.
 *
 * NOTE ON SECURITY:
 * The Supabase "anon" public key is designed to be used in browser apps when
 * paired with Row Level Security (RLS). Because `supabase_sql_migration.sql`
 * locks all tables strictly to signed-in `authenticated` staff, anonymous
 * visitors cannot read, modify, or delete any council data without logging in.
 *
 * You can also leave these empty ("") and configure credentials inside the app
 * via the "⚡ Supabase" button in the bottom-left sidebar.
 * ============================================================================
 */
window.COUNCIL_SUPABASE_CONFIG = {
  url: "",      // Example: "https://xyzcompany.supabase.co"
  anonKey: ""   // Example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
};

