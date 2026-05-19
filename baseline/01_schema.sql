-- 1. Create the database if it doesn't already exist, need to run with root user;
CREATE DATABASE IF NOT EXISTS mes_db;
-- version 4: Full relational model with human-friendly codes and status tracking

Use mes_db;
-- 1. Reference Table for Equipment Types
CREATE TABLE equipment_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    type_code VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'STATION', 'CONTROLLER'
    description TEXT
) ENGINE=InnoDB;

-- 2. Reference Table for Equipment Status
CREATE TABLE equipment_status_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    status_code VARCHAR(20) UNIQUE NOT NULL, -- e.g., 'READY', 'OFFLINE'
    display_name VARCHAR(50) NOT NULL,       -- e.g., 'Ready', 'Offline'
    category ENUM('PRODUCTIVE', 'DOWNTIME', 'NON-PRODUCTIVE') NOT NULL,
    description VARCHAR(255),
    is_selectable BOOLEAN DEFAULT TRUE      
) ENGINE=InnoDB;

-- 3. Main Equipment Hierarchy Table
CREATE TABLE equipment_hierarchy (
    id INT PRIMARY KEY AUTO_INCREMENT,

    -- Human-friendly identifier (e.g., '10001', '20001')
    -- Indexed for high-speed searching and sorting
    equipment_code VARCHAR(20) UNIQUE NOT NULL, 

    name VARCHAR(100) NOT NULL,
    type_id INT NOT NULL, 
    parent_id INT,
    asset_tag VARCHAR(50), -- Physical barcode tag

    -- Status tracking (Defaults to ID 1: 'OFFLINE')
    current_status_id INT NOT NULL DEFAULT 1, 

    status_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Constraints and Relationships
    FOREIGN KEY (type_id) REFERENCES equipment_types(id),
    FOREIGN KEY (current_status_id) REFERENCES equipment_status_types(id),
    FOREIGN KEY (parent_id) REFERENCES equipment_hierarchy(id) ON DELETE SET NULL,

    -- Explicit index for sorting by code if the UNIQUE constraint wasn't enough
    INDEX idx_sorting_code (equipment_code)
) ENGINE=InnoDB;

-- 4. Audit Log for Status Changes (Essential for OEE)
-- CREATE TABLE equipment_status_log (
--     id BIGINT PRIMARY KEY AUTO_INCREMENT,
--     equipment_id INT NOT NULL,
--     from_status_id INT,
--     to_status_id INT NOT NULL,
--     changed_by VARCHAR(50), 
--     change_reason VARCHAR(255),
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

--     FOREIGN KEY (equipment_id) REFERENCES equipment_hierarchy(id),
--     FOREIGN KEY (from_status_id) REFERENCES equipment_status_types(id),
--     FOREIGN KEY (to_status_id) REFERENCES equipment_status_types(id)
-- ) ENGINE=InnoDB;

-- Table 1: Pure Hardware Compatibility (Mechanical/Electrical)
CREATE TABLE equipment_compatibility (
    compatibility_id BIGINT PRIMARY KEY AUTO_INCREMENT,

    -- The "Left Side" of the pair
    controller_type_id INT NOT NULL,

    -- The "Right Side" of the pair
    fixture_type_id INT NOT NULL,

    -- Prevents duplicate rules
    UNIQUE KEY uq_hardware (controller_type_id, fixture_type_id),

    FOREIGN KEY (controller_type_id) REFERENCES equipment_types(id),
    FOREIGN KEY (fixture_type_id) REFERENCES equipment_types(id)
) ENGINE=InnoDB;

-- Optional: Link it to a specific Product (SCU vs PEPS)
-- If NULL, this fixture/controller pair works for ANY product
-- (Product scope is modeled per-row in equipment_product_capability.)

-- Table 2: Process/Product Capability (The Junction)
CREATE TABLE equipment_product_capability (
    compatibility_id BIGINT NOT NULL, -- Links to Table 1
    product_id INT NOT NULL,          -- e.g., SCU, PEPS, BCM

    PRIMARY KEY (compatibility_id, product_id),
    FOREIGN KEY (compatibility_id) REFERENCES equipment_compatibility(compatibility_id)
) ENGINE=InnoDB;

CREATE TABLE manufacturing_orders (
    order_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_number VARCHAR(50) UNIQUE NOT NULL, -- e.g., "PO-2026-SCU-001"
    
    -- Product Definition
    part_number VARCHAR(100) NOT NULL, -- Links to your Product Specs/BOM
        product_type VARCHAR(50) NOT NULL, -- e.g., 'SCU', 'PEPS', 'BCM',
    revision VARCHAR(20), -- Engineering change level (e.g., "Rev B")

    -- Quantity Tracking
    target_quantity INT NOT NULL,       -- How many the customer wants
    completed_quantity INT DEFAULT 0,   -- PASS results
    scrapped_quantity INT DEFAULT 0,    -- FAIL results (for yield calculation)

    -- Scheduling & Performance
    scheduled_start DATETIME,
    actual_start DATETIME,
    actual_completion DATETIME,
    
    -- The "Gatekeeper" Status
    order_status ENUM(
        'PLANNED',   -- Created but not released
        'RELEASED',  -- Ready for the line
        'IN_PROGRESS', 
        'PAUSED',    -- Quality hold or material shortage
        'COMPLETED', 
        'CLOSED'     -- Financed/Invoiced, no more results allowed
    ) DEFAULT 'PLANNED',

    -- Audit Trail
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by VARCHAR(100)
) ENGINE=InnoDB;

-- 5. Manufacturing Result Table
CREATE TABLE manufacturing_result (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    
    -- 1. Traceability: product under test related 
    serial_number VARCHAR(100) NOT NULL, -- The barcode of the PCB/Product
    product_type VARCHAR(50),            -- 'SCU', 'PEPS', etc.
    mo_id BIGINT NOT NULL,                  -- Link to the Manufacturing Order
    
    -- 2. The "Equipment Stack" (Snapshot of what was used)
    -- We link to IDs, but you might store the Code as well for historical speed
    station_id INT,                      -- For integrated machines, nullable for stations with combination structure: EOL=Controller+Fixture
    controller_id INT NOT NULL,          -- The 'Root' for EOL
    fixture_id INT NOT NULL,             -- The fixture which work together with 'Root' equipment like EOL Controller
    nest_number INT,                     -- Which specific slot was used, also called 'Channel'
    
    -- 3. The Outcome
    overall_result ENUM('PASS', 'FAIL', 'ABORTED') NOT NULL,
    cycle_time_seconds DECIMAL(10, 2),   -- Performance metric for OEE
    
    sw_version VARCHAR(50) NULL, -- Only filled by CAN/LIN-enabled stations
    hw_revision VARCHAR(50) NULL,

    -- 4. Data Links
    test_data_json JSON,                 -- Store raw measurements (Voltage, Current, etc.)
    error_code VARCHAR(50),              -- Reason if FAIL, mostly for failure category like CAN/LIN failure or function failure.
    
    -- 5. Labor/Shift Tracking
    operator_id VARCHAR(50),     -- Who was at the station?
    shift_code VARCHAR(20),      -- Shift A/B/C for OEE grouping

    -- 6. Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indices for high-speed reporting (Traceability)
    INDEX idx_serial (serial_number),
    INDEX idx_product_mo (product_type, mo_id),
    
    -- Foreign Keys
    FOREIGN KEY (mo_id) REFERENCES manufacturing_orders(order_id),
    FOREIGN KEY (controller_id) REFERENCES equipment_hierarchy(id),
    FOREIGN KEY (fixture_id) REFERENCES equipment_hierarchy(id)
) ENGINE=InnoDB;

-- The products Master Table: A place to store all product definitions
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    -- The Part Number, is the unique identifier for the product, this is for intenal use of PLC/EOL/Kafka,not to customers
    product_code VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'SCU-1234567890'
    -- The display name for the product, this is for displaying to internal engineers or operators
    product_name VARCHAR(100) NOT NULL, -- e.g., 'SCU-Ford-CD4-RevB'
    product_description TEXT,           -- e.g., 'SCU-Ford-CD4-RevB is a controller module for Ford CD4'    
    -- The broader family grouping
    product_type VARCHAR(50) NOT NULL, -- e.g., 'SCU', 'PEPS', 'BCM'
    product_revision VARCHAR(20), -- Engineering change level (e.g., "Rev B")
    product_status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;
-- CREATE TABLE products (
--     product_id INT PRIMARY KEY AUTO_INCREMENT,
    
--     -- The "Human Readable" Part Number or Variant Code
--     product_code VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'SCU-CD4', 'SCU-CD391'
    
--     -- The broader family grouping
--     product_family VARCHAR(50) NOT NULL,      -- e.g., 'SCU', 'PEPS', 'BCM'
    
--     display_name VARCHAR(100) NOT NULL,       -- e.g., 'SCU CD4 Controller Module'
--     revision VARCHAR(10) DEFAULT 'A',         -- Engineering changes
    
--     is_active BOOLEAN DEFAULT TRUE,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- ) ENGINE=InnoDB;