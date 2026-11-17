from app.database_complete import db_complete as db
import asyncio

async def check_enum():
    result = await db.execute_query("""
        SELECT unnest(enum_range(NULL::user_role))::text as role_value
    """)
    print('\nActual database enum values:')
    for row in result:
        print(f'  - {row["role_value"]}')

asyncio.run(check_enum())
