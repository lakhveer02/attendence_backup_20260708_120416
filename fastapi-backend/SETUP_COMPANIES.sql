-- ============================================================================
-- ENSURE COMPANIES TABLE HAS DATA
-- This creates the Squadminds company if it doesn't exist
-- ============================================================================

-- Step 1: Check existing companies
SELECT * FROM companies ORDER BY created_at DESC LIMIT 10;

-- Step 2: Insert Squadminds company if not exists
INSERT INTO companies (
    id,
    name,
    email,
    phone,
    address,
    is_active,
    created_at,
    updated_at
)
VALUES (
    'b090d51d-3a18-4a0a-8c18-25765fc43456',
    'Squadminds Private Limited',
    'chetan@squadminds.com',
    '+91-9999999999',
    'India',
    true,
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE
SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    updated_at = NOW();

-- Step 3: Verify company exists
SELECT * FROM companies WHERE id = 'b090d51d-3a18-4a0a-8c18-25765fc43456';

-- Step 4: Create departments for the company
INSERT INTO departments (
    id,
    company_id,
    name,
    description,
    is_active,
    created_at,
    updated_at
)
VALUES 
    (gen_random_uuid(), 'b090d51d-3a18-4a0a-8c18-25765fc43456', 'Management', 'Executive Management', true, NOW(), NOW()),
    (gen_random_uuid(), 'b090d51d-3a18-4a0a-8c18-25765fc43456', 'Engineering', 'Software Development', true, NOW(), NOW()),
    (gen_random_uuid(), 'b090d51d-3a18-4a0a-8c18-25765fc43456', 'Sales', 'Sales and Marketing', true, NOW(), NOW()),
    (gen_random_uuid(), 'b090d51d-3a18-4a0a-8c18-25765fc43456', 'HR', 'Human Resources', true, NOW(), NOW())
ON CONFLICT (company_id, name) DO NOTHING;

-- Step 5: Show departments
SELECT d.*, c.name as company_name
FROM departments d
JOIN companies c ON d.company_id = c.id
WHERE c.id = 'b090d51d-3a18-4a0a-8c18-25765fc43456';
