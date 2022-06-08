--------------------------------------------
----- Step 0: CREATE ALL TABLES NEEDED -----
--------------------------------------------

USE [patstat2022a]
GO

-- 0.1 table containing the patent offices to browse
-- Table: po
DROP TABLE IF EXISTS patstat2022a.dbo.po;

CREATE TABLE patstat2022a.dbo.po (
patent_office CHAR(2) DEFAULT NULL
);  -- COMMENT ON TABLE po IS 'List of patent offices to browse';

INSERT INTO patstat2022a.dbo.po VALUES ('AL'), ('AT'), ('AU'), ('BE'), ('BG'),('BR'), ('CA'), ('CH'), ('CL'), ('CN'),('CY'), ('CZ'), ('DE'), ('DK'), ('EE'), ('EP'), ('ES'), ('FI'), ('FR'), ('GB'), ('GR'), ('HR'), ('HU'),('IB'), ('IE'), ('IL'), ('IN'), ('IS'), ('IT'), ('JP'), ('KR'), ('LT'), ('LU'), ('LV'), ('MK'), ('MT'), ('MX'), ('NL'), ('NO'), ('NZ'), ('PL'), ('PT'), ('RO'), ('RS'), ('RU'), ('SE'), ('SI'), ('SK'), ('SM'), ('TR'), ('US'), ('ZA');
-- 52 rows affected
DROP INDEX IF EXISTS po.po_idx;

CREATE UNIQUE CLUSTERED INDEX [po_idx] ON [patstat2022a].[dbo].[po]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


-- 0.2 Table containing the priority filings of a given (patent office, year)
-- Table: PRIORITY_FILINGS_app
DROP TABLE IF EXISTS patstat2022a.dbo.PRIORITY_FILINGS_app;

CREATE TABLE patstat2022a.dbo.PRIORITY_FILINGS_app(
appln_id INT,
appln_kind CHAR,
person_id INT,
patent_office VARCHAR(2),
appln_filing_year INT,
appln_filing_date DATE,
f_type VARCHAR(MAX)
);


-- priority
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS_app
-- 8385972 rows affected
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'priority'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.tls204_appln_prior t2 ON t1.appln_id = t2.prior_appln_id
JOIN patstat2022a.dbo.po t5 ON t1.appln_auth = t5.patent_office
JOIN patstat2022a.dbo.tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
WHERE (t1.appln_kind != 'W')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
-- AND t1.appln_filing_year < 2023;
;

INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS_app
-- 394293 rows affected
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'priority'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.tls204_appln_prior t2 ON t1.appln_id = t2.prior_appln_id
JOIN patstat2022a.dbo.po t5 ON t1.receiving_office = t5.patent_office
JOIN patstat2022a.dbo.tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
WHERE (t1.appln_kind = 'W')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
-- AND t1.appln_filing_year < 2023;
;

-- pct
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS_app
-- 676801 rows affected
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth AS patent_office, t1.appln_filing_year, t1.appln_filing_date, 'pct'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.po t5 ON t1.receiving_office = t5.patent_office
JOIN patstat2022a.dbo.tls207_pers_appln t6 ON t1.appln_id = t6.appln_id

  LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind = 'W')
AND t1.internat_appln_id = 0 and nat_phase = 'N' and reg_phase = 'N'
AND t1.appln_id = t1.earliest_filing_id
AND applt_seq_nr > 0
-- AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;

-- continual
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS_app
-- 2064353 rows affected
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'continual'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.tls216_appln_contn t2 ON t1.appln_id = t2.parent_appln_id
JOIN patstat2022a.dbo.po t5 ON t1.appln_auth = t5.patent_office
JOIN patstat2022a.dbo.tls207_pers_appln t6 ON t1.appln_id = t6.appln_id

      LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind != 'W')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
-- AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;

INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS_app
-- 13 rows affected
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'continual'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.tls216_appln_contn t2 ON t1.appln_id = t2.parent_appln_id
JOIN patstat2022a.dbo.po t5 ON t1.receiving_office = t5.patent_office
JOIN patstat2022a.dbo.tls207_pers_appln t6 ON t1.appln_id = t6.appln_id

      LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind = 'W')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
-- AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;


-- tech_rel
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS_app
-- 1508144 rows affected
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'tech_rel'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.tls205_tech_rel t2 ON t1.appln_id = t2.tech_rel_appln_id
JOIN patstat2022a.dbo.po t5 ON t1.appln_auth = t5.patent_office
JOIN patstat2022a.dbo.tls207_pers_appln t6 ON t1.appln_id = t6.appln_id

      LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind != 'W')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
-- AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;

INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS_app
-- 25294 rows affected
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'tech_rel'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.tls205_tech_rel t2 ON t1.appln_id = t2.tech_rel_appln_id
JOIN patstat2022a.dbo.po t5 ON t1.receiving_office = t5.patent_office
JOIN patstat2022a.dbo.tls207_pers_appln t6 ON t1.appln_id = t6.appln_id

      LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind = 'W')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
-- AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;


-- single
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS_app
-- 57339139 rows affected
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'single'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN (SELECT docdb_family_id from patstat2022a.dbo.tls201_appln group by docdb_family_id having count(distinct appln_id) = 1) as t2
ON t1.docdb_family_id = t2.docdb_family_id
JOIN patstat2022a.dbo.po t5 ON t1.appln_auth = t5.patent_office
JOIN patstat2022a.dbo.tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
      LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind != 'W')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
-- AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;

INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS_app
-- 484634 rows affected
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'single'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN (SELECT docdb_family_id from patstat2022a.dbo.tls201_appln group by docdb_family_id having count(distinct appln_id) = 1) as t2
ON t1.docdb_family_id = t2.docdb_family_id
JOIN patstat2022a.dbo.po t5 ON t1.receiving_office = t5.patent_office
JOIN patstat2022a.dbo.tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
      LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind = 'W')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
-- AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;


DROP INDEX IF EXISTS dbo.PRIORITY_FILINGS_app.pfa_idx, dbo.PRIORITY_FILINGS_app.pfa_idx2, dbo.PRIORITY_FILINGS_app.pfa_idx3;

CREATE CLUSTERED INDEX [pfa_idx] ON [patstat2022a].[dbo].[PRIORITY_FILINGS_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [pfa_idx2] ON [patstat2022a].[dbo].[PRIORITY_FILINGS_app]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [pfa_idx3] ON [patstat2022a].[dbo].[PRIORITY_FILINGS_app]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


-- 0.3 Table containing appln_id, person_id, ctry_code
-- Table: country_codes_inv
DROP TABLE IF EXISTS patstat2022a.dbo.country_codes_inv;

CREATE TABLE patstat2022a.dbo.country_codes_inv(
appln_id INT,
person_id INT,
ctry_code CHAR(2)
--invt_seq_nr INT
)

INSERT INTO patstat2022a.dbo.country_codes_inv
-- 217376298 rows affected
SELECT DISTINCT t1.appln_id, t1.person_id, t2.person_ctry_code AS ctry_code 
FROM patstat2022a.dbo.tls207_pers_appln t1
JOIN patstat2022a.dbo.tls206_person t2 ON t1.person_id = t2.person_id
WHERE invt_seq_nr > 0;


-- Table: country_codes_app
DROP TABLE IF EXISTS patstat2022a.dbo.country_codes_app;

CREATE TABLE patstat2022a.dbo.country_codes_app(
appln_id INT,
person_id INT,
ctry_code CHAR(2)
-- applt_seq_nr INT
)

INSERT INTO patstat2022a.dbo.country_codes_app
-- 113637398 rows affected
SELECT DISTINCT t1.appln_id, t1.person_id, t2.person_ctry_code AS ctry_code 
FROM patstat2022a.dbo.tls207_pers_appln t1
JOIN patstat2022a.dbo.tls206_person t2 ON t1.person_id = t2.person_id
WHERE applt_seq_nr > 0;


DROP INDEX IF EXISTS dbo.country_codes_inv.country_codes_inv_idx, dbo.country_codes_inv.country_codes_pers_inv_idx;

CREATE CLUSTERED INDEX [country_codes_inv_idx] ON [patstat2022a].[dbo].[country_codes_inv]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [country_codes_pers_inv_idx] ON [patstat2022a].[dbo].[country_codes_inv]
(
   [person_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


DROP INDEX IF EXISTS dbo.country_codes_app.country_codes_app_idx, dbo.country_codes_app.country_codes_pers_app_idx;

CREATE CLUSTERED INDEX [country_codes_app_idx] ON [patstat2022a].[dbo].[country_codes_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [country_codes_pers_app_idx] ON [patstat2022a].[dbo].[country_codes_app]
(
   [person_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO





-- 1.1 Applicant information

-- A. Information that is directly available (source = 1)
-- Table: PRIORITY_FILINGS1_app
DROP TABLE IF EXISTS patstat2022a.dbo.PRIORITY_FILINGS1_app;

CREATE TABLE patstat2022a.dbo.PRIORITY_FILINGS1_app(
appln_id INT,
person_id INT,
patent_office VARCHAR(2),
appln_filing_date DATE,
appln_filing_year INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX)
)

INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS1_app
-- 70878643 rows affected
SELECT DISTINCT t1.appln_id, t1.person_id, t1.patent_office, t1.appln_filing_date, t1.appln_filing_year, ctry_code, t1.f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
LEFT OUTER JOIN patstat2022a.dbo.country_codes_app t2 ON (t1.appln_id = t2.appln_id AND t1.person_id = t2.person_id);

DROP INDEX IF EXISTS dbo.PRIORITY_FILINGS1_app.pri1_idx, 
dbo.PRIORITY_FILINGS1_app.pri1_pers_idx, 
dbo.PRIORITY_FILINGS1_app.pri1_office_idx, 
dbo.PRIORITY_FILINGS1_app.pri1_year;

CREATE CLUSTERED INDEX [pri1_idx] ON [patstat2022a].[dbo].[PRIORITY_FILINGS1_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [pri1_pers_idx] ON [patstat2022a].[dbo].[PRIORITY_FILINGS1_app]
(
   [person_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [pri1_office_idx] ON [patstat2022a].[dbo].[PRIORITY_FILINGS1_app]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [pri1_year_idx] ON [patstat2022a].[dbo].[PRIORITY_FILINGS1_app]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO







-- B. Prepare a pool of all potential second filings
-- Table: temp
-- 1.1-B-temp.sql
CREATE TABLE patstat2022a.dbo.temp(
appln_id INT,
subsequent_id INT,
subsequent_date DATE,
nb_priorities INT
)

INSERT INTO patstat2022a.dbo.temp
-- 24251634 rows affected
SELECT t1.appln_id, t3.appln_id AS subsequent_id, t3.appln_filing_date AS subsequent_date, max(t4.prior_appln_seq_nr) AS nb_priorities
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
INNER JOIN patstat2022a.dbo.tls204_appln_prior t2 ON t2.prior_appln_id = t1.appln_id
INNER JOIN patstat2022a.dbo.tls201_appln t3 ON t3.appln_id = t2.appln_id
INNER JOIN patstat2022a.dbo.tls204_appln_prior t4 ON t4.appln_id = t3.appln_id
WHERE t1.f_type = 'priority'
GROUP BY t1.appln_id, t3.appln_id, t3.appln_filing_date ;

DROP INDEX IF EXISTS dbo.PRIORITY_FILINGS1.pri1_idx, dbo.PRIORITY_FILINGS1.pri1_pers_idx, dbo.PRIORITY_FILINGS1.pri1_office_idx, dbo.PRIORITY_FILINGS1.pri1_year;

CREATE CLUSTERED INDEX [t_appln_id] ON [patstat2022a].[dbo].[temp]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO








-- Table: SUBSEQUENT_FILINGS1_app
-- 1.1-B-SUBSEQUENT_FILINGS1_app.sql
DROP TABLE IF EXISTS patstat2022a.dbo.SUBSEQUENT_FILINGS1_app;

CREATE TABLE patstat2022a.dbo.SUBSEQUENT_FILINGS1_app(
appln_id INT,
subsequent_id INT,
subsequent_person_id INT,
applt_seq_nr INT,
invt_seq_nr INT,
patent_office VARCHAR(2),
appln_filing_year INT,
subsequent_date DATE,
nb_priorities INT,
f_type VARCHAR(MAX)
)

INSERT INTO patstat2022a.dbo.SUBSEQUENT_FILINGS1_app
-- 78691913 rows affected
SELECT DISTINCT t1.appln_id, t.subsequent_id, t2.person_id as subsequent_person_id, applt_seq_nr, invt_seq_nr, t1.patent_office, t1.appln_filing_year, t.subsequent_date, t.nb_priorities, t1.f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
JOIN patstat2022a.dbo.temp t ON (t1.appln_id = t.appln_id )
JOIN patstat2022a.dbo.tls207_pers_appln t2 ON (t.subsequent_id = t2.appln_id)
ORDER BY t1.appln_id, t.subsequent_date, t2.person_id, applt_seq_nr, invt_seq_nr ASC;









-- Insert 1.0
DROP TABLE patstat2022a.dbo.temp;

CREATE TABLE patstat2022a.dbo.temp(
appln_id INT,
subsequent_id INT,
subsequent_date DATE,
nb_priorities INT
)

INSERT INTO patstat2022a.dbo.temp
-- 2078749 rows affected
SELECT t1.appln_id, t3.appln_id AS subsequent_id, t3.appln_filing_date AS subsequent_date, max(t4.count_4) AS nb_priorities
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
INNER JOIN patstat2022a.dbo.tls216_appln_contn t2 ON t2.parent_appln_id = t1.appln_id
INNER JOIN patstat2022a.dbo.tls201_appln t3 ON t3.appln_id = t2.appln_id
INNER JOIN (select appln_id, count(*) AS count_4 from patstat2022a.dbo.tls216_appln_contn group by appln_id) as t4 ON t4.appln_id = t3.appln_id
WHERE f_type = 'continual'
GROUP BY t1.appln_id, t3.appln_id, t3.appln_filing_date ;

CREATE CLUSTERED INDEX [t_appln_id] ON [patstat2022a].[dbo].[temp]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


INSERT INTO patstat2022a.dbo.SUBSEQUENT_FILINGS1_app
-- 8205402 rows affected
SELECT DISTINCT t1.appln_id, t.subsequent_id, t2.person_id as subsequent_person_id, applt_seq_nr, invt_seq_nr, t1.patent_office, t1.appln_filing_year, t.subsequent_date, t.nb_priorities, f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
JOIN patstat2022a.dbo.temp t ON (t1.appln_id = t.appln_id )
JOIN patstat2022a.dbo.tls207_pers_appln t2 ON (t.subsequent_id = t2.appln_id)
ORDER BY t1.appln_id, t.subsequent_date, t2.person_id, applt_seq_nr, invt_seq_nr ASC;








-- Insert 1.0
DROP TABLE patstat2022a.dbo.temp;

CREATE TABLE patstat2022a.dbo.temp(
appln_id INT,
subsequent_id INT,
subsequent_date DATE,
nb_priorities INT
)

INSERT INTO patstat2022a.dbo.temp
-- 24251634 rows affected
SELECT t1.appln_id, t3.appln_id AS subsequent_id, t3.appln_filing_date AS subsequent_date, max(t4.prior_appln_seq_nr) AS nb_priorities
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
INNER JOIN patstat2022a.dbo.tls204_appln_prior t2 ON t2.prior_appln_id = t1.appln_id
INNER JOIN patstat2022a.dbo.tls201_appln t3 ON t3.appln_id = t2.appln_id
INNER JOIN patstat2022a.dbo.tls204_appln_prior t4 ON t4.appln_id = t3.appln_id
WHERE f_type = 'priority'
GROUP BY t1.appln_id, t3.appln_id, t3.appln_filing_date ;

CREATE CLUSTERED INDEX [t_appln_id] ON [patstat2022a].[dbo].[temp]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


INSERT INTO patstat2022a.dbo.SUBSEQUENT_FILINGS1_app
-- 78691913 rows affected
SELECT DISTINCT t1.appln_id, t.subsequent_id, t2.person_id as subsequent_person_id, applt_seq_nr, invt_seq_nr, t1.patent_office, t1.appln_filing_year, t.subsequent_date, t.nb_priorities, f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
JOIN patstat2022a.dbo.temp t ON (t1.appln_id = t.appln_id )
JOIN patstat2022a.dbo.tls207_pers_appln t2 ON (t.subsequent_id = t2.appln_id)
ORDER BY t1.appln_id, t.subsequent_date, t2.person_id, applt_seq_nr, invt_seq_nr ASC;








-- Insert 2.0
DROP TABLE IF EXISTS patstat2022a.dbo.temp;

CREATE TABLE patstat2022a.dbo.temp(
appln_id INT,
subsequent_id INT,
subsequent_date DATE,
nb_priorities INT
)

INSERT INTO patstat2022a.dbo.temp
-- 1706077 rows affected
SELECT t1.appln_id, t3.appln_id AS subsequent_id, t3.appln_filing_date AS subsequent_date, max(t4.count_4) AS nb_priorities
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
INNER JOIN patstat2022a.dbo.TLS205_TECH_REL t2 ON t2.tech_rel_appln_id = t1.appln_id
INNER JOIN patstat2022a.dbo.tls201_appln t3 ON t3.appln_id = t2.appln_id
INNER JOIN (select appln_id, count(*) AS count_4 from patstat2022a.dbo.TLS205_TECH_REL group by appln_id) as t4 ON t4.appln_id = t3.appln_id
WHERE f_type = 'tech_rel'
GROUP BY t1.appln_id, t3.appln_id, t3.appln_filing_date;

CREATE CLUSTERED INDEX [t_appln_id] ON [patstat2022a].[dbo].[temp]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

INSERT INTO patstat2022a.dbo.SUBSEQUENT_FILINGS1_app
-- 1123577 rows affected
SELECT DISTINCT t1.appln_id, t.subsequent_id, t2.person_id as subsequent_person_id, applt_seq_nr, invt_seq_nr, t1.patent_office, t1.appln_filing_year, t.subsequent_date, t.nb_priorities, f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
JOIN patstat2022a.dbo.temp t ON (t1.appln_id = t.appln_id )
JOIN patstat2022a.dbo.tls207_pers_appln t2 ON (t.subsequent_id = t2.appln_id)
ORDER BY t1.appln_id, t.subsequent_date, t2.person_id, applt_seq_nr, invt_seq_nr ASC;






-- Insert 3.0
DROP TABLE IF EXISTS patstat2022a.dbo.temp;

CREATE TABLE patstat2022a.dbo.temp(
appln_id INT,
subsequent_id INT,
subsequent_date DATE
)

INSERT INTO patstat2022a.dbo.temp
-- 157494 rows affected
SELECT t1.appln_id, t2.appln_id AS subsequent_id, t2.appln_filing_date AS subsequent_date
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
INNER JOIN patstat2022a.dbo.tls201_appln t2 ON t1.appln_id = t2.internat_appln_id
WHERE f_type = 'pct'
AND t2.internat_appln_id != 0 and reg_phase = 'Y'
GROUP BY t1.appln_id, t2.appln_id, t2.appln_filing_date;

CREATE CLUSTERED INDEX [t_appln_id] ON [patstat2022a].[dbo].[temp]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO   

INSERT INTO patstat2022a.dbo.SUBSEQUENT_FILINGS1_app
-- 567649 rows affected
SELECT DISTINCT t1.appln_id, t.subsequent_id, t2.person_id as subsequent_person_id, applt_seq_nr, invt_seq_nr, t1.patent_office, t1.appln_filing_year, t.subsequent_date, 1, f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
JOIN patstat2022a.dbo.temp t ON (t1.appln_id = t.appln_id )
JOIN patstat2022a.dbo.tls207_pers_appln t2 ON (t.subsequent_id = t2.appln_id)
ORDER BY t1.appln_id, t.subsequent_date, t2.person_id, applt_seq_nr, invt_seq_nr ASC;










-- Insert 4.0
DROP TABLE IF EXISTS patstat2022a.dbo.temp;

CREATE TABLE patstat2022a.dbo.temp(
appln_id INT,
subsequent_id INT,
subsequent_date DATE
)

INSERT INTO patstat2022a.dbo.temp
-- 557185 rows affected
SELECT t1.appln_id, t2.appln_id AS subsequent_id, t2.appln_filing_date AS subsequent_date
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
INNER JOIN patstat2022a.dbo.tls201_appln t2 ON t1.appln_id = t2.internat_appln_id
WHERE f_type = 'pct'
AND t2.internat_appln_id != 0 and nat_phase = 'Y'
GROUP BY t1.appln_id, t2.appln_id, t2.appln_filing_date;

CREATE CLUSTERED INDEX [t_appln_id] ON [patstat2022a].[dbo].[temp]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO      

INSERT INTO patstat2022a.dbo.subsequent_filings1_app
-- 1718821 rows affected
SELECT DISTINCT t1.appln_id, t.subsequent_id, t2.person_id as subsequent_person_id, applt_seq_nr, invt_seq_nr, t1.patent_office, t1.appln_filing_year, t.subsequent_date, 2, f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
JOIN patstat2022a.dbo.temp t ON (t1.appln_id = t.appln_id )
JOIN patstat2022a.dbo.tls207_pers_appln t2 ON (t.subsequent_id = t2.appln_id)
ORDER BY t1.appln_id, t.subsequent_date, t2.person_id, applt_seq_nr, invt_seq_nr ASC;

DROP INDEX IF EXISTS dbo.subsequent_filings1_app.sec1_idx, 
dbo.subsequent_filings1_app.sec1_sub_idx, 
dbo.subsequent_filings1_app.sec1_sub_pers_idx,
dbo.subsequent_filings1_app.sec1_office_idx,
dbo.subsequent_filings1_app.sec1_year_idx, 
dbo.subsequent_filings1_app.sec1_nb_prior_idx, 
dbo.subsequent_filings1_app.sec1_applt_idx, 
dbo.subsequent_filings1_app.sec1_invt_idx;		

CREATE CLUSTERED INDEX [sec1_idx] ON [patstat2022a].[dbo].[subsequent_filings1_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO      

CREATE INDEX [sec1_sub_idx] ON [patstat2022a].[dbo].[subsequent_filings1_app]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO   

CREATE INDEX [sec1_sub_pers_idx] ON [patstat2022a].[dbo].[subsequent_filings1_app]
(
   [subsequent_person_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [sec1_office_idx] ON [patstat2022a].[dbo].[subsequent_filings1_app]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [sec1_year_idx] ON [patstat2022a].[dbo].[subsequent_filings1_app]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [sec1_nb_prior_idx] ON [patstat2022a].[dbo].[subsequent_filings1_app]
(
   [nb_priorities] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [sec1_applt_idx] ON [patstat2022a].[dbo].[subsequent_filings1_app]
(
   [applt_seq_nr] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [sec1_invt_idx] ON [patstat2022a].[dbo].[subsequent_filings1_app]
(
   [invt_seq_nr] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

DROP TABLE patstat2022a.dbo.temp;










-- B.1 Information from equivalents (source = 2)
-- B.1.1 Find all the relevant information
-- Table: EQUIVALENTS2_app

DROP TABLE IF EXISTS patstat2022a.dbo.EQUIVALENTS2_app;

CREATE  TABLE patstat2022a.dbo.EQUIVALENTS2_app(
appln_id INT,
subsequent_id INT,
subsequent_person_id INT,
subsequent_date DATE,
patent_office VARCHAR(2),
appln_filing_year INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX)
)

INSERT INTO patstat2022a.dbo.EQUIVALENTS2_app
-- 34697859 rows affected
SELECT t1.appln_id,  t1.subsequent_id, t1.subsequent_person_id, t1.subsequent_date, t1.patent_office, t1.appln_filing_year, ctry_code, f_type
FROM patstat2022a.dbo.SUBSEQUENT_FILINGS1_app t1 
JOIN patstat2022a.dbo.country_codes_app t2 ON (t1.subsequent_id = t2.appln_id and t1.subsequent_person_id = t2.person_id)
WHERE t1.nb_priorities = 1 AND applt_seq_nr >0 AND NULLIF(ctry_code, '') IS NOT NULL ;

DROP INDEX IF EXISTS dbo.EQUIVALENTS2_app.equ2_idx, 
dbo.EQUIVALENTS2_app.equ2_sub_idx, 
dbo.EQUIVALENTS2_app.equ2_pers_idx, 
dbo.EQUIVALENTS2_app.equ2_office_idx, 
dbo.EQUIVALENTS2_app.equ2_year_idx;

CREATE CLUSTERED INDEX [equ2_idx] ON [patstat2022a].[dbo].[EQUIVALENTS2_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [equ2_sub_idx] ON [patstat2022a].[dbo].[EQUIVALENTS2_app]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [equ2_sub_pers_idx] ON [patstat2022a].[dbo].[EQUIVALENTS2_app]
(
   [subsequent_person_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [equ2_office_idx] ON [patstat2022a].[dbo].[EQUIVALENTS2_app]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [equ2_year_idx] ON [patstat2022a].[dbo].[EQUIVALENTS2_app]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 








-- B.1.2 Select the most appropriate (i.e. earliest) equivalent
-- Table: EARLIEST_EQUIVALENT2_app

DROP TABLE IF EXISTS patstat2022a.dbo.EARLIEST_EQUIVALENT2_app;

CREATE  TABLE patstat2022a.dbo.EARLIEST_EQUIVALENT2_app(
appln_id INT,
subsequent_id INT,
subsequent_person_id INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX),
min_subsequent_date DATE
) 

INSERT INTO patstat2022a.dbo.EARLIEST_EQUIVALENT2_app
-- 26402776 rows affected
SELECT t1.appln_id, subsequent_id, subsequent_person_id, ctry_code, f_type, min_subsequent_date
FROM patstat2022a.dbo.EQUIVALENTS2_app t1
JOIN (SELECT appln_id, min(subsequent_date) AS min_subsequent_date
FROM patstat2022a.dbo.EQUIVALENTS2_app
GROUP BY appln_id) AS t2 ON (t1.appln_id = t2.appln_id AND t1.subsequent_date = t2.min_subsequent_date);

DROP INDEX IF EXISTS dbo.EARLIEST_EQUIVALENT2_app.eequ2_idx, 
dbo.EARLIEST_EQUIVALENT2_app.eequ2_sub_idx, 
dbo.EARLIEST_EQUIVALENT2_app.eequ2_sub_pers_idx;

CREATE CLUSTERED INDEX [eequ2_idx] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT2_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO   

CREATE INDEX [eequ2_sub_idx] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT2_app]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO   

CREATE INDEX [eequ2_sub_pers_idx] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT2_app]
(
   [subsequent_person_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


-- Table: EARLIEST_EQUIVALENT2_app_
-- deal with cases where we have several earliest equivalents (select only one)
DROP TABLE IF EXISTS patstat2022a.dbo.EARLIEST_EQUIVALENT2_app_;

CREATE TABLE patstat2022a.dbo.EARLIEST_EQUIVALENT2_app_(
appln_id INT,
subsequent_id INT,
subsequent_person_id INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX),
min_subsequent_date DATE
) 

INSERT INTO patstat2022a.dbo.EARLIEST_EQUIVALENT2_app_
-- 15307921 rows affected
SELECT t1.* FROM patstat2022a.dbo.EARLIEST_EQUIVALENT2_app t1 JOIN 
(SELECT appln_id, min(subsequent_id) as min_subsequent_id
FROM patstat2022a.dbo.EARLIEST_EQUIVALENT2_app
GROUP BY appln_id) AS t2
ON (t1.appln_id = t2.appln_id AND t1.subsequent_id = t2.min_subsequent_id);

DROP INDEX IF EXISTS dbo.EARLIEST_EQUIVALENT2_app_.eequ2_idx_, 
dbo.EARLIEST_EQUIVALENT2_app_.eequ2_sub_idx_, 
dbo.EARLIEST_EQUIVALENT2_app_.eequ2_sub_pers_idx_;

CREATE CLUSTERED INDEX [eequ2_idx_] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT2_app_]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [eequ2_sub_idx_] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT2_app_]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [eequ2_sub_pers_idx_] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT2_app_]
(
   [subsequent_person_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO









-- B.2 Information from other subsequent filings (source = 3)
-- B.2.1 Find information on applicants from subsequent filings for patents that have not yet been identified via their potential equivalent(s)
-- Table: OTHER_SUBSEQUENT_FILINGS3_app

DROP TABLE IF EXISTS patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS3_app;

CREATE  TABLE patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS3_app(
appln_id INT,
subsequent_id INT,
subsequent_person_id INT,
subsequent_date DATE,
patent_office VARCHAR(2),
appln_filing_year INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX)
) 

INSERT INTO patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS3_app
-- 16245083 rows affected
SELECT t1.appln_id,  t1.subsequent_id, t1.subsequent_person_id, t1.subsequent_date, t1.patent_office, t1.appln_filing_year, ctry_code, f_type
FROM patstat2022a.dbo.SUBSEQUENT_FILINGS1_app t1 
JOIN patstat2022a.dbo.country_codes_app t2 ON (t1.subsequent_id = t2.appln_id and t1.subsequent_person_id = t2.person_id)
WHERE t1.nb_priorities > 1 AND applt_seq_nr >0 AND NULLIF(ctry_code, '') IS NOT NULL;

DROP INDEX IF EXISTS dbo.OTHER_SUBSEQUENT_FILINGS3_app.other3_idx, 
dbo.OTHER_SUBSEQUENT_FILINGS3_app.other3_sub_idx, 
dbo.OTHER_SUBSEQUENT_FILINGS3_app.other3_office_idy, 
dbo.OTHER_SUBSEQUENT_FILINGS3_app.other3_year_idx;

CREATE CLUSTERED INDEX [other3_idx] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS3_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [other3_sub_idx] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS3_app]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [other3_sub_pers_idx] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS3_app]
(
   [subsequent_person_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [other3_office_idx] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS3_app]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [other3_year_idx] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS3_app]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO










-- B.2.2 Select the most appropriate (i.e. earliest) subsequent filing
-- Table: EARLIEST_SUBSEQUENT_FILING3_app

DROP TABLE IF EXISTS patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_app;

CREATE  TABLE patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_app(
appln_id INT,
subsequent_id INT,
subsequent_person_id INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX),
min_subsequent_date DATE
) 

INSERT INTO patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_app
-- 11243826 rows affected
SELECT t1.appln_id, subsequent_id, subsequent_person_id, ctry_code, f_type, min_subsequent_date
FROM patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS3_app t1
JOIN (SELECT appln_id, min(subsequent_date) AS min_subsequent_date
FROM patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS3_app
GROUP BY appln_id) AS t2 ON (t1.appln_id = t2.appln_id AND t1.subsequent_date = t2.min_subsequent_date);

DROP INDEX IF EXISTS dbo.EARLIEST_SUBSEQUENT_FILING3_app.esub3_idx, 
dbo.EARLIEST_SUBSEQUENT_FILING3_app.esub3_sub_idx, 
dbo.EARLIEST_SUBSEQUENT_FILING3_app.esub3_sub_pers_idx;

CREATE CLUSTERED INDEX [esub3_idx] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING3_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [esub3_sub_idx] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING3_app]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [esub3_sub_pers_idx] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING3_app]
(
   [subsequent_person_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 


-- Table: EARLIEST_SUBSEQUENT_FILING3_app_
-- deal with cases where we have several earliest equivalents (select only one)

DROP TABLE IF EXISTS patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_app_;

CREATE TABLE patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_app_(
appln_id INT,
subsequent_id INT,
subsequent_person_id INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX),
min_subsequent_date DATE
) 

INSERT INTO patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_app_
-- 6212402 rows affected
SELECT t1.* FROM patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_app t1 JOIN 
(SELECT appln_id, min(subsequent_id) as min_subsequent_id
FROM patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_app
GROUP BY appln_id) AS t2 
ON (t1.appln_id = t2.appln_id AND t1.subsequent_id = t2.min_subsequent_id);

DROP INDEX IF EXISTS dbo.EARLIEST_SUBSEQUENT_FILING3_app_.esub3_idx_,
dbo.EARLIEST_SUBSEQUENT_FILING3_app_.esub3_sub_idx_, 
dbo.EARLIEST_SUBSEQUENT_FILING3_app_.esub3_sub_pers_idx_;

CREATE CLUSTERED INDEX [esub3_idx_] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING3_app_]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [esub3_sub_idx_] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING3_app_]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [esub3_sub_pers_idx_] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING3_app_]
(
   [subsequent_person_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 










-- 1.2 Inventor information
-- C. Information that is directly available (source = 4)
-- Table: PRIORITY_FILINGS4_app

DROP TABLE IF EXISTS patstat2022a.dbo.PRIORITY_FILINGS4_app;

CREATE TABLE patstat2022a.dbo.PRIORITY_FILINGS4_app(
appln_id INT,
patent_office VARCHAR(2),
appln_filing_year INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX)
)

INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS4_app
-- 16139527 rows affected
SELECT DISTINCT t1.appln_id, t1.patent_office, t1.appln_filing_year, ctry_code, f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS_app t1 
JOIN patstat2022a.dbo.country_codes_inv t2 ON (t1.appln_id = t2.appln_id)
WHERE NULLIF(t2.ctry_code, '') IS NOT NULL;

DROP INDEX IF EXISTS dbo.PRIORITY_FILINGS4_app.pri4_idx, 
dbo.PRIORITY_FILINGS4_app.pri4_office_idx, 
dbo.PRIORITY_FILINGS4_app.pri4_year_idx;

CREATE CLUSTERED INDEX [pri4_idx] ON [patstat2022a].[dbo].[PRIORITY_FILINGS4_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [pri4_office_idx] ON [patstat2022a].[dbo].[PRIORITY_FILINGS4_app]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [pri4_year_idx] ON [patstat2022a].[dbo].[PRIORITY_FILINGS4_app]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO







-- D.1 Use information from equivalents (source = 5)
-- D.1.1 Find all the relevant information
-- Table: EQUIVALENTS5_app

DROP TABLE IF EXISTS patstat2022a.dbo.EQUIVALENTS5_app;

CREATE  TABLE patstat2022a.dbo.EQUIVALENTS5_app(
appln_id INT,
subsequent_id INT,
subsequent_date DATE,
patent_office VARCHAR(2),
appln_filing_year INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX)
)

INSERT INTO patstat2022a.dbo.EQUIVALENTS5_app
-- 204158933 rows affected
SELECT  t1.appln_id, t1.subsequent_id, t1.subsequent_date, t1.patent_office, t1.appln_filing_year, ctry_code, f_type
FROM patstat2022a.dbo.SUBSEQUENT_FILINGS1_app t1 
JOIN patstat2022a.dbo.country_codes_inv t2 ON (t1.subsequent_id = t2.appln_id)
WHERE t1.nb_priorities = 1  AND invt_seq_nr > 0 AND NULLIF(ctry_code, '') IS NOT NULL;

DROP INDEX IF EXISTS dbo.EQUIVALENTS5_app.equ5_idx, 
dbo.EQUIVALENTS5_app.equ5_sub_idx, 
dbo.EQUIVALENTS5_app.equ5_office_idx, 
dbo.EQUIVALENTS5_app.equ5_year_idx;

CREATE CLUSTERED INDEX [equ5_idx] ON [patstat2022a].[dbo].[EQUIVALENTS5_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [equ5_sub_idx] ON [patstat2022a].[dbo].[EQUIVALENTS5_app]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [equ5_office_idx] ON [patstat2022a].[dbo].[EQUIVALENTS5_app]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [equ5_year_idx] ON [patstat2022a].[dbo].[EQUIVALENTS5_app]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO










-- D.1.2 Select the most appropriate (i.e. earliest) equivalent
-- Table: EARLIEST_EQUIVALENT5_app

DROP TABLE IF EXISTS patstat2022a.dbo.EARLIEST_EQUIVALENT5_app;

CREATE  TABLE patstat2022a.dbo.EARLIEST_EQUIVALENT5_app(
appln_id INT,
subsequent_id INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX),
min_subsequent_date DATE
) 

INSERT INTO patstat2022a.dbo.EARLIEST_EQUIVALENT5_app
-- 156694619 rows affected
SELECT t1.appln_id, subsequent_id, ctry_code, f_type, min_subsequent_date
FROM patstat2022a.dbo.EQUIVALENTS5_app t1
JOIN (SELECT appln_id, min(subsequent_date) AS min_subsequent_date
FROM patstat2022a.dbo.EQUIVALENTS5_app
GROUP BY appln_id) AS t2 ON (t1.appln_id = t2.appln_id AND t1.subsequent_date = t2.min_subsequent_date);




DROP INDEX IF EXISTS dbo.EARLIEST_EQUIVALENT5_app.eequ5_idx, 
dbo.EARLIEST_EQUIVALENT5_app.eequ5_sub_idx;

CREATE CLUSTERED INDEX [eequ5_idx] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT5_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [eequ5_sub_idx] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT5_app]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 


-- Table: EARLIEST_EQUIVALENT5_app_ 
-- deal with cases where we have several earliest equivalents (select only one)

DROP TABLE IF EXISTS patstat2022a.dbo.EARLIEST_EQUIVALENT5_app_;

CREATE TABLE patstat2022a.dbo.EARLIEST_EQUIVALENT5_app_(
appln_id INT,
subsequent_id INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX),
min_subsequent_date DATE
) 

INSERT INTO patstat2022a.dbo.EARLIEST_EQUIVALENT5_app_
-- 88710085 rows affected
SELECT t1.* FROM patstat2022a.dbo.EARLIEST_EQUIVALENT5_app t1 JOIN 
(SELECT appln_id, min(subsequent_id) as min_subsequent_id
FROM patstat2022a.dbo.EARLIEST_EQUIVALENT5_app
GROUP BY appln_id) AS t2
ON (t1.appln_id = t2.appln_id AND t1.subsequent_id = t2.min_subsequent_id);

DROP INDEX IF EXISTS dbo.EARLIEST_EQUIVALENT5_app_.eequ5_idx_, 
dbo.EARLIEST_EQUIVALENT5_app_.eequ5_sub_idx_;

CREATE CLUSTERED INDEX [eequ5_idx_] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT5_app_]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [eequ5_sub_idx_] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT5_app_]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 







-- D.2 Use information from other subsequent filings (source = 6)
-- D.2.1 Find information on inventors from subsequent filings for patents that have not yet been identified via their potential equivalents
-- Table: OTHER_SUBSEQUENT_FILINGS6_app

DROP TABLE IF EXISTS patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS6_app;

CREATE TABLE patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS6_app(
appln_id INT,
subsequent_id INT,
subsequent_date DATE,
patent_office VARCHAR(2),
appln_filing_year INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX)
) 

INSERT INTO patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS6_app
-- 159665216 rows affected
SELECT  t1.appln_id, t1.subsequent_id, t1.subsequent_date, t1.patent_office, t1.appln_filing_year, ctry_code, f_type 
FROM patstat2022a.dbo.SUBSEQUENT_FILINGS1_app t1 
JOIN patstat2022a.dbo.country_codes_inv t2 ON (t1.subsequent_id = t2.appln_id)
WHERE t1.nb_priorities > 1  AND invt_seq_nr > 0 AND NULLIF(ctry_code, '') IS NOT NULL;

DROP INDEX IF EXISTS dbo.OTHER_SUBSEQUENT_FILINGS6_app.other6_idx, 
dbo.OTHER_SUBSEQUENT_FILINGS6_app.other6_sub_idx, 
dbo.OTHER_SUBSEQUENT_FILINGS6_app.other6_office_idx, 
dbo.OTHER_SUBSEQUENT_FILINGS6_app.other6_year_idx, 
dbo.OTHER_SUBSEQUENT_FILINGS6_app.other6_sub_pers_idx;

CREATE CLUSTERED INDEX [other6_idx] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS6_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [other6_sub_idx] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS6_app]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [other6_office_idx] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS6_app]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [other6_year_idx] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS6_app]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 









-- D.2.2 Select the most appropriate (i.e. earliest) subsequent filing
-- Table: EARLIEST_SUBSEQUENT_FILING6_app

DROP TABLE IF EXISTS patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING6_app;

CREATE  TABLE patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING6_app(
appln_id INT,
subsequent_id INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX),
min_subsequent_date DATE
) 

INSERT INTO patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING6_app
-- 103413162 rows affected
SELECT t1.appln_id, subsequent_id, ctry_code, f_type, min_subsequent_date
FROM patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS6_app t1
JOIN (SELECT appln_id, min(subsequent_date) AS min_subsequent_date
FROM patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS6_app
GROUP BY appln_id) AS t2 ON (t1.appln_id = t2.appln_id AND t1.subsequent_date = t2.min_subsequent_date);

DROP INDEX IF EXISTS dbo.EARLIEST_SUBSEQUENT_FILING6_app.esub6_idx, 
dbo.EARLIEST_SUBSEQUENT_FILING6_app.esub6_sub_idx;

CREATE CLUSTERED INDEX [esub6_idx] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING6_app]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [esub6_sub_idx] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING6_app]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 


-- Table: EARLIEST_SUBSEQUENT_FILING6_app_
-- deal with cases where we have several earliest equivalents (select only one)

DROP TABLE IF EXISTS patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING6_app_;

CREATE TABLE patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING6_app_(
appln_id INT,
subsequent_id INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX),
min_subsequent_date DATE
) 

INSERT INTO patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING6_app_
-- 52532301 rows affected
SELECT t1.* FROM patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING6_app t1 JOIN 
(SELECT appln_id, min(subsequent_id) as min_subsequent_id
FROM patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING6_app
GROUP BY appln_id) AS t2
ON (t1.appln_id = t2.appln_id AND t1.subsequent_id = t2.min_subsequent_id);

DROP INDEX IF EXISTS dbo.EARLIEST_SUBSEQUENT_FILING6_app_.esub6_idx_, 
dbo.EARLIEST_SUBSEQUENT_FILING6_app_.esub6_sub_idx_;

CREATE CLUSTERED INDEX [esub6_idx_] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING6_app_]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [esub6_sub_idx_] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING6_app_]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 








-- D.3 table containing the information on priority filings and country information if available for priority filing
-- Table: TABLE_APP

DROP TABLE IF EXISTS patstat2022a.dbo.TABLE_APP;

CREATE TABLE patstat2022a.dbo.TABLE_APP(
appln_id INT,
person_id INT,
patent_office VARCHAR(2),
appln_filing_date DATE,
appln_filing_year INT,
ctry_code CHAR(2),
f_type VARCHAR(MAX)
)

INSERT INTO patstat2022a.dbo.TABLE_APP
-- 70878643 rows affected
SELECT * FROM patstat2022a.dbo.priority_filings1_app; 

CREATE CLUSTERED INDEX [TABLE_APP_APPLN_ID] ON [patstat2022a].[dbo].[TABLE_APP]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [TABLE_APP_PERSON_ID] ON [patstat2022a].[dbo].[TABLE_APP]
(
   [person_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


-- Table: TABLE_TO_BE_FILLED_APP

DROP TABLE IF EXISTS patstat2022a.dbo.TABLE_TO_BE_FILLED_APP;

CREATE  TABLE patstat2022a.dbo.TABLE_TO_BE_FILLED_APP(
appln_id INTEGER DEFAULT NULL,
person_id INTEGER DEFAULT NULL,
ctry_code VARCHAR(2) DEFAULT NULL,
f_source SMALLINT DEFAULT NULL,
f_type TEXT DEFAULT NULL
);










----------------------------------
----- Step 2: MAIN PROCEDURE -----
----------------------------------

-- A. Insert information that is directly available (source = 1)
-- Table: TABLE_TO_BE_FILLED_APP

INSERT INTO patstat2022a.dbo.TABLE_TO_BE_FILLED_APP
-- 22756915 rows affected
SELECT  t_.appln_id, t_.person_id, ctry_code, 1, f_type
FROM patstat2022a.dbo.TABLE_APP t_
WHERE NULLIF(t_.ctry_code, '') IS NOT NULL;

CREATE CLUSTERED INDEX [TABLE_TO_BE_FILLED_APP_appln_id] ON [patstat2022a].[dbo].[TABLE_TO_BE_FILLED_APP]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  







-- A.2 delete information that has been added

DELETE 
-- 22847339 rows affected
FROM 
	patstat2022a.dbo.TABLE_APP 
WHERE appln_id IN (SELECT appln_id FROM patstat2022a.dbo.TABLE_TO_BE_FILLED_APP);   






-- B.1 Add the information from each selected equivalent
INSERT INTO patstat2022a.dbo.TABLE_TO_BE_FILLED_APP
-- 5736054 rows affected
SELECT t_.appln_id, t_.subsequent_person_id, t_.ctry_code, 2, t_.f_type
FROM (
SELECT t1.appln_id, t1.subsequent_person_id, ctry_code, f_type
FROM patstat2022a.dbo.EARLIEST_EQUIVALENT2_APP_ t1
JOIN (
SELECT DISTINCT appln_id FROM
patstat2022a.dbo.TABLE_APP) AS t2
ON t1.appln_id = t2.appln_id 
WHERE NULLIF(t1.ctry_code, '') IS NOT NULL) AS t_;
 
DELETE 
-- 2315407 rows affected
FROM patstat2022a.dbo.TABLE_APP
WHERE appln_id IN (SELECT appln_id FROM patstat2022a.dbo.TABLE_TO_BE_FILLED_APP);   









-- B.2 Add the information from each selected subsequent filing
INSERT INTO patstat2022a.dbo.TABLE_TO_BE_FILLED_APP
-- 1907676 rows affected
SELECT
t_.appln_id,
t_.subsequent_person_id,
t_.ctry_code,
3,
t_.f_type 
FROM (
SELECT t1.appln_id, t1.subsequent_person_id, ctry_code, f_type
FROM patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_APP_ t1
JOIN (
SELECT DISTINCT appln_id FROM
patstat2022a.dbo.TABLE_APP) AS t2
ON t1.appln_id = t2.appln_id 
WHERE NULLIF(t1.ctry_code, '') IS NOT NULL 
) AS t_
;
 
DELETE 
-- 780179 rows affected
FROM patstat2022a.dbo.TABLE_APP
WHERE appln_id IN (SELECT appln_id FROM patstat2022a.dbo.TABLE_TO_BE_FILLED_APP);  











-- Take information from applicants to recover missing information 
-- C Insert information that is directly available (source = 4)

INSERT INTO patstat2022a.dbo.TABLE_TO_BE_FILLED_APP
-- 214456 rows affected
SELECT
t_.appln_id,
0,
t_.ctry_code,
4,
t_.f_type
FROM (
SELECT t1.appln_id, ctry_code, f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS4_APP t1
JOIN (
SELECT DISTINCT appln_id FROM
patstat2022a.dbo.TABLE_APP) AS t2
ON t1.appln_id = t2.appln_id 
WHERE NULLIF(t1.ctry_code, '') IS NOT NULL 
) AS t_
;
 
DELETE 
-- 296854 rows affected
FROM patstat2022a.dbo.TABLE_APP WHERE appln_id IN (SELECT appln_id FROM patstat2022a.dbo.TABLE_TO_BE_FILLED_APP);  







-- D.1 Add the information from each selected equivalent
INSERT INTO patstat2022a.dbo.TABLE_TO_BE_FILLED_APP
-- 248981 rows affected
SELECT
t_.appln_id,
0,
t_.ctry_code,
5,
t_.f_type   
FROM (
SELECT t1.appln_id, ctry_code, f_type
FROM patstat2022a.dbo.EARLIEST_EQUIVALENT5_APP_ t1
JOIN (
SELECT DISTINCT appln_id FROM
patstat2022a.dbo.TABLE_APP) AS t2
ON t1.appln_id = t2.appln_id 
WHERE NULLIF(t1.ctry_code, '') IS NOT NULL 
) AS t_
;
 
DELETE
-- 19629 rows affected
FROM patstat2022a.dbo.TABLE_APP WHERE appln_id IN (SELECT appln_id FROM patstat2022a.dbo.TABLE_TO_BE_FILLED_APP);  










-- D.2 Add the information from each selected subsequent filing
INSERT INTO patstat2022a.dbo.TABLE_TO_BE_FILLED_APP
-- 101368 rows affected
SELECT
t_.appln_id,
0,
t_.ctry_code,
6,
t_.f_type
FROM (
SELECT t1.appln_id, ctry_code, f_type
FROM patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING6_APP_ t1
JOIN (
SELECT DISTINCT appln_id FROM
patstat2022a.dbo.TABLE_APP) AS t2
ON t1.appln_id = t2.appln_id 
WHERE NULLIF(t1.ctry_code, '') IS NOT NULL 
) AS t_
;
 
DELETE
-- 5001 rows affected
FROM patstat2022a.dbo.TABLE_APP WHERE appln_id IN (SELECT appln_id FROM patstat2022a.dbo.TABLE_TO_BE_FILLED_APP);









-- E. If country code is still missing, set it equal to a filing's patent office
-- E.1 Table with location information from all possible sources

-- APPLN_KIND = 'W'
INSERT INTO patstat2022a.dbo.TABLE_TO_BE_FILLED_APP
-- 140 rows affected
SELECT
t_.appln_id,
0,
t_.receiving_office,
7,
t_.f_type
FROM (
SELECT t1.appln_id, receiving_office, f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS_APP t1 
JOIN (
SELECT DISTINCT appln_id FROM
patstat2022a.dbo.TABLE_APP) AS t2
ON (t1.appln_id = t2.appln_id)
JOIN (
SELECT DISTINCT appln_id, receiving_office FROM
patstat2022a.dbo.tls201_appln) AS t3
ON (t2.appln_id = t3.appln_id) 
WHERE receiving_office NOT IN ('EP', 'AP', 'EA', 'GC', 'OA', 'WO') 
AND t1.appln_kind = 'W'
) AS t_;

DELETE
-- 140 rows affected
FROM patstat2022a.dbo.TABLE_APP WHERE appln_id IN (SELECT appln_id FROM patstat2022a.dbo.TABLE_TO_BE_FILLED_APP);


-- APPLN_KIND != 'W'
INSERT INTO patstat2022a.dbo.TABLE_TO_BE_FILLED_APP
-- 44614088 rows affected
SELECT
t_.appln_id,
0,
t_.patent_office,
7,
t_.f_type
FROM (
SELECT t1.appln_id, patent_office, f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS_APP t1 
JOIN (
SELECT DISTINCT appln_id FROM
patstat2022a.dbo.TABLE_APP) AS t2
ON (t1.appln_id = t2.appln_id) 
WHERE patent_office NOT IN ('EP', 'AP', 'EA', 'GC', 'OA', 'WO')
AND t1.appln_kind != 'W'
) AS t_;

DELETE
-- 44614088 rows affected
FROM patstat2022a.dbo.TABLE_APP WHERE appln_id IN (SELECT appln_id FROM patstat2022a.dbo.TABLE_TO_BE_FILLED_APP);








-- E.2 Table: PF_APP_PERS_CTRY_ALL
-- Table with location information from all possible sources

DROP TABLE IF EXISTS patstat2022a.dbo.PF_APP_PERS_CTRY_ALL;

CREATE TABLE patstat2022a.dbo.PF_APP_PERS_CTRY_ALL (
appln_id INT DEFAULT NULL,
appln_kind CHAR(2) DEFAULT NULL,
person_id INT DEFAULT NULL,
patent_office VARCHAR(2) DEFAULT NULL,
priority_date date DEFAULT NULL,
priority_year INT DEFAULT NULL,
ctry_code CHAR(2) DEFAULT NULL,
f_source INT DEFAULT NULL,
f_type VARCHAR(MAX) 
); -- COMMENT ON TABLE PF_APP_PERS_CTRY_ALL IS 'Applicants from priority filings of a given (po, year)';











-- F. Job done, insert into final table 
INSERT INTO patstat2022a.dbo.PF_APP_PERS_CTRY_ALL
-- 75579678 rows affected
SELECT t1.appln_id, t2.appln_kind, t1.person_id, t2.patent_office, t2.appln_filing_date, t2.appln_filing_year, ctry_code, f_source, f_type
FROM patstat2022a.dbo.TABLE_TO_BE_FILLED_APP t1 JOIN (
SELECT DISTINCT appln_id, appln_kind, patent_office, appln_filing_date, appln_filing_year FROM patstat2022a.dbo.PRIORITY_FILINGS_APP) AS t2 ON t1.appln_id = t2.appln_id;

CREATE CLUSTERED INDEX [PF_APP_PERS_CTRY_ALL_APPLN_ID] ON [patstat2022a].[dbo].[PF_APP_PERS_CTRY_ALL]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [PF_APP_PERS_CTRY_ALL_PERS_ID] ON [patstat2022a].[dbo].[PF_APP_PERS_CTRY_ALL]
(
   [person_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [PF_APP_PERS_CTRY_ALL_YEAR] ON [patstat2022a].[dbo].[PF_APP_PERS_CTRY_ALL]
(
   [priority_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 








