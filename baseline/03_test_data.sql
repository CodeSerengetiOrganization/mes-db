Use mes_db;

-- Prerequisite: manufacturing order (not seeded in 02_system_metadata.sql)
INSERT INTO manufacturing_orders (
    order_number,
    part_number,
    product_type,
    revision,
    target_quantity,
    order_status,
    created_by
) VALUES (
    'PO-2026-TEST-001',
    'SCU-CD4',
    'SCU',
    'A',
    100,
    'RELEASED',
    'test_script'
);

-- Sample EOL result: G1 controller + G1 fixture, nest 1, PASS
INSERT INTO manufacturing_result (
    serial_number,
    product_type,
    mo_id,
    station_id,
    controller_id,
    fixture_id,
    nest_number,
    overall_result,
    cycle_time_seconds,
    sw_version,
    hw_revision,
    test_data_json,
    operator_id,
    shift_code
) VALUES (
    'SN-TEST-20260519-0001',
    'SCU',
    (SELECT order_id FROM manufacturing_orders WHERE order_number = 'PO-2026-TEST-001'),
    NULL,
    (SELECT id FROM equipment_hierarchy WHERE equipment_code = 'SCU-EOL-CTRL-G1-01'),
    (SELECT id FROM equipment_hierarchy WHERE equipment_code = 'SCU-FIX-G1-01'),
    1,
    'PASS',
    42.50,
    '1.2.3',
    'Rev-A',
    JSON_OBJECT('voltage_v', 12.0, 'current_ma', 150),
    'OP-TEST',
    'A'
);
