Use mes_db;
-- 1. Equipment Types
INSERT INTO equipment_types (type_code, description) VALUES
('STATION', 'Stand alone machines or devices on the production line'),
('CONTROLLER', 'The DAQ with PC or PLC unit managing the test logic'),
('FIXTURE', 'The mechanical jig that holds the product during manufacturing or testing'),
('NEST', 'The specific slot or cavity within a fixture for multi-product manufacturing or testing'),
('COBOT', 'Collaborative robot used for handling or visual inspection of the product');

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

-- Inserting Controllers (The Parents)
INSERT INTO equipment (equipment_code, type_id, description) VALUES
('SCU-EOL-CTRL-G1-01', 2, 'Gen 1 EOL Controller 01'),
('SCU-EOL-CTRL-G1-02', 2, 'Gen 1 EOL Controller 02'),
('SCU-EOL-CTRL-G1-03', 2, 'Gen 1 EOL Controller 03'),
('SCU-EOL-CTRL-G2-01', 2, 'Gen 2 EOL Controller 01'),
('SCU-EOL-CTRL-G2-02', 2, 'Gen 2 EOL Controller 02'),
('SCU-EOL-CTRL-G3-01', 2, 'Gen 3 EOL Controller 01'),
('SCU-EOL-CTRL-G3-02', 2, 'Gen 3 EOL Controller 02');

-- Inserting Fixtures (The Children)
INSERT INTO equipment (equipment_code, type_id, description) VALUES
('SCU-FIX-G1-01', 3, 'Gen 1 Fixture 01'),
('SCU-FIX-G1-02', 3, 'Gen 1 Fixture 02'),
('SCU-FIX-G1-03', 3, 'Gen 1 Fixture 03'),
('SCU-FIX-G2-01', 3, 'Gen 2 Fixture 01'),
('SCU-FIX-G2-02', 3, 'Gen 2 Fixture 02'),
('SCU-FIX-G3-01', 3, 'Gen 3 Fixture 01'),
('SCU-FIX-G3-02', 3, 'Gen 3 Fixture 02');

-- G1 Logic: G1 Fixtures -> G1 Controllers only
INSERT INTO equipment_hierarchy (parent_id, child_id)
SELECT p.id, c.id 
FROM equipment p, equipment c 
WHERE p.equipment_code LIKE 'SCU-EOL-CTRL-G1%' 
AND c.equipment_code LIKE 'SCU-FIX-G1%';

-- G2 Logic: G2 Fixtures -> G2 Controllers only (G1 is incompatible)
INSERT INTO equipment_hierarchy (parent_id, child_id)
SELECT p.id, c.id 
FROM equipment p, equipment c 
WHERE p.equipment_code LIKE 'SCU-EOL-CTRL-G2%' 
AND c.equipment_code LIKE 'SCU-FIX-G2%';

-- G3 Logic: G3 Fixtures -> BOTH G2 and G3 Controllers
INSERT INTO equipment_hierarchy (parent_id, child_id)
SELECT p.id, c.id 
FROM equipment p, equipment c 
WHERE (p.equipment_code LIKE 'SCU-EOL-CTRL-G2%' OR p.equipment_code LIKE 'SCU-EOL-CTRL-G3%')
AND c.equipment_code LIKE 'SCU-FIX-G3%';

-- 3. Equipment Compatibility
INSERT INTO equipment_compatibility (controller_type_id, fixture_type_id, product_id) VALUES
(1, 2, 1);