Use mes_db;
-- 1. Equipment Types
INSERT INTO equipment_types (type_code, description) VALUES
('STATION', 'Stand alone machines or devices on the production line'),
('CONTROLLER', 'The DAQ with PC or PLC unit managing the test logic'),
('FIXTURE', 'The mechanical jig that holds the product during manufacturing or testing'),
('NEST', 'The specific slot or cavity within a fixture for multi-product manufacturing or testing'),
('COBOT', 'Collaborative robot used for handling or visual inspection of the product'),
('CONTROLLER_G1', 'Gen 1 EOL controller hardware generation'),
('CONTROLLER_G2', 'Gen 2 EOL controller hardware generation'),
('CONTROLLER_G3', 'Gen 3 EOL controller hardware generation'),
('FIXTURE_G1', 'Gen 1 fixture hardware generation'),
('FIXTURE_G2', 'Gen 2 fixture hardware generation'),
('FIXTURE_G3', 'Gen 3 fixture hardware generation');

-- 2. Equipment Status Types
INSERT INTO equipment_status_types (status_code, display_name, category, description, is_selectable) VALUES
-- PRODUCTIVE: Machine is available and adding value
('READY', 'Ready', 'PRODUCTIVE', 'Equipment is idle but capable of production', TRUE),
('RUNNING', 'Running', 'PRODUCTIVE', 'Equipment is actively executing a process', FALSE),

-- DOWNTIME: Unplanned losses that hurt Availability/OEE
('REPAIR', 'Repair', 'DOWNTIME', 'Unplanned mechanical or software failure repair', TRUE),
('CALIBRATION', 'Calibration', 'DOWNTIME', 'Required calibration preventing production', TRUE),
('BLOCKED', 'Blocked', 'DOWNTIME', 'Equipment is functional but downstream is full', FALSE),

-- NON-PRODUCTIVE: Scheduled/Neutral time (Excluded from OEE)
('MAINTENANCE', 'Maintenance', 'NON-PRODUCTIVE', 'Scheduled preventative maintenance', TRUE),
('OFFLINE', 'Offline', 'NON-PRODUCTIVE', 'Equipment is powered down or shift has ended', TRUE);

-- INSERT INTO equipment_status_types (status_code, display_name, category, description, is_selectable) VALUES
-- ('READY', 'Ready', 'PRODUCTIVE', 'The equipment is ready to be used', TRUE),
-- ('OFFLINE', 'Offline', 'DOWNTIME', 'The equipment is offline', TRUE),
-- ('MAINTENANCE', 'Maintenance', 'DOWNTIME', 'The equipment is under maintenance', TRUE),
-- ('CALIBRATION', 'Calibration', 'DOWNTIME', 'The equipment is under calibration', TRUE),
-- ('REPAIR', 'Repair', 'DOWNTIME', 'The equipment is under repair', TRUE);
-- ('BLOCKED', 'Blocked', 'DOWNTIME', 'The equipment is blocked', FALSE);

-- INSERT INTO equipment_status_types (status_code, display_name, category, is_selectable) VALUES 
-- ('OFFLINE', 'Offline', 'NON-PRODUCTIVE', TRUE),
-- ('READY', 'Ready', 'PRODUCTIVE', TRUE),
-- ('RUNNING', 'Running', 'PRODUCTIVE', FALSE), -- Usually system-set, not manual
-- ('DOWN', 'Down (General)', 'DOWNTIME', TRUE),
-- ('MAINTENANCE', 'Maintenance', 'NON-PRODUCTIVE', TRUE),
-- ('BLOCKED', 'Blocked', 'DOWNTIME', FALSE);

-- 3. Products
INSERT INTO products (product_code, product_name, product_description, product_type, product_revision) VALUES
('SCU-CD4', 'SCU Ford CD4', 'CD4 SCU controller module for Ford', 'SCU', 'A'),
('SCU-CD391', 'SCU Ford CD391', 'CD391 SCU controller module for Ford', 'SCU', 'A'),
('SCU-L318', 'SCU Ford L318', 'L318 SCU controller module for Ford', 'SCU', 'A'),
('SCU-L538', 'SCU Ford L538', 'L538 SCU controller module for Ford', 'SCU', 'A'),
('SCU-U540', 'SCU Ford U540', 'U540 SCU controller module for Ford', 'SCU', 'A'),
('SCU-P552', 'SCU Ford P552', 'P552 SCU controller module for Ford', 'SCU', 'A'),
('PEPS-CT5', 'PEPS GM CT5', 'CT5 PEPS module for GM', 'PEPS', 'A');

-- 4. Equipment Compatibility
-- G1 Logic: G1 Fixtures -> G1 Controllers only
INSERT INTO equipment_compatibility (controller_type_id, fixture_type_id) VALUES
((SELECT id FROM equipment_types WHERE type_code = 'CONTROLLER_G1'),
 (SELECT id FROM equipment_types WHERE type_code = 'FIXTURE_G1'));

-- G2 Logic: G2 Fixtures -> G2 Controllers only (G1 is incompatible)
INSERT INTO equipment_compatibility (controller_type_id, fixture_type_id) VALUES
((SELECT id FROM equipment_types WHERE type_code = 'CONTROLLER_G2'),
 (SELECT id FROM equipment_types WHERE type_code = 'FIXTURE_G2'));

-- G3 Logic: G3 Fixtures -> BOTH G2 and G3 Controllers
INSERT INTO equipment_compatibility (controller_type_id, fixture_type_id) VALUES
((SELECT id FROM equipment_types WHERE type_code = 'CONTROLLER_G2'),
 (SELECT id FROM equipment_types WHERE type_code = 'FIXTURE_G3')),
((SELECT id FROM equipment_types WHERE type_code = 'CONTROLLER_G3'),
 (SELECT id FROM equipment_types WHERE type_code = 'FIXTURE_G3'));

-- 5. Equipment Hierarchy
-- Inserting Controllers
INSERT INTO equipment_hierarchy (equipment_code, name, type_id) VALUES
('SCU-EOL-CTRL-G1-01', 'Gen 1 EOL Controller 01', (SELECT id FROM equipment_types WHERE type_code = 'CONTROLLER_G1')),
('SCU-EOL-CTRL-G1-02', 'Gen 1 EOL Controller 02', (SELECT id FROM equipment_types WHERE type_code = 'CONTROLLER_G1')),
('SCU-EOL-CTRL-G1-03', 'Gen 1 EOL Controller 03', (SELECT id FROM equipment_types WHERE type_code = 'CONTROLLER_G1')),
('SCU-EOL-CTRL-G2-01', 'Gen 2 EOL Controller 01', (SELECT id FROM equipment_types WHERE type_code = 'CONTROLLER_G2')),
('SCU-EOL-CTRL-G2-02', 'Gen 2 EOL Controller 02', (SELECT id FROM equipment_types WHERE type_code = 'CONTROLLER_G2')),
('SCU-EOL-CTRL-G3-01', 'Gen 3 EOL Controller 01', (SELECT id FROM equipment_types WHERE type_code = 'CONTROLLER_G3')),
('SCU-EOL-CTRL-G3-02', 'Gen 3 EOL Controller 02', (SELECT id FROM equipment_types WHERE type_code = 'CONTROLLER_G3'));

-- Inserting Fixtures
INSERT INTO equipment_hierarchy (equipment_code, name, type_id) VALUES
('SCU-FIX-G1-01', 'Gen 1 Fixture 01', (SELECT id FROM equipment_types WHERE type_code = 'FIXTURE_G1')),
('SCU-FIX-G1-02', 'Gen 1 Fixture 02', (SELECT id FROM equipment_types WHERE type_code = 'FIXTURE_G1')),
('SCU-FIX-G1-03', 'Gen 1 Fixture 03', (SELECT id FROM equipment_types WHERE type_code = 'FIXTURE_G1')),
('SCU-FIX-G2-01', 'Gen 2 Fixture 01', (SELECT id FROM equipment_types WHERE type_code = 'FIXTURE_G2')),
('SCU-FIX-G2-02', 'Gen 2 Fixture 02', (SELECT id FROM equipment_types WHERE type_code = 'FIXTURE_G2')),
('SCU-FIX-G3-01', 'Gen 3 Fixture 01', (SELECT id FROM equipment_types WHERE type_code = 'FIXTURE_G3')),
('SCU-FIX-G3-02', 'Gen 3 Fixture 02', (SELECT id FROM equipment_types WHERE type_code = 'FIXTURE_G3'));

-- 6. Equipment Product Capability (fixture generation -> products)
-- G1 fixture: CD4, CD391
INSERT INTO equipment_product_capability (compatibility_id, product_id)
SELECT ec.compatibility_id, p.product_id
FROM equipment_compatibility ec
JOIN equipment_types ft ON ec.fixture_type_id = ft.id AND ft.type_code = 'FIXTURE_G1'
JOIN products p ON p.product_code IN ('SCU-CD4', 'SCU-CD391');

-- G2 fixture: L318, L538
INSERT INTO equipment_product_capability (compatibility_id, product_id)
SELECT ec.compatibility_id, p.product_id
FROM equipment_compatibility ec
JOIN equipment_types ft ON ec.fixture_type_id = ft.id AND ft.type_code = 'FIXTURE_G2'
JOIN products p ON p.product_code IN ('SCU-L318', 'SCU-L538');

-- G3 fixture: L318, L538, U540, P552 (G2+G3 and G3+G3 controller pairings)
INSERT INTO equipment_product_capability (compatibility_id, product_id)
SELECT ec.compatibility_id, p.product_id
FROM equipment_compatibility ec
JOIN equipment_types ft ON ec.fixture_type_id = ft.id AND ft.type_code = 'FIXTURE_G3'
JOIN products p ON p.product_code IN ('SCU-L318', 'SCU-L538', 'SCU-U540', 'SCU-P552');
