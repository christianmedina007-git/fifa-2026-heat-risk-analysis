Create schema mini_project_3;
USE mini_project_3;

-- CREATE COUNTRIES Table
CREATE TABLE COUNTRIES (
    CountryID    INT NOT NULL AUTO_INCREMENT,
    CountryName  VARCHAR(100) NOT NULL,
    CONSTRAINT PK_COUNTRIES PRIMARY KEY (CountryID)
);

-- CREATE CITIES Table
CREATE TABLE CITIES (
    CityID     INT NOT NULL AUTO_INCREMENT,
    CityName   VARCHAR(100) NOT NULL,
    Latitude   DOUBLE NOT NULL,
    Longitude  DOUBLE NOT NULL,
    CountryID  INT NOT NULL,
    CONSTRAINT PK_CITIES PRIMARY KEY (CityID),
    CONSTRAINT FK_CITIES_COUNTRIES
        FOREIGN KEY (CountryID) REFERENCES COUNTRIES (CountryID)
);

-- CREATE STADIUMS Table
CREATE TABLE STADIUMS (
    StadiumID    INT NOT NULL AUTO_INCREMENT,
    StadiumName  VARCHAR(150) NOT NULL,
    Capacity     DOUBLE NOT NULL,
    HasRoof      ENUM('NONE', 'STATIC', 'RETRACTABLE') NOT NULL DEFAULT 'NONE',
    CityID       INT NOT NULL,
    CONSTRAINT PK_STADIUMS PRIMARY KEY (StadiumID),
    CONSTRAINT FK_STADIUMS_CITIES
        FOREIGN KEY (CityID) REFERENCES CITIES (CityID)
);

-- CREATE MATCHES Table
CREATE TABLE MATCHES (
    MatchID      INT NOT NULL AUTO_INCREMENT,
    MatchDate    DATE NOT NULL,
    KickoffTime  TIME NOT NULL,
    MatchRound  VARCHAR(15) NOT NULL,
    StadiumID    INT NOT NULL,
    CONSTRAINT PK_MATCHES PRIMARY KEY (MatchID),
    CONSTRAINT FK_MATCHES_STADIUMS
        FOREIGN KEY (StadiumID) REFERENCES STADIUMS (StadiumID)
);

-- CREATE WEATHER_OBSERVATIONS Table
CREATE TABLE WEATHER_OBSERVATIONS (
    WeatherID         INT NOT NULL AUTO_INCREMENT,
    ObservationDate   DATE NOT NULL,
    ObservationHour   TINYINT NOT NULL,
    AirTemperature    DOUBLE NOT NULL,
    RelativeHumidity  DECIMAL(4,1) NOT NULL,
    WindSpeed         DOUBLE NOT NULL,
    SolarRadiation    DECIMAL(6,1) NOT NULL,
    CityID            INT NOT NULL,
    CONSTRAINT PK_WEATHER_OBSERVATIONS PRIMARY KEY (WeatherID),
    CONSTRAINT FK_WEATHER_OBSERVATIONS_CITIES
        FOREIGN KEY (CityID) REFERENCES CITIES (CityID)
);

-- CREATE WBGT_CALCULATIONS Table
CREATE TABLE WBGT_CALCULATIONS (
    WBGTID      INT NOT NULL AUTO_INCREMENT,
    WBGTValue   DOUBLE NOT NULL,
    WeatherID   INT NOT NULL,
    CONSTRAINT PK_WBGT_CALCULATIONS PRIMARY KEY (WBGTID),
    CONSTRAINT FK_WBGT_CALCULATIONS_WEATHER
        FOREIGN KEY (WeatherID) REFERENCES WEATHER_OBSERVATIONS (WeatherID)
);

-- CREATE WBGT_CLIMATOLOGY Table
CREATE TABLE WBGT_CLIMATOLOGY (
    ClimatologyID   INT NOT NULL AUTO_INCREMENT,
    CityID          INT NOT NULL,
    ObsMonth        TINYINT NOT NULL,
    ObsDay          TINYINT NOT NULL,
    ObsHour         TINYINT NOT NULL,
    ClimatologyType ENUM('Average', 'Hot') NOT NULL,
    WBGTValue       DECIMAL(5,2) NOT NULL,
    CONSTRAINT PK_WBGT_CLIMATOLOGY PRIMARY KEY (ClimatologyID),
    CONSTRAINT FK_WBGT_CLIMATOLOGY_CITIES
        FOREIGN KEY (CityID) REFERENCES CITIES (CityID)
);

-- INSERT COUNTRIES Data from raw_fifa_host_cities
INSERT INTO COUNTRIES (CountryName)
	SELECT DISTINCT Country FROM raw_fifa_2026_host_cities;
    
-- INSERT CITIES Data from raw_fifa_2026_host_cities
INSERT INTO CITIES (CityName, Latitude, Longitude, CountryID)
	SELECT City, Latitude, Longitude, CountryID FROM raw_fifa_2026_host_cities r
		JOIN COUNTRIES on r.Country = COUNTRIES.CountryName;

-- INSERT STADIUMS Data from raw_fifa_2026_host_cities
INSERT INTO STADIUMS (StadiumName, Capacity, HasRoof, CityID)
	SELECT Stadium, Capacity, Roof, CityID FROM raw_fifa_2026_host_cities r
		JOIN CITIES on r.City = CITIES.CityName;
        
-- INSERT MATCHES Date from raw_fifa_2026_match_schedule
INSERT INTO MATCHES (MatchDate, KickoffTime, MatchRound, StadiumID)
	SELECT MatchDate, KickoffTime, `Round`, StadiumID FROM raw_fifa_2026_match_schedule r
		JOIN STADIUMS on r.Stadium = STADIUMS.StadiumName;
        
-- INSERT WEATHER_OBSERVATIONS Data from raw_fifa_2026_weather_hourly_2003_2022
INSERT INTO WEATHER_OBSERVATIONS (ObservationDate, ObservationHour, AirTemperature, RelativeHumidity, WindSpeed, SolarRadiation, CityID)
	SELECT ObservationDate, ObservationHour, AirTemperature_C, RelativeHumidity_pct, WindSpeed_kmh, SolarRadiation_Wm2, CityID FROM raw_fifa_2026_weather_hourly_2003_2022 r
		JOIN CITIES on r.City = CITIES.CityName;

-- INSERT WBGT_CALCULATIONS Data
--  Formula for WBGT sourced from Kaggle
INSERT INTO WBGT_CALCULATIONS (WBGTValue, WeatherID)
SELECT
    (
        0.7 * (
            AirTemperature * ATAN(0.151977 * SQRT(RelativeHumidity + 8.313659))
            + ATAN(AirTemperature + RelativeHumidity)
            - ATAN(RelativeHumidity - 1.676331)
            + 0.00391838 * POWER(RelativeHumidity, 1.5) * ATAN(0.023101 * RelativeHumidity)
            - 4.686035
        )
        +
        0.2 * (AirTemperature + (SolarRadiation / 1000) * 5)
        +
        0.1 * AirTemperature
    ) AS WBGTValue,
    WeatherID
FROM WEATHER_OBSERVATIONS;

-- INSERT WBGT_CLIMATOLOGY Data
INSERT INTO WBGT_CLIMATOLOGY
    (CityID, ObsMonth, ObsDay, ObsHour, ClimatologyType, WBGTValue)

-- Average climatology
SELECT
    wo.CityID,
    MONTH(wo.ObservationDate) AS ObsMonth,
    DAY(wo.ObservationDate) AS ObsDay,
    wo.ObservationHour AS ObsHour,
    'Average' AS ClimatologyType,
    ROUND(AVG(wc.WBGTValue), 2) AS WBGTValue
FROM WEATHER_OBSERVATIONS wo
JOIN WBGT_CALCULATIONS wc
    ON wo.WeatherID = wc.WeatherID
GROUP BY
    wo.CityID,
    MONTH(wo.ObservationDate),
    DAY(wo.ObservationDate),
    wo.ObservationHour

UNION ALL

-- Hot climatology = 95th percentile
SELECT
    hot.CityID,
    hot.ObsMonth,
    hot.ObsDay,
    hot.ObsHour,
    'Hot' AS ClimatologyType,
    ROUND(MIN(hot.WBGTValue), 2) AS WBGTValue
FROM (
    SELECT
        wo.CityID,
        MONTH(wo.ObservationDate) AS ObsMonth,
        DAY(wo.ObservationDate) AS ObsDay,
        wo.ObservationHour AS ObsHour,
        wc.WBGTValue,
        ROW_NUMBER() OVER (
            PARTITION BY
                wo.CityID,
                MONTH(wo.ObservationDate),
                DAY(wo.ObservationDate),
                wo.ObservationHour
            ORDER BY wc.WBGTValue
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY
                wo.CityID,
                MONTH(wo.ObservationDate),
                DAY(wo.ObservationDate),
                wo.ObservationHour
        ) AS cnt
    FROM WEATHER_OBSERVATIONS wo
    JOIN WBGT_CALCULATIONS wc
        ON wo.WeatherID = wc.WeatherID
) hot
WHERE hot.rn >= CEIL(0.95 * hot.cnt)
GROUP BY
    hot.CityID,
    hot.ObsMonth,
    hot.ObsDay,
    hot.ObsHour;
    
    -- QUERY to find the risk score for each match based on historical Average
    -- -- and Hot GBWT values for each location at kickoff time
    SELECT
    m.MatchID,
    m.MatchDate,
    m.KickoffTime,
    s.StadiumName,
    MAX(CASE WHEN clim.ClimatologyType = 'Average' THEN clim.WBGTValue END) AS WBGT_Avg,
    MAX(CASE WHEN clim.ClimatologyType = 'Hot'     THEN clim.WBGTValue END) AS WBGT_Hot,
    CASE
      WHEN MAX(CASE WHEN clim.ClimatologyType = 'Average' THEN clim.WBGTValue END) > 32 THEN 5
      WHEN MAX(CASE WHEN clim.ClimatologyType = 'Hot'     THEN clim.WBGTValue END) > 32
        OR MAX(CASE WHEN clim.ClimatologyType = 'Average' THEN clim.WBGTValue END) > 28 THEN 4
      WHEN MAX(CASE WHEN clim.ClimatologyType = 'Hot'     THEN clim.WBGTValue END) > 28
        OR MAX(CASE WHEN clim.ClimatologyType = 'Average' THEN clim.WBGTValue END) > 26 THEN 3
      WHEN MAX(CASE WHEN clim.ClimatologyType = 'Hot'     THEN clim.WBGTValue END) > 26 THEN 2
      ELSE 1
    END AS RiskTier
FROM MATCHES m
JOIN STADIUMS s            ON s.StadiumID = m.StadiumID
JOIN WBGT_CLIMATOLOGY clim ON clim.CityID   = s.CityID
                          AND clim.ObsMonth = MONTH(m.MatchDate)
                          AND clim.ObsDay   = DAY(m.MatchDate)
                          AND clim.ObsHour  = HOUR(m.KickoffTime)
GROUP BY m.MatchID, m.MatchDate, m.KickoffTime, s.StadiumName
ORDER BY RiskTier DESC, WBGT_Hot DESC;