CREATE DATABASE football_analysis;
USE football_analysis;

CREATE TABLE raw_results (
    match_date DATE,
    home_team VARCHAR(100),
    away_team VARCHAR(100),
    home_score INT,
    away_score INT,
    tournament VARCHAR(150),
    city VARCHAR(100),
    country VARCHAR(100),
    neutral VARCHAR(10)
);

-- Row Count
SELECT COUNT(*) FROM raw_results;

-- Date Range
SELECT MIN(match_date), MAX(match_date)
FROM raw_results;

-- Null Check
SELECT
    SUM(match_date IS NULL),
    SUM(home_team IS NULL),
    SUM(away_team IS NULL),
    SUM(home_score IS NULL),
    SUM(away_score IS NULL),
    SUM(tournament IS NULL),
    SUM(country IS NULL)
FROM raw_results;

-- Duplicate Check
SELECT match_date, home_team, away_team, COUNT(*)
FROM raw_results
GROUP BY match_date, home_team, away_team
HAVING COUNT(*) > 1;

-- CREATE CLEAN FACT TABLE
CREATE TABLE fact_matches AS
SELECT
    match_date,
    YEAR(match_date) AS year,
    MONTH(match_date) AS month,
    home_team,
    away_team,
    home_score,
    away_score,
    (home_score + away_score) AS total_goals,
    (home_score - away_score) AS goal_difference,
    tournament,
    city,
    country,
    CASE
        WHEN home_score > away_score THEN 'Home Win'
        WHEN home_score < away_score THEN 'Away Win'
        ELSE 'Draw'
    END AS match_result,
    CASE
        WHEN neutral = 'TRUE' THEN 1
        ELSE 0
    END AS neutral_flag
FROM raw_results;

-- CREATE DIMENSIONS (STAR SCHEMA)
-- Team Dimension
CREATE TABLE dim_team AS
SELECT DISTINCT home_team AS team_name FROM raw_results
UNION
SELECT DISTINCT away_team FROM raw_results;

-- Tournament Dimension
CREATE TABLE dim_tournament AS
SELECT DISTINCT tournament FROM raw_results;

-- Country Dimension
CREATE TABLE dim_country AS
SELECT DISTINCT country FROM raw_results;

-- Date Dimension
CREATE TABLE dim_date AS
SELECT DISTINCT
    match_date,
    YEAR(match_date) AS year,
    MONTH(match_date) AS month,
    QUARTER(match_date) AS quarter
FROM raw_results;

-- TEAM PERFORMANCE VIEW
CREATE VIEW team_stats AS
SELECT
    team,
    COUNT(*) AS matches_played,
    SUM(wins) AS wins,
    SUM(draws) AS draws,
    SUM(losses) AS losses,
    SUM(goals_scored) AS goals_scored,
    SUM(goals_conceded) AS goals_conceded,
    SUM(goal_diff) AS goal_difference
FROM (
    SELECT
        home_team AS team,
        CASE WHEN home_score > away_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN home_score = away_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN home_score < away_score THEN 1 ELSE 0 END AS losses,
        home_score AS goals_scored,
        away_score AS goals_conceded,
        (home_score - away_score) AS goal_diff
    FROM fact_matches

    UNION ALL

    SELECT
        away_team AS team,
        CASE WHEN away_score > home_score THEN 1 ELSE 0 END,
        CASE WHEN away_score = home_score THEN 1 ELSE 0 END,
        CASE WHEN away_score < home_score THEN 1 ELSE 0 END,
        away_score,
        home_score,
        (away_score - home_score)
    FROM fact_matches
) combined
GROUP BY team;

-- CORE ANALYSIS QUERIES
-- Overall Result Distribution
SELECT match_result,
COUNT(*) AS matches,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2) AS percentage
FROM fact_matches
GROUP BY match_result;

-- Home Advantage vs Neutral
SELECT neutral_flag, match_result, COUNT(*) AS matches
FROM fact_matches
GROUP BY neutral_flag, match_result;

-- Year-wise Goal Trend
SELECT year,
ROUND(AVG(total_goals),2) AS avg_goals,
COUNT(*) AS matches
FROM fact_matches
GROUP BY year
ORDER BY year;

-- High Scoring Matches (3+ Goals)
SELECT year,
COUNT(CASE WHEN total_goals >= 3 THEN 1 END) AS high_scoring_matches
FROM fact_matches
GROUP BY year;

-- Win % Leaderboard
SELECT *,
ROUND((wins * 100.0 / matches_played),2) AS win_percentage
FROM team_stats
WHERE matches_played >= 100
ORDER BY win_percentage DESC;

-- Scoring Threshold Impact
SELECT
    CASE WHEN home_score >= 2 THEN '2+ Goals' ELSE '<2 Goals' END AS scoring_group,
    COUNT(*) AS matches,
    SUM(CASE WHEN match_result = 'Home Win' THEN 1 ELSE 0 END) AS wins,
    ROUND(SUM(CASE WHEN match_result = 'Home Win' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS win_percentage
FROM fact_matches
GROUP BY scoring_group;

-- PREPARE DATA FOR ML
SELECT
    CASE WHEN match_result = 'Home Win' THEN 1 ELSE 0 END AS home_win,
    goal_difference,
    total_goals,
    neutral_flag,
    year
FROM fact_matches;


SELECT COUNT(*) FROM fact_matches;
SELECT COUNT(*) FROM raw_results;


DROP TABLE fact_matches;
DROP TABLE raw_results;


CREATE TABLE raw_results (
    match_date DATE,
    home_team VARCHAR(100),
    away_team VARCHAR(100),
    home_score INT,
    away_score INT,
    tournament VARCHAR(150),
    city VARCHAR(100),
    country VARCHAR(100),
    neutral VARCHAR(10)
);

SHOW VARIABLES LIKE 'secure_file_priv';


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/results.csv'
INTO TABLE raw_results
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM raw_results;

DROP TABLE IF EXISTS fact_matches;

CREATE TABLE fact_matches AS
SELECT
    match_date,
    YEAR(match_date) AS year,
    MONTH(match_date) AS month,
    home_team,
    away_team,
    home_score,
    away_score,
    (home_score + away_score) AS total_goals,
    (home_score - away_score) AS goal_difference,
    tournament,
    city,
    country,
    CASE
        WHEN home_score > away_score THEN 'Home Win'
        WHEN home_score < away_score THEN 'Away Win'
        ELSE 'Draw'
    END AS match_result,
    CASE
        WHEN neutral = 'TRUE' THEN 1
        ELSE 0
    END AS neutral_flag
FROM raw_results;

SELECT COUNT(*) FROM fact_matches;

SELECT COUNT(DISTINCT tournament)
FROM raw_results;

DROP TABLE dim_tournament;

CREATE TABLE dim_tournament AS
SELECT DISTINCT tournament
FROM raw_results;

SELECT COUNT(DISTINCT home_team) FROM raw_results;
SELECT COUNT(DISTINCT away_team) FROM raw_results;

SELECT COUNT(DISTINCT team_name)
FROM (
    SELECT home_team AS team_name FROM raw_results
    UNION
    SELECT away_team FROM raw_results
) combined;

DROP TABLE dim_team;
CREATE TABLE dim_team AS
SELECT DISTINCT home_team AS team_name FROM raw_results
UNION
SELECT DISTINCT away_team FROM raw_results;


DROP TABLE dim_date;

CREATE TABLE dim_date AS
SELECT DISTINCT
    match_date,
    YEAR(match_date) AS year,
    MONTH(match_date) AS month
FROM raw_results;

-- =====================================
DROP TABLE IF EXISTS shootouts;

CREATE TABLE shootouts (
    match_date DATE,
    home_team VARCHAR(100),
    away_team VARCHAR(100),
    winner VARCHAR(100),
    first_shooter VARCHAR(100)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/shootouts.csv'
INTO TABLE shootouts
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(match_date, home_team, away_team, winner, first_shooter);

SELECT COUNT(*) FROM shootouts;



ALTER TABLE fact_matches
ADD COLUMN match_key VARCHAR(255);

SET SQL_SAFE_UPDATES = 0;


UPDATE fact_matches
SET match_key = CONCAT(match_date, '_', home_team, '_', away_team);

ALTER TABLE shootouts
ADD COLUMN match_key VARCHAR(255);

UPDATE shootouts
SET match_key = CONCAT(match_date, '_', home_team, '_', away_team);

SET SQL_SAFE_UPDATES = 1;

SELECT match_key FROM fact_matches LIMIT 5;


select * from raw_results
where tournament ='FIFA World Cup';

select * from fact_matches
where tournament ='FIFA World Cup';


CREATE TABLE raw_goalscorers (
    match_date DATE,
    home_team VARCHAR(100),
    away_team VARCHAR(100),
    team VARCHAR(100),
    scorer VARCHAR(150),
    minute VARCHAR(10),
    own_goal TINYINT,
    penalty TINYINT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/goalscorers.csv'
INTO TABLE raw_goalscorers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

DROP TABLE raw_goalscorers;

CREATE TABLE raw_goalscorers (
    match_date DATE,
    home_team VARCHAR(100),
    away_team VARCHAR(100),
    team VARCHAR(100),
    scorer VARCHAR(150),
    minute VARCHAR(10),
    own_goal VARCHAR(10),
    penalty VARCHAR(10)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/goalscorers.csv'
INTO TABLE raw_goalscorers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM raw_goalscorers;

CREATE TABLE dim_goal_events AS
SELECT
    ROW_NUMBER() OVER () AS goal_id,
    
    match_date,
    home_team,
    away_team,
    team AS scoring_team,
    scorer,
    minute,

    -- Base minute
    CASE
        WHEN minute LIKE '%+%' THEN
            CAST(SUBSTRING_INDEX(minute, '+', 1) AS UNSIGNED)
        ELSE
            CAST(minute AS UNSIGNED)
    END AS minute_base,

    -- Extra time minute
    CASE
        WHEN minute LIKE '%+%' THEN
            CAST(SUBSTRING_INDEX(minute, '+', -1) AS UNSIGNED)
        ELSE
            0
    END AS extra_minute,

    -- Convert TRUE/FALSE to 1/0
    CASE WHEN own_goal = 'TRUE' THEN 1 ELSE 0 END AS own_goal,
    CASE WHEN penalty = 'TRUE' THEN 1 ELSE 0 END AS penalty

FROM raw_goalscorers;

DROP TABLE IF EXISTS dim_goal_events;
CREATE TABLE dim_goal_events AS
SELECT
    ROW_NUMBER() OVER () AS goal_id,
    
    match_date,
    home_team,
    away_team,
    team AS scoring_team,
    scorer,
    minute,

    -- Safe Base Minute
    CASE
        WHEN minute = 'NA' OR minute IS NULL OR minute = '' THEN NULL
        WHEN minute LIKE '%+%' THEN
            CAST(SUBSTRING_INDEX(minute, '+', 1) AS UNSIGNED)
        ELSE
            CAST(minute AS UNSIGNED)
    END AS minute_base,

    -- Safe Extra Time
    CASE
        WHEN minute LIKE '%+%' THEN
            CAST(SUBSTRING_INDEX(minute, '+', -1) AS UNSIGNED)
        ELSE
            0
    END AS extra_minute,

    CASE WHEN own_goal = 'TRUE' THEN 1 ELSE 0 END AS own_goal,
    CASE WHEN penalty = 'TRUE' THEN 1 ELSE 0 END AS penalty

FROM raw_goalscorers;

ALTER TABLE dim_goal_events
ADD COLUMN minute_total INT;

SET SQL_SAFE_UPDATES = 0;

UPDATE dim_goal_events
SET minute_total =
    CASE
        WHEN minute_base IS NULL THEN NULL
        ELSE minute_base + extra_minute
    END;
    
SET SQL_SAFE_UPDATES = 1;
    
ALTER TABLE dim_goal_events
ADD COLUMN time_slot VARCHAR(20);

SET SQL_SAFE_UPDATES = 0;

UPDATE dim_goal_events
SET time_slot =
    CASE
        WHEN minute_total IS NULL THEN 'Unknown'
        WHEN minute_total BETWEEN 0 AND 15 THEN '0-15'
        WHEN minute_total BETWEEN 16 AND 30 THEN '16-30'
        WHEN minute_total BETWEEN 31 AND 45 THEN '31-45'
        WHEN minute_total BETWEEN 46 AND 60 THEN '46-60'
        WHEN minute_total BETWEEN 61 AND 75 THEN '61-75'
        WHEN minute_total BETWEEN 76 AND 90 THEN '76-90'
        WHEN minute_total BETWEEN 91 AND 105 THEN '90-105'
        WHEN minute_total BETWEEN 106 AND 120 THEN '105-120'
        ELSE '120+'
    END;

SET SQL_SAFE_UPDATES = 1;

ALTER TABLE fact_matches
ADD COLUMN match_key VARCHAR(255);

SET SQL_SAFE_UPDATES = 0;

UPDATE fact_matches
SET match_key = CONCAT(match_date, '_', home_team, '_', away_team)
WHERE match_key IS NULL OR match_key = '';

SET SQL_SAFE_UPDATES = 1;

SHOW COLUMNS FROM dim_goal_events LIKE 'match_key';

ALTER TABLE dim_goal_events
ADD COLUMN match_key VARCHAR(255);

SET SQL_SAFE_UPDATES = 0;

UPDATE dim_goal_events
SET match_key = CONCAT(match_date, '_', home_team, '_', away_team)
WHERE match_key IS NULL OR match_key = '';

SET SQL_SAFE_UPDATES = 1;

SHOW INDEX FROM dim_goal_events WHERE Key_name = 'idx_goal_match_key';

CREATE INDEX idx_goal_match_key ON dim_goal_events(match_key);

CREATE INDEX idx_goal_team ON dim_goal_events(scoring_team);
CREATE INDEX idx_goal_minute ON dim_goal_events(minute_total);

DROP TABLE IF EXISTS fact_team_goal_timing;

CREATE TABLE fact_team_goal_timing AS
SELECT
    scoring_team,
    time_slot,
    COUNT(*) AS goals_scored
FROM dim_goal_events
GROUP BY scoring_team, time_slot;

DROP TABLE IF EXISTS fact_player_stats;

CREATE TABLE fact_player_stats AS
SELECT
    scorer,
    scoring_team,

    COUNT(*) AS total_goals,

    SUM(penalty) AS penalty_goals,
    SUM(own_goal) AS own_goals,

    SUM(CASE WHEN minute_total <= 15 THEN 1 ELSE 0 END) AS early_goals,
    SUM(CASE WHEN minute_total >= 76 THEN 1 ELSE 0 END) AS late_goals,
    SUM(CASE WHEN minute_total >= 90 THEN 1 ELSE 0 END) AS stoppage_goals

FROM dim_goal_events
GROUP BY scorer, scoring_team;

DROP TABLE IF EXISTS fact_penalty_analysis;

CREATE TABLE fact_penalty_analysis AS
SELECT
    scoring_team,
    COUNT(*) AS total_goals,
    SUM(penalty) AS penalty_goals,
    ROUND(SUM(penalty) / COUNT(*) * 100, 2) AS penalty_percentage
FROM dim_goal_events
GROUP BY scoring_team;

DROP TABLE IF EXISTS fact_clutch_goals;

CREATE TABLE fact_clutch_goals AS
SELECT
    scoring_team,
    COUNT(*) AS goals_after_75
FROM dim_goal_events
WHERE minute_total >= 76
GROUP BY scoring_team;

SELECT COUNT(*) FROM dim_goal_events;

SELECT time_slot, COUNT(*) 
FROM dim_goal_events
GROUP BY time_slot
ORDER BY time_slot;

SELECT * FROM fact_player_stats
ORDER BY total_goals DESC
LIMIT 10;

SELECT match_key, COUNT(*)
FROM fact_matches
GROUP BY match_key
HAVING COUNT(*) > 1;

SELECT match_id, COUNT(*)
FROM fact_matches
GROUP BY match_id
HAVING COUNT(*) > 1;

DESCRIBE fact_matches;

ALTER TABLE fact_matches
ADD COLUMN match_id INT AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE dim_goal_events
ADD COLUMN match_id INT;

SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;
SET GLOBAL net_read_timeout = 600;
SET GLOBAL net_write_timeout = 600;
SHOW VARIABLES LIKE 'wait_timeout';
SET GLOBAL max_allowed_packet = 1073741824;

SET SQL_SAFE_UPDATES = 0;

UPDATE dim_goal_events g
JOIN fact_matches m
  ON g.match_date = m.match_date
 AND g.home_team = m.home_team
 AND g.away_team = m.away_team
SET g.match_id = m.match_id
WHERE g.match_id IS NULL
LIMIT 20000;

ALTER USER 'root'@'localhost'
IDENTIFIED WITH mysql_native_password
BY 'password';

FLUSH PRIVILEGES;

SELECT user, host, plugin 
FROM mysql.user 
WHERE user = 'root';

ALTER TABLE dim_goal_events
ADD COLUMN match_id INT;

SELECT COUNT(*) 
FROM dim_goal_events
WHERE match_id IS NULL;

SELECT match_id, COUNT(*)
FROM fact_matches
GROUP BY match_id
HAVING COUNT(*) > 1;

SELECT goal_id, COUNT(*)
FROM dim_goal_events
GROUP BY goal_id
HAVING COUNT(*) > 1;

SELECT VERSION();


SELECT match_result, COUNT(*)
FROM fact_matches
WHERE year = 1930
GROUP BY match_result;
