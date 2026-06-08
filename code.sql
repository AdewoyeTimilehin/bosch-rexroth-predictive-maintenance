

CREATE TABLE equipment_master(
   Machine_id TEXT,
   installation_date DATE,
   total_operating_hours INT,
   fluid_type TEXT,
   last_filter_change_date DATE,
   maintenance_priority TEXT
);

CREATE TABLE failure_labels(
	failure_event_id TEXT,
	machine_id TEXT,
	failure_timestamp DATE,
	failure_mode TEXT,
	degradation_start_timestamp DATE,
	repair_cost_usd INT,
	downtime_hours NUMERIC(10, 2)
);

CREATE TABLE maintenance_log(
    maintenance_id TEXT,
	machine_id TEXT,
	action_timestamp TIMESTAMP,
	action_type TEXT,
	component_replaced TEXT,
	technician_id TEXT,
	cost_usd INT
);

CREATE TABLE sensor_telemetry(
    timestamp TIMESTAMP,
	machine_id TEXT,
	pressure_bar NUMERIC(10, 2),
	temp_celsius NUMERIC(10, 2),
	flow_lpm NUMERIC(10, 2),
	vibration_x_g NUMERIC(12, 7),
	vibration_y_g NUMERIC(12, 7),
	pump_rpm NUMERIC(10, 2),
	is_anomaly INT,
	failure_mode TEXT,
	rul_hours NUMERIC(10,2),
	is_sensor_dropout INT,
	shift TEXT,
	day_of_week INT
);

SELECT *
FROM equipment_master;

SELECT *
FROM failure_labels;

SELECT *
FROM maintenance_log;

SELECT *
FROM sensor_telemetry;

SELECT DISTINCT failure_mode
FROM sensor_telemetry
WHERE failure_mode IS NOT NULL
GROUP BY failure_mode;

SELECT failure_mode
FROM sensor_telemetry
WHERE failure_mode IS NULL;

SELECT vibration_x_g
FROM sensor_telemetry
WHERE vibration_x_g IS NULL;

SELECT vibration_y_g
FROM sensor_telemetry
WHERE vibration_y_g IS NULL;

SELECT timestamp
FROM sensor_telemetry
WHERE timestamp IS NULL;

SELECT is_sensor_dropout
FROM sensor_telemetry
WHERE is_sensor_dropout IS NULL;

SELECT
    is_sensor_dropout,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE pressure_bar IS NULL) AS null_pressure,
    COUNT(*) FILTER (WHERE temp_celsius IS NULL) AS null_temp,
    COUNT(*) FILTER (WHERE flow_lpm IS NULL)     AS null_flow
FROM sensor_telemetry
GROUP BY is_sensor_dropout;

SELECT
    COUNT(*)                                            AS total_rows,
    COUNT(*) FILTER (WHERE pressure_bar IS NULL)        AS null_pressure,
    COUNT(*) FILTER (WHERE temp_celsius IS NULL)        AS null_temp,
    COUNT(*) FILTER (WHERE flow_lpm IS NULL)            AS null_flow,
    COUNT(*) FILTER (WHERE vibration_x_g IS NULL)       AS null_vib_x,
    COUNT(*) FILTER (WHERE vibration_y_g IS NULL)       AS null_vib_y,
    COUNT(*) FILTER (WHERE pump_rpm IS NULL)            AS null_pump_rpm,
    COUNT(*) FILTER (WHERE is_anomaly IS NULL)          AS null_is_anomaly,
    COUNT(*) FILTER (WHERE failure_mode IS NULL)        AS null_failure_mode,
    COUNT(*) FILTER (WHERE rul_hours IS NULL)           AS null_rul_hours,
    COUNT(*) FILTER (WHERE is_sensor_dropout IS NULL)   AS null_is_sensor_dropout,
    COUNT(*) FILTER (WHERE shift IS NULL)               AS null_shift,
    COUNT(*) FILTER (WHERE day_of_week IS NULL)         AS null_day_of_week
FROM sensor_telemetry;

SELECT
    COUNT(*) AS rows_where_all_6_are_null
FROM sensor_telemetry
WHERE
    pressure_bar    IS NULL
    AND temp_celsius    IS NULL
    AND flow_lpm        IS NULL
    AND vibration_x_g   IS NULL
    AND vibration_y_g   IS NULL
    AND pump_rpm        IS NULL;

DELETE FROM sensor_telemetry
WHERE is_sensor_dropout = 1;

SELECT COUNT(*) AS total_rows
FROM sensor_telemetry;

UPDATE sensor_telemetry
SET failure_mode = 'Nor'
WHERE failure_mode IS NULL;

-- Equipment Master
ALTER TABLE equipment_master
ADD PRIMARY KEY (machine_id);

-- Failure Labels
ALTER TABLE failure_labels
ADD PRIMARY KEY (failure_event_id);

-- Maintenance Log
ALTER TABLE maintenance_log
ADD PRIMARY KEY (maintenance_id);

-- Sensor Telemetry
ALTER TABLE sensor_telemetry
ADD PRIMARY KEY (timestamp, machine_id);

SELECT 
    timestamp, 
    machine_id, 
    COUNT(*) AS occurrences
FROM sensor_telemetry
GROUP BY timestamp, machine_id
HAVING COUNT(*) > 1;

-- Sensor Telemetry references Equipment Master
ALTER TABLE sensor_telemetry
ADD CONSTRAINT fk_sensor_machine
FOREIGN KEY (machine_id)
REFERENCES equipment_master (machine_id);

-- Failure Labels references Equipment Master
ALTER TABLE failure_labels
ADD CONSTRAINT fk_failure_machine
FOREIGN KEY (machine_id)
REFERENCES equipment_master (machine_id);

-- Maintenance Log references Equipment Master
ALTER TABLE maintenance_log
ADD CONSTRAINT fk_maintenance_machine
FOREIGN KEY (machine_id)
REFERENCES equipment_master (machine_id);

SELECT
    tc.table_name            AS child_table,
    kcu.column_name          AS foreign_key,
    ccu.table_name           AS parent_table,
    ccu.column_name          AS primary_key,
    tc.constraint_name       AS constraint_name
FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
WHERE
    tc.constraint_type = 'FOREIGN KEY';

---Failure mode distribution
SELECT
    failure_mode,
    COUNT(*)                                    AS total_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) 
    OVER(), 2)                                  AS percentage
FROM sensor_telemetry
GROUP BY failure_mode
ORDER BY total_count DESC;

---Sensor reading statistics
SELECT
    ROUND(AVG(pressure_bar), 2)         AS avg_pressure,
    ROUND(MIN(pressure_bar), 2)         AS min_pressure,
    ROUND(MAX(pressure_bar), 2)         AS max_pressure,

    ROUND(AVG(temp_celsius), 2)         AS avg_temp,
    ROUND(MIN(temp_celsius), 2)         AS min_temp,
    ROUND(MAX(temp_celsius), 2)         AS max_temp,

    ROUND(AVG(flow_lpm), 2)             AS avg_flow,
    ROUND(MIN(flow_lpm), 2)             AS min_flow,
    ROUND(MAX(flow_lpm), 2)             AS max_flow,

    ROUND(AVG(vibration_x_g), 2)        AS avg_vib_x,
    ROUND(MIN(vibration_x_g), 2)        AS min_vib_x,
    ROUND(MAX(vibration_x_g), 2)        AS max_vib_x,

    ROUND(AVG(vibration_y_g), 2)        AS avg_vib_y,
    ROUND(MIN(vibration_y_g), 2)        AS min_vib_y,
    ROUND(MAX(vibration_y_g), 2)        AS max_vib_y,

    ROUND(AVG(pump_rpm), 2)             AS avg_pump_rpm,
    ROUND(MIN(pump_rpm), 2)             AS min_pump_rpm,
    ROUND(MAX(pump_rpm), 2)             AS max_pump_rpm

FROM sensor_telemetry;

---Anomaly Rate Per Machine
SELECT
    machine_id,
    COUNT(*)                                        AS total_readings,
    SUM(is_anomaly)                                 AS total_anomalies,
    ROUND(SUM(is_anomaly) * 100.0 / COUNT(*), 2)   AS anomaly_rate_percentage
FROM sensor_telemetry
GROUP BY machine_id
ORDER BY anomaly_rate_percentage DESC;

---RUL Distribution Per Machine
SELECT
    machine_id,
    ROUND(AVG(rul_hours), 2)            AS avg_rul,
    ROUND(MIN(rul_hours), 2)            AS min_rul,
    ROUND(MAX(rul_hours), 2)            AS max_rul
FROM sensor_telemetry
GROUP BY machine_id
ORDER BY avg_rul ASC;

---Maintenance Frequency and Cost Per Machine 
SELECT
    machine_id,
    COUNT(*)                            AS total_maintenance,
    ROUND(SUM(cost_usd), 2)             AS total_cost,
    ROUND(AVG(cost_usd), 2)             AS avg_cost,
    ROUND(MIN(cost_usd), 2)             AS min_cost,
    ROUND(MAX(cost_usd), 2)             AS max_cost
FROM maintenance_log
GROUP BY machine_id
ORDER BY total_cost DESC;

---Repair cost and downtime per failure mode 
SELECT
    failure_mode,
    COUNT(*)                                AS total_failures,
    ROUND(SUM(repair_cost_usd), 2)          AS total_repair_cost,
    ROUND(AVG(repair_cost_usd), 2)          AS avg_repair_cost,
    ROUND(SUM(downtime_hours), 2)           AS total_downtime_hours,
    ROUND(AVG(downtime_hours), 2)           AS avg_downtime_hours
FROM failure_labels
GROUP BY failure_mode
ORDER BY total_repair_cost DESC;

--- Top 5 Machines with Highest Failures
SELECT
    machine_id,
    COUNT(*)                                AS total_failures,
    ROUND(SUM(repair_cost_usd), 2)          AS total_repair_cost,
    ROUND(SUM(downtime_hours), 2)           AS total_downtime_hours
FROM failure_labels
GROUP BY machine_id
ORDER BY total_failures DESC
LIMIT 5;

---Classify machines into risk categories based on RUL 
SELECT
    machine_id,
    ROUND(AVG(rul_hours), 2)            AS avg_rul,
    ROUND(AVG(is_anomaly) * 100, 2)     AS anomaly_rate_percentage,
    CASE
        WHEN AVG(rul_hours) < 200 THEN 'High Risk'
        WHEN AVG(rul_hours) BETWEEN 200 AND 350 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END                                 AS risk_category
FROM sensor_telemetry
GROUP BY machine_id
ORDER BY avg_rul ASC;

---Reactive vs Proactive Maintenance Ratio
SELECT DISTINCT action_type
FROM maintenance_log;

SELECT
    action_type,
    COUNT(*)                                        AS total_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) 
    OVER(), 2)                                      AS percentage,
    CASE
        WHEN action_type IN ('Preventive', 'Inspection') 
            THEN 'Proactive'
        WHEN action_type = 'Reactive' 
            THEN 'Reactive'
    END                                             AS category
FROM maintenance_log
GROUP BY action_type
ORDER BY total_count DESC;

---Fluid type correlation with RUL
SELECT 
    machine_id,
    fluid_type
FROM equipment_master;

SELECT
    em.fluid_type,
    COUNT(DISTINCT em.machine_id)               AS total_machines,
    ROUND(AVG(st.rul_hours), 2)                 AS avg_rul,
    ROUND(MIN(st.rul_hours), 2)                 AS min_rul,
    ROUND(MAX(st.rul_hours), 2)                 AS max_rul,
    ROUND(AVG(st.is_anomaly) * 100, 2)          AS avg_anomaly_rate,
    ROUND(AVG(st.pressure_bar), 2)              AS avg_pressure,
    ROUND(AVG(st.temp_celsius), 2)              AS avg_temp,
    ROUND(AVG(st.vibration_x_g), 2)            AS avg_vibration
FROM equipment_master em
LEFT JOIN sensor_telemetry st
    ON em.machine_id = st.machine_id
GROUP BY em.fluid_type
ORDER BY avg_rul DESC;

---Sensor Threshold Analysis for Pump Wear
SELECT
    failure_mode,
    ROUND(AVG(pressure_bar), 2)         AS avg_pressure,
    ROUND(MIN(pressure_bar), 2)         AS min_pressure,
    ROUND(MAX(pressure_bar), 2)         AS max_pressure,
    ROUND(AVG(vibration_x_g), 2)        AS avg_vibration_x,
    ROUND(MIN(vibration_x_g), 2)        AS min_vibration_x,
    ROUND(MAX(vibration_x_g), 2)        AS max_vibration_x,
    ROUND(AVG(temp_celsius), 2)         AS avg_temp,
    ROUND(MIN(temp_celsius), 2)         AS min_temp,
    ROUND(MAX(temp_celsius), 2)         AS max_temp,
    ROUND(AVG(flow_lpm), 2)             AS avg_flow,
    ROUND(MIN(flow_lpm), 2)             AS min_flow,
    ROUND(MAX(flow_lpm), 2)             AS max_flow
FROM sensor_telemetry
GROUP BY failure_mode
ORDER BY failure_mode;

---Maintenance action effectiveness
SELECT
    ml.action_type,
    ml.component_replaced,
    COUNT(*)                                AS total_actions,
    ROUND(AVG(st.rul_hours), 2)             AS avg_rul_after_maintenance,
    ROUND(MIN(st.rul_hours), 2)             AS min_rul,
    ROUND(MAX(st.rul_hours), 2)             AS max_rul,
    ROUND(AVG(ml.cost_usd), 2)              AS avg_maintenance_cost
FROM maintenance_log ml
LEFT JOIN sensor_telemetry st
    ON ml.machine_id = st.machine_id
    AND st.timestamp > ml.action_timestamp
GROUP BY ml.action_type, ml.component_replaced
ORDER BY avg_rul_after_maintenance DESC;

---Operating Hours vs Failure Frequency
SELECT
    em.machine_id,
    em.total_operating_hours,
    em.maintenance_priority,
    COUNT(fl.failure_mode)                          AS total_failures,
    ROUND(AVG(st.rul_hours), 2)                     AS avg_rul,
    ROUND(AVG(st.is_anomaly) * 100, 2)              AS anomaly_rate,
    ROUND(SUM(fl.repair_cost_usd), 2)               AS total_repair_cost,
    ROUND(SUM(fl.downtime_hours), 2)                AS total_downtime_hours
FROM equipment_master em
LEFT JOIN sensor_telemetry st
    ON em.machine_id = st.machine_id
LEFT JOIN failure_labels fl
    ON em.machine_id = fl.machine_id
GROUP BY em.machine_id, em.total_operating_hours, em.maintenance_priority
ORDER BY em.total_operating_hours DESC;

SELECT
    em.machine_id,
    em.total_operating_hours,
    em.maintenance_priority,
    COALESCE(fl.total_failures, 0)          AS total_failures,
    st.avg_rul,
    st.anomaly_rate,
    COALESCE(fl.total_repair_cost, 0)       AS total_repair_cost,
    COALESCE(fl.total_downtime_hours, 0)    AS total_downtime_hours
FROM equipment_master em
LEFT JOIN (
    SELECT
        machine_id,
        ROUND(AVG(rul_hours), 2)            AS avg_rul,
        ROUND(AVG(is_anomaly) * 100, 2)     AS anomaly_rate
    FROM sensor_telemetry
    GROUP BY machine_id
) st ON em.machine_id = st.machine_id
LEFT JOIN (
    SELECT
        machine_id,
        COUNT(*)                            AS total_failures,
        ROUND(SUM(repair_cost_usd), 2)      AS total_repair_cost,
        ROUND(SUM(downtime_hours), 2)       AS total_downtime_hours
    FROM failure_labels
    GROUP BY machine_id
) fl ON em.machine_id = fl.machine_id
ORDER BY em.total_operating_hours DESC;

SELECT COUNT(*) AS total_rows
FROM equipment_master em
LEFT JOIN sensor_telemetry st
    ON em.machine_id = st.machine_id
LEFT JOIN failure_labels fl
    ON em.machine_id = fl.machine_id
LEFT JOIN maintenance_log ml
    ON em.machine_id = ml.machine_id;

--- Craeting view for Equipment master
CREATE VIEW vw_equipment_master AS
SELECT
    machine_id,
    installation_date,
    total_operating_hours,
    fluid_type,
    maintenance_priority
FROM equipment_master;

---Creating view for sensor telemetry
CREATE VIEW vw_sensor_telemetry AS
SELECT
    machine_id,
    timestamp,
    pressure_bar,
    temp_celsius,
    flow_lpm,
    vibration_x_g,
    vibration_y_g,
    pump_rpm,
    is_anomaly,
    failure_mode,
    rul_hours,
    shift
FROM sensor_telemetry;

---Creating view for failure labels
CREATE VIEW vw_failure_labels AS
SELECT
    machine_id,
    failure_timestamp,
    failure_mode,
    degradation_start_timestamp,
    repair_cost_usd,
    downtime_hours
FROM failure_labels;

---Creating views for maintenance log
CREATE VIEW vw_maintenance_log AS
SELECT
    machine_id,
    action_timestamp,
    action_type,
    component_replaced,
    cost_usd AS maintenance_cost_usd
FROM maintenance_log;

SELECT * FROM vw_equipment_master LIMIT 5;

SELECT * FROM vw_sensor_telemetry LIMIT 5;

SELECT * FROM vw_failure_labels LIMIT 5;

SELECT * FROM vw_maintenance_log LIMIT 5;

SELECT 'vw_equipment_master'   AS view_name, COUNT(*) AS total_rows FROM vw_equipment_master
UNION ALL
SELECT 'vw_sensor_telemetry'   AS view_name, COUNT(*) AS total_rows FROM vw_sensor_telemetry
UNION ALL
SELECT 'vw_failure_labels'     AS view_name, COUNT(*) AS total_rows FROM vw_failure_labels
UNION ALL
SELECT 'vw_maintenance_log'    AS view_name, COUNT(*) AS total_rows FROM vw_maintenance_log;