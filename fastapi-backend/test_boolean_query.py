#!/usr/bin/env python3
from supabase import create_client
import os
from dotenv import load_dotenv
load_dotenv()

supabase = create_client(os.getenv('SUPABASE_URL'), os.getenv('SUPABASE_SERVICE_KEY'))

# Test with capital True
resp1 = supabase.table('profiles').select('id', count='exact').eq('company_id', '01e20568-18c6-4020-a3b3-6c717a023baf').eq('is_active', True).execute()
print(f'With True: count={resp1.count}, len={len(resp1.data)}')

# Test with lowercase true string
resp2 = supabase.table('profiles').select('id', count='exact').eq('company_id', '01e20568-18c6-4020-a3b3-6c717a023baf').eq('is_active', 'true').execute()
print(f'With "true": count={resp2.count}, len={len(resp2.data)}')

# Test without is_active filter
resp3 = supabase.table('profiles').select('id', count='exact').eq('company_id', '01e20568-18c6-4020-a3b3-6c717a023baf').execute()
print(f'Without filter: count={resp3.count}, len={len(resp3.data)}')

# Test with select *
resp4 = supabase.table('profiles').select('*').eq('company_id', '01e20568-18c6-4020-a3b3-6c717a023baf').eq('is_active', True).execute()
print(f'With select *: len={len(resp4.data)}')
for r in resp4.data:
    print(f"  {r['email']}: is_active={r['is_active']}")
