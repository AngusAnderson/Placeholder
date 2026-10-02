import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(
        string: "https://pbwbjennjihbyqwthimm.supabase.co"
    )!

    static let publishableKey =
        "sb_publishable_V-5U-3Mh8GojeZ8PjcdmoQ_ruaANriJ"
}

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.publishableKey
)