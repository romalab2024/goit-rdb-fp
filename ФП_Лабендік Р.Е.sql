-- ============================================
-- FINAL PROJECT: Pandemic Data Analysis
-- ============================================

-- 1. Створення схеми
CREATE SCHEMA IF NOT EXISTS pandemic;
USE pandemic;

-- ============================================
-- 2. (ДАНІ ІМПОРТУЮТЬСЯ ЧЕРЕЗ IMPORT WIZARD)
-- Таблиця: infectious_cases
-- ============================================

-- Перевірка кількості рядків
SELECT COUNT(*) AS total_rows
FROM infectious_cases;

-- ============================================
-- 3. НОРМАЛІЗАЦІЯ (3NF)
-- ============================================

-- 3.1 Таблиця довідника (Entity + Code)
DROP TABLE IF EXISTS entities;

CREATE TABLE entities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    Entity VARCHAR(255) NOT NULL,
    Code VARCHAR(20),
    UNIQUE (Entity, Code)
);

-- Заповнення довідника
INSERT INTO entities (Entity, Code)
SELECT DISTINCT Entity, Code
FROM infectious_cases;

-- Перевірка
SELECT COUNT(*) AS entities_count FROM entities;

-- ============================================

-- 3.2 Основна таблиця (нормалізована)
DROP TABLE IF EXISTS infectious_cases_normalized;

CREATE TABLE infectious_cases_normalized (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity_id INT NOT NULL,
    Year INT NOT NULL,

    Number_yaws TEXT,
    polio_cases TEXT,
    cases_guinea_worm TEXT,
    Number_rabies TEXT,
    Number_malaria TEXT,
    Number_hiv TEXT,
    Number_tuberculosis TEXT,
    Number_smallpox TEXT,
    Number_cholera_cases TEXT,

    FOREIGN KEY (entity_id) REFERENCES entities(id)
);

-- Заповнення нормалізованої таблиці
INSERT INTO infectious_cases_normalized (
    entity_id, Year,
    Number_yaws, polio_cases, cases_guinea_worm,
    Number_rabies, Number_malaria, Number_hiv,
    Number_tuberculosis, Number_smallpox, Number_cholera_cases
)
SELECT
    e.id,
    ic.Year,
    ic.Number_yaws,
    ic.polio_cases,
    ic.cases_guinea_worm,
    ic.Number_rabies,
    ic.Number_malaria,
    ic.Number_hiv,
    ic.Number_tuberculosis,
    ic.Number_smallpox,
    ic.Number_cholera_cases
FROM infectious_cases ic
JOIN entities e
ON ic.Entity = e.Entity AND ic.Code = e.Code;

-- Перевірка
SELECT COUNT(*) AS normalized_count
FROM infectious_cases_normalized;

-- ============================================
-- 4. АНАЛІЗ ДАНИХ
-- ============================================

SELECT
    e.Entity,
    e.Code,

    AVG(CAST(NULLIF(icn.Number_rabies, '') AS DECIMAL(20,2))) AS avg_rabies,
    MIN(CAST(NULLIF(icn.Number_rabies, '') AS DECIMAL(20,2))) AS min_rabies,
    MAX(CAST(NULLIF(icn.Number_rabies, '') AS DECIMAL(20,2))) AS max_rabies,
    SUM(CAST(NULLIF(icn.Number_rabies, '') AS DECIMAL(20,2))) AS sum_rabies

FROM infectious_cases_normalized icn
JOIN entities e ON icn.entity_id = e.id

WHERE NULLIF(icn.Number_rabies, '') IS NOT NULL

GROUP BY e.Entity, e.Code

ORDER BY avg_rabies DESC

LIMIT 10;

-- ============================================
-- 5. РОБОТА З ДАТАМИ
-- ============================================

ALTER TABLE infectious_cases_normalized
ADD COLUMN year_start_date DATE,
ADD COLUMN current_date_value DATE,
ADD COLUMN year_difference INT;

SET SQL_SAFE_UPDATES = 0;

UPDATE infectious_cases_normalized
SET 
    year_start_date = STR_TO_DATE(CONCAT(`Year`, '-01-01'), '%Y-%m-%d'),
    current_date_value = CURDATE(),
    year_difference = TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(CONCAT(`Year`, '-01-01'), '%Y-%m-%d'),
        CURDATE()
    );

SET SQL_SAFE_UPDATES = 1;

SELECT 
    id,
    `Year`,
    year_start_date,
    current_date_value,
    year_difference
FROM infectious_cases_normalized
LIMIT 10;

-- ============================================
-- 6. КОРИСТУВАЦЬКА ФУНКЦІЯ (YEAR DIFFERENCE)
-- ============================================

DROP FUNCTION IF EXISTS get_year_difference;

DELIMITER //

CREATE FUNCTION get_year_difference(input_year INT)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(CONCAT(input_year, '-01-01'), '%Y-%m-%d'),
        CURDATE()
    );
END //

DELIMITER ;

-- Використання функції
SELECT
    id,
    `Year`,
    get_year_difference(`Year`) AS year_difference
FROM infectious_cases_normalized
LIMIT 10;

-- ============================================
-- 7. BONUS ФУНКЦІЯ (СЕРЕДНЄ ЗА ПЕРІОД)
-- ============================================

DROP FUNCTION IF EXISTS calc_cases_per_period;

DELIMITER //

CREATE FUNCTION calc_cases_per_period(
    yearly_cases DECIMAL(20,2),
    divisor INT
)
RETURNS DECIMAL(20,2)
DETERMINISTIC
BEGIN
    IF yearly_cases IS NULL OR divisor IS NULL OR divisor = 0 THEN
        RETURN NULL;
    END IF;

    RETURN yearly_cases / divisor;
END //

DELIMITER ;

-- Використання (місяць)
SELECT
    id,
    `Year`,
    calc_cases_per_period(
        CAST(NULLIF(Number_rabies, '') AS DECIMAL(20,2)),
        12
    ) AS avg_per_month
FROM infectious_cases_normalized
WHERE NULLIF(Number_rabies, '') IS NOT NULL
LIMIT 10;

-- Використання (квартал)
SELECT
    id,
    `Year`,
    calc_cases_per_period(
        CAST(NULLIF(Number_rabies, '') AS DECIMAL(20,2)),
        4
    ) AS avg_per_quarter
FROM infectious_cases_normalized
WHERE NULLIF(Number_rabies, '') IS NOT NULL
LIMIT 10;

-- Використання (півріччя)
SELECT
    id,
    `Year`,
    calc_cases_per_period(
        CAST(NULLIF(Number_rabies, '') AS DECIMAL(20,2)),
        2
    ) AS avg_per_half_year
FROM infectious_cases_normalized
WHERE NULLIF(Number_rabies, '') IS NOT NULL
LIMIT 10;
