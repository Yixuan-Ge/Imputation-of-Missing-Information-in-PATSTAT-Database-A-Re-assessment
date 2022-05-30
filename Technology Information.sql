




--------------------------------------------
----- Step 0: CREATE ALL TABLES NEEDED -----
--------------------------------------------

USE [patstat2022a]
GO

SET ANSI_WARNINGS OFF;

-- 0.1 table containing the patent offices to browse
-- Table: po
DROP TABLE IF EXISTS patstat2022a.dbo.po;

CREATE TABLE patstat2022a.dbo.po (
patent_office CHAR(2) DEFAULT NULL
);  -- COMMENT ON TABLE po IS 'List of patent offices to browse';

INSERT INTO patstat2022a.dbo.po VALUES ('AL'), ('AT'), ('AU'), ('BE'), ('BG'),('BR'), ('CA'), ('CH'), ('CL'), ('CN'),('CY'), ('CZ'), ('DE'), ('DK'), ('EE'), ('EP'), ('ES'), ('FI'), ('FR'), ('GB'), ('GR'), ('HR'), ('HU'),('IB'), ('IE'), ('IL'), ('IN'), ('IS'), ('IT'), ('JP'), ('KR'), ('LT'), ('LU'), ('LV'), ('MK'), ('MT'), ('MX'), ('NL'), ('NO'), ('NZ'), ('PL'), ('PT'), ('RO'), ('RS'), ('RU'), ('SE'), ('SI'), ('SK'), ('SM'), ('TR'), ('US'), ('ZA');
DROP INDEX IF EXISTS po.po_idx;

CREATE UNIQUE CLUSTERED INDEX [po_idx] ON [patstat2022a].[dbo].[po]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


-- 0.2 table containing the appln_id to exclude from the analysis (e.g. petty patents) for a given patent office
--Table: toExclude
--DROP TABLE IF EXISTS patstat2022a.dbo.toExclude;

--CREATE TABLE patstat2022a.dbo.toExclude (
--appln_id INT,
--publn_auth CHAR(2),
--publn_kind CHAR(2)
--);

--INSERT INTO patstat2022a.dbo.toExclude
-- 157509 rows affected
--SELECT DISTINCT appln_id, publn_auth, publn_kind FROM patstat2022a.dbo.tls211_pat_publn
--WHERE 
--(publn_auth='AU' AND (publn_kind='A3' OR publn_kind='B3' OR publn_kind='B4' OR publn_kind='C1'
--OR publn_kind='C4' OR publn_kind='D0'))
--OR 
--(publn_auth='BE' AND (publn_kind='A6' OR publn_kind='A7'))
--OR 
--(publn_auth='FR' AND (publn_kind='A3' OR publn_kind='A4' OR publn_kind='A7'))
--OR
--(publn_auth='IE' AND (publn_kind='A2' OR publn_kind='B2'))
--OR
--(publn_auth='NL' AND publn_kind='C1')
--OR 
--(publn_auth='SI' AND publn_kind='A2')
--OR
--(publn_auth='US' AND (publn_kind='E' OR publn_kind='E1' OR publn_kind='H' OR publn_kind='H1' OR publn_kind='I4' 
--OR publn_kind='P' OR publn_kind='P1' OR publn_kind='P2' OR publn_kind='P3' OR publn_kind='S1'))
--;  -- COMMENT ON TABLE toExclude IS 'Excluded appln_id for a given po based on publn_kind';

--DROP INDEX IF EXISTS toExclude.exclude_idx;

--CREATE UNIQUE CLUSTERED INDEX [exclude_idx] ON [patstat2022a].[dbo].[toExclude]
--(
--   [appln_id] ASC
--)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
--GO



-- 1. Table containing the priority filings of a given (patent office, year)
-- Table: PRIORITY_FILINGS
DROP TABLE IF EXISTS patstat2022a.dbo.PRIORITY_FILINGS;

CREATE TABLE patstat2022a.dbo.PRIORITY_FILINGS(
appln_id INT,
appln_kind CHAR,
patent_office VARCHAR(2),
appln_filing_year INT,
appln_filing_date DATE,
f_type VARCHAR(MAX)
);


-- priority (!= 'W')
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS
SELECT DISTINCT t1.appln_id, t1.appln_kind, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'priority'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.tls204_appln_prior t2 ON t1.appln_id = t2.prior_appln_id
--LEFT OUTER JOIN toExclude t3 ON t1.appln_id = t3.appln_id
--JOIN patstat2022a.dbo.tls211_pat_publn t4 ON t1.appln_id = t4.appln_id
JOIN patstat2022a.dbo.po t5 ON t1.appln_auth = t5.patent_office
WHERE (t1.appln_kind!= 'W')
AND t1.internat_appln_id = 0
--AND t3.appln_id IS NULL
--AND t4.publn_nr IS NOT NULL 
--AND t4.publn_kind !='D2'
--AND t1.appln_filing_year < 2023
;


-- priority (W)
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS
SELECT DISTINCT t1.appln_id, t1.appln_kind, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'priority'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.tls204_appln_prior t2 ON t1.appln_id = t2.prior_appln_id
--LEFT OUTER JOIN toExclude t3 ON t1.appln_id = t3.appln_id
--JOIN patstat2022a.dbo.tls211_pat_publn t4 ON t1.appln_id = t4.appln_id
JOIN patstat2022a.dbo.po t5 ON t1.receiving_office = t5.patent_office

--	LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind = 'W')
AND t1.internat_appln_id = 0
--AND t3.appln_id IS NULL
--AND t4.publn_nr IS NOT NULL 
--AND t4.publn_kind !='D2'
--AND t1.appln_filing_year < 2023
--AND t7.appln_id is null
;


-- pct (W)
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS
SELECT DISTINCT t1.appln_id, t1.appln_kind, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'pct'
FROM patstat2022a.dbo.tls201_appln t1 
--LEFT OUTER JOIN toExclude t3 ON t1.appln_id = t3.appln_id
--JOIN patstat2022a.dbo.tls211_pat_publn t4 ON t1.appln_id = t4.appln_id
JOIN po t5 ON t1.receiving_office = t5.patent_office

  LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind = 'W')
AND t1.internat_appln_id = 0 and nat_phase = 'N' and reg_phase = 'N'
AND t1.appln_id = t1.earliest_filing_id
--AND t3.appln_id IS NULL
--AND t4.publn_nr IS NOT NULL 
--AND t4.publn_kind !='D2'
-- AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;


-- continual (!= 'W')
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS
SELECT DISTINCT t1.appln_id, t1.appln_kind, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'continual'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.tls216_appln_contn t2 ON t1.appln_id = t2.parent_appln_id
--LEFT OUTER JOIN patstat2022a.dbo.toExclude t3 ON t1.appln_id = t3.appln_id
--JOIN patstat2022a.dbo.tls211_pat_publn t4 ON t1.appln_id = t4.appln_id
JOIN patstat2022a.dbo.po t5 ON t1.appln_auth = t5.patent_office

      LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind!= 'W')
AND t1.internat_appln_id = 0
--AND t3.appln_id IS NULL
--AND t4.publn_nr IS NOT NULL 
--AND t4.publn_kind !='D2'
--AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;

-- continual (W)
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS
SELECT DISTINCT t1.appln_id, t1.appln_kind, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'continual'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.tls216_appln_contn t2 ON t1.appln_id = t2.parent_appln_id
--LEFT OUTER JOIN patstat2022a.dbo.toExclude t3 ON t1.appln_id = t3.appln_id
--JOIN patstat2022a.dbo.tls211_pat_publn t4 ON t1.appln_id = t4.appln_id
JOIN patstat2022a.dbo.po t5 ON t1.receiving_office = t5.patent_office

      LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind = 'W')
AND t1.internat_appln_id = 0
--AND t3.appln_id IS NULL
--AND t4.publn_nr IS NOT NULL 
--AND t4.publn_kind !='D2'
--AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;


-- tech_rel (!= 'W')
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS
SELECT DISTINCT t1.appln_id, t1.appln_kind, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'tech_rel'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.tls205_tech_rel t2 ON t1.appln_id = t2.tech_rel_appln_id
--LEFT OUTER JOIN patstat2022a.dbo.toExclude t3 ON t1.appln_id = t3.appln_id
--JOIN patstat2022a.dbo.tls211_pat_publn t4 ON t1.appln_id = t4.appln_id
JOIN patstat2022a.dbo.po t5 ON t1.appln_auth = t5.patent_office

      LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind!= 'W')
AND t1.internat_appln_id = 0
--AND t3.appln_id IS NULL
--AND t4.publn_nr IS NOT NULL 
--AND t4.publn_kind !='D2'
--AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;


-- tech_rel(W)
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS
SELECT DISTINCT t1.appln_id, t1.appln_kind, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'tech_rel'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN patstat2022a.dbo.tls205_tech_rel t2 ON t1.appln_id = t2.tech_rel_appln_id
--LEFT OUTER JOIN patstat2022a.dbo.toExclude t3 ON t1.appln_id = t3.appln_id
--JOIN patstat2022a.dbo.tls211_pat_publn t4 ON t1.appln_id = t4.appln_id
JOIN patstat2022a.dbo.po t5 ON t1.receiving_office = t5.patent_office

      LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind = 'W')
AND t1.internat_appln_id = 0
--AND t3.appln_id IS NULL
--AND t4.publn_nr IS NOT NULL 
--AND t4.publn_kind !='D2'
--AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;


-- single (!= 'W')
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS
SELECT DISTINCT t1.appln_id, t1.appln_kind, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'single'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN (SELECT docdb_family_id from patstat2022a.dbo.tls201_appln group by docdb_family_id having count(distinct appln_id) = 1) as t2
ON t1.docdb_family_id = t2.docdb_family_id
--LEFT OUTER JOIN toExclude t3 ON t1.appln_id = t3.appln_id
--JOIN patstat2022a.dbo.tls211_pat_publn t4 ON t1.appln_id = t4.appln_id
JOIN patstat2022a.dbo.po t5 ON t1.appln_auth = t5.patent_office

      LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind!= 'W')
AND t1.internat_appln_id = 0
--AND t3.appln_id IS NULL
--AND t4.publn_nr IS NOT NULL 
--AND t4.publn_kind !='D2'
--AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;


-- single (W)
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS
SELECT DISTINCT t1.appln_id, t1.appln_kind, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'single'
FROM patstat2022a.dbo.tls201_appln t1 
JOIN (SELECT docdb_family_id from patstat2022a.dbo.tls201_appln group by docdb_family_id having count(distinct appln_id) = 1) as t2
ON t1.docdb_family_id = t2.docdb_family_id
--LEFT OUTER JOIN toExclude t3 ON t1.appln_id = t3.appln_id
--JOIN patstat2022a.dbo.tls211_pat_publn t4 ON t1.appln_id = t4.appln_id
JOIN patstat2022a.dbo.po t5 ON t1.receiving_office = t5.patent_office

      LEFT OUTER JOIN patstat2022a.dbo.PRIORITY_FILINGS t7 on t1.appln_id = t7.appln_id 

WHERE (t1.appln_kind = 'W')
AND t1.internat_appln_id = 0
--AND t3.appln_id IS NULL
--AND t4.publn_nr IS NOT NULL 
--AND t4.publn_kind !='D2'
--AND t1.appln_filing_year < 2023
AND t7.appln_id is null
;

DROP INDEX IF EXISTS dbo.PRIORITY_FILINGS.pf_idx, dbo.PRIORITY_FILINGS.pf_idx2, dbo.PRIORITY_FILINGS.pf_idx3;

CREATE CLUSTERED INDEX [pf_idx] ON [patstat2022a].[dbo].[PRIORITY_FILINGS]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [pf_idx2] ON [patstat2022a].[dbo].[PRIORITY_FILINGS]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [pf_idx3] ON [patstat2022a].[dbo].[PRIORITY_FILINGS]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

SET ANSI_WARNINGS ON;





-- 1.1 Applicant information

-- A. Information that is directly available (source = 1)
-- Table: PRIORITY_FILINGS1
DROP TABLE IF EXISTS patstat2022a.dbo.PRIORITY_FILINGS1_TECH;

CREATE TABLE patstat2022a.dbo.PRIORITY_FILINGS1_TECH(
appln_id INT,
appln_kind CHAR,
patent_office VARCHAR(2),
appln_filing_year INT,
appln_filing_date DATE,
techn_field_nr INT,
[weight] REAL,
f_type VARCHAR(MAX)
)


INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS1_TECH
-- first of all we need all priority filings with technology information in Patstat 
SELECT DISTINCT t1.appln_id, t1.appln_kind, t1.patent_office, t1.appln_filing_year, t1.appln_filing_date, t2.techn_field_nr, t2.[weight], t1.f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS t1 
JOIN patstat2022a.dbo.TLS230_APPLN_TECHN_FIELD t2 ON t1.appln_id = t2.appln_id;


--second, we need all priority filings without any technology information
INSERT INTO patstat2022a.dbo.PRIORITY_FILINGS1_TECH
SELECT DISTINCT t1.appln_id, t1.appln_kind, t1.patent_office, t1.appln_filing_year, t1.appln_filing_date, t2.techn_field_nr, t2.[weight], t1.f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS t1 
LEFT JOIN patstat2022a.dbo.TLS230_APPLN_TECHN_FIELD t2 ON t1.appln_id = t2.appln_id
WHERE t2.appln_id IS NULL;



DROP INDEX IF EXISTS dbo.PRIORITY_FILINGS1_TECH.pri1t_idx, dbo.PRIORITY_FILINGS1_TECH.pri1t_office_idx, dbo.PRIORITY_FILINGS1_TECH.pri1t_year;

CREATE CLUSTERED INDEX [pri1t_idx] ON [patstat2022a].[dbo].[PRIORITY_FILINGS1_TECH]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [pri1t_office_idx] ON [patstat2022a].[dbo].[PRIORITY_FILINGS1_TECH]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE INDEX [pri1t_year_idx] ON [patstat2022a].[dbo].[PRIORITY_FILINGS1_TECH]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO





-- B. Prepare a pool of all potential second filings
-- Table: SUBSEQUENT_FILINGS1_TECH


DROP TABLE IF EXISTS SUBSEQUENT_FILINGS1_TECH;

CREATE TABLE patstat2022a.dbo.SUBSEQUENT_FILINGS1_TECH(
appln_id INT,
appln_kind CHAR,
subsequent_id INT,
patent_office VARCHAR(2),
appln_filing_year INT,
appln_filing_date DATE,
subsequent_date DATE,
nb_priorities INT,
f_type VARCHAR(MAX)
)


-- priority
INSERT INTO patstat2022a.dbo.SUBSEQUENT_FILINGS1_TECH
SELECT DISTINCT t1.appln_id, t1.appln_kind, t.subsequent_id, t1.patent_office, t1.appln_filing_year, t1.appln_filing_date, 
t.subsequent_date, t.nb_priorities, t1.f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS1_TECH t1 
JOIN (SELECT t1.appln_id, t3.appln_id AS subsequent_id, t3.appln_filing_date AS subsequent_date, max(t4.prior_appln_seq_nr) AS nb_priorities
	  FROM patstat2022a.dbo.PRIORITY_FILINGS1_TECH t1 
	  INNER JOIN patstat2022a.dbo.tls204_appln_prior t2 ON t2.prior_appln_id = t1.appln_id
	  INNER JOIN patstat2022a.dbo.tls201_appln t3 ON t3.appln_id = t2.appln_id
	  INNER JOIN patstat2022a.dbo.tls204_appln_prior t4 ON t4.appln_id = t3.appln_id
    where f_type = 'priority'
      GROUP BY t1.appln_id, t3.appln_id, t3.appln_filing_date 	  
) AS t ON t1.appln_id = t.appln_id
ORDER BY t1.appln_id, t.subsequent_date ASC;


-- continual
INSERT INTO patstat2022a.dbo.SUBSEQUENT_FILINGS1_TECH
SELECT DISTINCT t1.appln_id, t1.appln_kind, t.subsequent_id, t1.patent_office, t1.appln_filing_year, t1.appln_filing_date, 
t.subsequent_date, t.nb_priorities, t1.f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS1_TECH t1 

JOIN (SELECT t1.appln_id, t3.appln_id AS subsequent_id, t3.appln_filing_date AS subsequent_date, max(t4.count_4) AS nb_priorities
	  FROM patstat2022a.dbo.PRIORITY_FILINGS1_TECH t1 
	  INNER JOIN patstat2022a.dbo.tls216_appln_contn t2 ON t2.parent_appln_id = t1.appln_id
	  INNER JOIN patstat2022a.dbo.tls201_appln t3 ON t3.appln_id = t2.appln_id
	  INNER JOIN  (select appln_id, count(*) AS count_4 from patstat2022a.dbo.tls216_appln_contn group by appln_id) as t4 ON t4.appln_id = t3.appln_id
    where f_type = 'continual'
      GROUP BY t1.appln_id, t3.appln_id, t3.appln_filing_date 	  
) AS t ON t1.appln_id = t.appln_id
ORDER BY t1.appln_id, t.subsequent_date ASC;


-- tech_rel
INSERT INTO patstat2022a.dbo.SUBSEQUENT_FILINGS1_TECH
SELECT DISTINCT t1.appln_id, t1.appln_kind, t.subsequent_id, t1.patent_office, t1.appln_filing_year, t1.appln_filing_date, 
t.subsequent_date, t.nb_priorities, t1.f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS1_TECH t1 

JOIN (SELECT t1.appln_id, t3.appln_id AS subsequent_id, t3.appln_filing_date AS subsequent_date, max(t4.count_5) AS nb_priorities
	  FROM patstat2022a.dbo.PRIORITY_FILINGS1_TECH t1 
	  INNER JOIN patstat2022a.dbo.TLS205_TECH_REL t2 ON t2.tech_rel_appln_id = t1.appln_id
	  INNER JOIN patstat2022a.dbo.tls201_appln t3 ON t3.appln_id = t2.appln_id
	  INNER JOIN  (select appln_id, count(*) AS count_5 from patstat2022a.dbo.TLS205_TECH_REL group by appln_id) as t4 ON t4.appln_id = t3.appln_id
    where f_type = 'tech_rel'
      GROUP BY t1.appln_id, t3.appln_id, t3.appln_filing_date 	  
) AS t ON t1.appln_id = t.appln_id
ORDER BY t1.appln_id, t.subsequent_date ASC;


-- pct
INSERT INTO patstat2022a.dbo.SUBSEQUENT_FILINGS1_TECH
SELECT DISTINCT t1.appln_id, t1.appln_kind, t.subsequent_id, t1.patent_office, t1.appln_filing_year, t1.appln_filing_date,
t.subsequent_date, 1, t1.f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS1_TECH t1 

JOIN (SELECT t1.appln_id, t2.appln_id AS subsequent_id, t2.appln_filing_date AS subsequent_date
	  FROM patstat2022a.dbo.PRIORITY_FILINGS1_TECH t1 
	  INNER JOIN patstat2022a.dbo.tls201_appln t2 ON t1.appln_id = t2.internat_appln_id
    where f_type = 'pct'
    AND t2.internat_appln_id != 0 and reg_phase = 'Y'
      GROUP BY t1.appln_id, t2.appln_id, t2.appln_filing_date 	  
) AS t ON t1.appln_id = t.appln_id
ORDER BY t1.appln_id, t.subsequent_date ASC;


-- pct
INSERT INTO patstat2022a.dbo.SUBSEQUENT_FILINGS1_TECH
SELECT DISTINCT t1.appln_id, t1.appln_kind, t.subsequent_id, t1.patent_office, t1.appln_filing_year, t1.appln_filing_date,
t.subsequent_date, 2, t1.f_type
FROM patstat2022a.dbo.PRIORITY_FILINGS1_TECH t1 

JOIN (SELECT t1.appln_id, t2.appln_id AS subsequent_id, t2.appln_filing_date AS subsequent_date
	  FROM patstat2022a.dbo.PRIORITY_FILINGS1_TECH t1 
	  INNER JOIN patstat2022a.dbo.tls201_appln t2 ON t1.appln_id = t2.internat_appln_id
    where f_type = 'pct'
    AND t2.internat_appln_id != 0 and nat_phase = 'Y'
      GROUP BY t1.appln_id, t2.appln_id, t2.appln_filing_date 	  
) AS t ON t1.appln_id = t.appln_id
ORDER BY t1.appln_id, t.subsequent_date ASC;




DROP INDEX IF EXISTS dbo.SUBSEQUENT_FILINGS1_TECH.sec1t_idx, dbo.SUBSEQUENT_FILINGS1_TECH.sec1t_pers_idx, dbo.SUBSEQUENT_FILINGS1_TECH.sec1t_office_idx, dbo.SUBSEQUENT_FILINGS1_TECH.sec1t_year_idx;							

CREATE CLUSTERED INDEX [sec1t_idx] ON [patstat2022a].[dbo].[SUBSEQUENT_FILINGS1_TECH]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [sec1t_sub_idx] ON [patstat2022a].[dbo].[SUBSEQUENT_FILINGS1_TECH]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO   

CREATE INDEX [sec1t_office_idx] ON [patstat2022a].[dbo].[SUBSEQUENT_FILINGS1_TECH]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [sec1t_year_idx] ON [patstat2022a].[dbo].[SUBSEQUENT_FILINGS1_TECH]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  





-- B.1 Information from equivalents (source = 2)
-- B.1.1 Find all the relevant information
-- Table: EQUIVALENTS2_TECH

DROP TABLE IF EXISTS patstat2022a.dbo.EQUIVALENTS2_TECH;

CREATE TABLE patstat2022a.dbo.EQUIVALENTS2_TECH(
appln_id INT,
subsequent_id INT,
patent_office VARCHAR(2),
appln_filing_year INT,
appln_filing_date DATE,
subsequent_date DATE,
techn_field_nr INT,
[weight] REAL,
f_type VARCHAR(MAX)
)

INSERT INTO patstat2022a.dbo.EQUIVALENTS2_TECH
SELECT  t1.appln_id, t1.subsequent_id, t1.patent_office, t1.appln_filing_year, t1.appln_filing_date, t1.subsequent_date, techn_field_nr, t2.[weight], t1.f_type
FROM patstat2022a.dbo.SUBSEQUENT_FILINGS1_TECH t1 
JOIN patstat2022a.dbo.TLS230_APPLN_TECHN_FIELD t2 ON t1.subsequent_id = t2.appln_id
WHERE t1.nb_priorities = 1;


DROP INDEX IF EXISTS dbo.EQUIVALENTS2_TECH.equ2t_idx, dbo.EQUIVALENTS2_TECH.equ2t_sub_idx,  dbo.EQUIVALENTS2_TECH.equ2t_office_idx, dbo.EQUIVALENTS2_TECH.equ2t_year_idx;

CREATE CLUSTERED INDEX [equ2t_idx] ON [patstat2022a].[dbo].[EQUIVALENTS2_TECH]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [equ2t_sub_idx] ON [patstat2022a].[dbo].[EQUIVALENTS2_TECH]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [equ2t_office_idx] ON [patstat2022a].[dbo].[EQUIVALENTS2_TECH]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [equ2t_year_idx] ON [patstat2022a].[dbo].[EQUIVALENTS2_TECH]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 




-- B.1.2 Select the most appropriate (i.e. earliest) equivalent

DROP TABLE IF EXISTS EARLIEST_EQUIVALENT2_TECH;

CREATE TABLE patstat2022a.dbo.EARLIEST_EQUIVALENT2_TECH(
appln_id INT,
subsequent_id INT,
techn_field_nr INT,
[weight] REAL,
f_type VARCHAR(MAX),
min_subsequent_date DATE
) 


INSERT INTO patstat2022a.dbo.EARLIEST_EQUIVALENT2_TECH
SELECT t1.appln_id, subsequent_id, techn_field_nr, [weight], f_type, min_subsequent_date FROM patstat2022a.dbo.EQUIVALENTS2_TECH t1
JOIN (SELECT appln_id, min(subsequent_date) AS min_subsequent_date
FROM patstat2022a.dbo.EQUIVALENTS2_TECH
GROUP BY appln_id ) AS t2 ON (t1.appln_id = t2.appln_id AND t1.subsequent_date = t2.min_subsequent_date);


DROP INDEX IF EXISTS dbo.EARLIEST_EQUIVALENT2_TECH.eequ2t_idx, dbo.EARLIEST_EQUIVALENT2_TECH.eequ2t_sub_idx;

CREATE CLUSTERED INDEX [eequ2t_idx] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT2_TECH]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [eequ2t_sub_idx] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT2_TECH]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO   


-- Table: EARLIEST_EQUIVALENT2_TECH_
-- deal with cases where we have several earliest equivalents (select only one)
DROP TABLE IF EXISTS EARLIEST_EQUIVALENT2_TECH_;
CREATE TABLE patstat2022a.dbo.EARLIEST_EQUIVALENT2_TECH_(
appln_id INT,
subsequent_id INT,
techn_field_nr INT,
[weight] REAL,
f_type VARCHAR(MAX),
min_subsequent_date DATE
) 


INSERT INTO patstat2022a.dbo.EARLIEST_EQUIVALENT2_TECH_

SELECT t1.* FROM patstat2022a.dbo.EARLIEST_EQUIVALENT2_TECH t1 JOIN
(SELECT appln_id, min(subsequent_id) as min_subsequent_id
FROM patstat2022a.dbo.EARLIEST_EQUIVALENT2_TECH
GROUP BY appln_id) as t2
ON t1.appln_id = t2.appln_id AND t1.subsequent_id = t2.min_subsequent_id;


DROP INDEX IF EXISTS dbo.EARLIEST_EQUIVALENT2_TECH_.eequ2t_idx_, dbo.EARLIEST_EQUIVALENT2_TECH_.eequ2t_sub_idx_;

CREATE CLUSTERED INDEX [eequ2t_idx_] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT2_TECH_]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [eequ2t_sub_idx_] ON [patstat2022a].[dbo].[EARLIEST_EQUIVALENT2_TECH_]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO   





-- B.2 Information from other subsequent filings (source = 3)
-- B.2.1 Find information from subsequent filings for patents that have not yet been identified via their potential equivalent(s)
-- Table: OTHER_SUBSEQUENT_FILINGS3_TECH

DROP TABLE IF EXISTS patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS3_TECH;

CREATE TABLE patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS3_TECH(
appln_id INT,
subsequent_id INT,
patent_office VARCHAR(2),
appln_filing_year INT,
appln_filing_date DATE,
subsequent_date DATE,
techn_field_nr INT,
[weight] REAL,
f_type VARCHAR(MAX)
) 

INSERT INTO patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS3_TECH
SELECT  t1.appln_id, t1.subsequent_id, t1.patent_office, t1.appln_filing_year, t1.appln_filing_date, t1.subsequent_date, techn_field_nr, t2.[weight], t1.f_type
FROM patstat2022a.dbo.SUBSEQUENT_FILINGS1_TECH t1 
JOIN patstat2022a.dbo.TLS230_APPLN_TECHN_FIELD t2 ON t1.subsequent_id = t2.appln_id
WHERE t1.nb_priorities > 1;


DROP INDEX IF EXISTS dbo.OTHER_SUBSEQUENT_FILINGS3_TECH.other3t_idx, dbo.OTHER_SUBSEQUENT_FILINGS3_TECH.other3t_sub_idx, 
dbo.OTHER_SUBSEQUENT_FILINGS3_TECH.other3t_office_idy, dbo.OTHER_SUBSEQUENT_FILINGS3_TECH.other3t_year_idx;

CREATE CLUSTERED INDEX [other3t_idx] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS3_TECH]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [other3t_sub_idx] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS3_TECH]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [other3t_office_idy] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS3_TECH]
(
   [patent_office] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [other3t_year_idx] ON [patstat2022a].[dbo].[OTHER_SUBSEQUENT_FILINGS3_TECH]
(
   [appln_filing_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 






-- B.2.2 Select the most appropriate (i.e. earliest) subsequent filing
DROP TABLE IF EXISTS EARLIEST_SUBSEQUENT_FILING3_TECH;

CREATE TABLE patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_TECH(
appln_id INT,
subsequent_id INT,
techn_field_nr INT,
[weight] REAL,
f_type VARCHAR(MAX),
min_subsequent_date DATE
) 

INSERT INTO patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_TECH
SELECT t1.appln_id, subsequent_id, techn_field_nr, [weight], f_type, min_subsequent_date FROM patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS3_TECH t1
JOIN (SELECT appln_id, min(subsequent_date) AS min_subsequent_date 
FROM patstat2022a.dbo.OTHER_SUBSEQUENT_FILINGS3_TECH
GROUP BY appln_id) AS t2 ON (t1.appln_id = t2.appln_id AND t1.subsequent_date = t2.min_subsequent_date);


DROP INDEX IF EXISTS dbo.EARLIEST_SUBSEQUENT_FILING3_TECH.esub3t_idx, dbo.EARLIEST_SUBSEQUENT_FILING3_TECH.esub3t_sub_idx;

CREATE CLUSTERED INDEX [esub3t_idx] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING3_TECH]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [esub3t_sub_idx] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING3_TECH]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO   




-- deal with cases where we have several earliest equivalents (select only one)

DROP TABLE IF EXISTS EARLIEST_SUBSEQUENT_FILING3_TECH_;

CREATE TABLE patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_TECH_(
appln_id INT,
subsequent_id INT,
techn_field_nr INT,
[weight] REAL,
f_type VARCHAR(MAX),
min_subsequent_date DATE
) 

INSERT INTO patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_TECH_
SELECT t1.* FROM patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_TECH t1 JOIN
(SELECT appln_id, min(subsequent_id) as min_subsequent_id
FROM patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_TECH
GROUP BY appln_id) AS t2
ON t1.appln_id = t2.appln_id AND t1.subsequent_id = t2.min_subsequent_id;


DROP INDEX IF EXISTS dbo.EARLIEST_SUBSEQUENT_FILING3_TECH_.esub3t_idx_, dbo.EARLIEST_SUBSEQUENT_FILING3_TECH_.esub3t_sub_idx_;

CREATE CLUSTERED INDEX [esub3t_idx_] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING3_TECH_]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [esub3t_sub_idx_] ON [patstat2022a].[dbo].[EARLIEST_SUBSEQUENT_FILING3_TECH_]
(
   [subsequent_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  






-- C TABLE containing information on priority filings and tech fields 


DROP TABLE IF EXISTS patstat2022a.dbo.TABLE_USE_TECH;

CREATE TABLE patstat2022a.dbo.TABLE_USE_TECH(
appln_id INT,
appln_kind CHAR,
patent_office VARCHAR(2),
appln_filing_year INT,
appln_filing_date DATE,
techn_field_nr INT,
[weight] REAL,
f_type VARCHAR(MAX)
)

INSERT INTO patstat2022a.dbo.TABLE_USE_TECH
SELECT * FROM patstat2022a.dbo.PRIORITY_FILINGS1_TECH; 

CREATE CLUSTERED INDEX [TABLE_USE_TECH_APPLN_ID] ON [patstat2022a].[dbo].[TABLE_USE_TECH]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  



-- Table: TABLE_TECH

DROP TABLE IF EXISTS patstat2022a.dbo.TABLE_TECH;

CREATE TABLE patstat2022a.dbo.TABLE_TECH(
appln_id INT DEFAULT NULL,
techn_field_nr INT DEFAULT NULL,
[weight] REAL DEFAULT NULL,
f_source INT DEFAULT NULL,
f_type VARCHAR(MAX) DEFAULT NULL
);







----------------------------------
----- Step 2: MAIN PROCEDURE -----
----------------------------------

-- A Insert information that is directly available (source = 1)

INSERT INTO patstat2022a.dbo.TABLE_TECH
SELECT  t_.appln_id, t_.techn_field_nr, t_.[weight], 1, f_type
FROM patstat2022a.dbo.TABLE_USE_TECH t_
WHERE t_.techn_field_nr IS NOT NULL;



-- Delete information that has been added

DELETE 
FROM 
	patstat2022a.dbo.TABLE_USE_TECH 
WHERE appln_id IN (SELECT appln_id FROM patstat2022a.dbo.table_tech);   





-- B Add the information from each selected equivalent
INSERT INTO patstat2022a.dbo.TABLE_TECH
SELECT t_.appln_id,
     t_.techn_field_nr,
     t_.[weight],
     2,
	 t_.f_type
FROM (
SELECT t1.appln_id, techn_field_nr, [weight], f_type
FROM patstat2022a.dbo.EARLIEST_EQUIVALENT2_TECH_ t1
JOIN (
SELECT DISTINCT appln_id FROM
patstat2022a.dbo.TABLE_USE_TECH) AS t2
ON t1.appln_id = t2.appln_id 
WHERE t1.techn_field_nr IS NOT NULL) AS t_;
 


DELETE 
FROM patstat2022a.dbo.TABLE_USE_TECH 
WHERE appln_id IN (SELECT appln_id FROM patstat2022a.dbo.table_tech);   






-- C Add the information from each selected subsequent filing

INSERT INTO patstat2022a.dbo.TABLE_TECH
SELECT 
t_.appln_id,
t_.techn_field_nr,
t_.[weight],
3,
t_.f_type
FROM (
SELECT t1.appln_id, techn_field_nr, [weight], f_type
FROM patstat2022a.dbo.EARLIEST_SUBSEQUENT_FILING3_TECH_ t1
JOIN (
SELECT DISTINCT appln_id FROM
patstat2022a.dbo.TABLE_USE_TECH) AS t2
ON  t1.appln_id = t2.appln_id
WHERE t1.techn_field_nr IS NOT NULL
) AS t_
;




DELETE 
FROM patstat2022a.dbo.TABLE_USE_TECH 
WHERE appln_id IN (SELECT appln_id FROM patstat2022a.dbo.table_tech);  


CREATE CLUSTERED INDEX [table_tech_appln_id] ON [patstat2022a].[dbo].[table_tech]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  







-- D Table with tech fields
-- Table: PF_TECH

DROP TABLE IF EXISTS patstat2022a.dbo.PF_TECH;

CREATE TABLE patstat2022a.dbo.PF_TECH(
	appln_id INT DEFAULT NULL,
	appln_kind CHAR(2) DEFAULT NULL,
	patent_office VARCHAR(2) DEFAULT NULL,
	priority_year INT DEFAULT NULL,
	priority_date date DEFAULT NULL,
	techn_field_nr INT DEFAULT NULL,
	[weight] REAL DEFAULT NULL,
	f_source INT DEFAULT NULL,
	f_type VARCHAR(MAX) DEFAULT NULL
); 






-- E. Job done, insert into final table 
INSERT INTO patstat2022a.dbo.PF_TECH
SELECT DISTINCT t1.appln_id, t2.appln_kind, t2.patent_office, t2.appln_filing_year, t2.appln_filing_date, techn_field_nr, [weight], f_source, t1.f_type
FROM patstat2022a.dbo.TABLE_TECH t1 JOIN patstat2022a.dbo.PRIORITY_FILINGS t2 ON t1.appln_id = t2.appln_id;


CREATE CLUSTERED INDEX [PF_TECH_APPLN_ID] ON [patstat2022a].[dbo].[PF_TECH]
(
   [appln_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  

CREATE INDEX [PF_TECH_YEAR] ON [patstat2022a].[dbo].[PF_TECH]
(
   [priority_year] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO 

CREATE INDEX [PF_TECH_NR] ON [patstat2022a].[dbo].[PF_TECH]
(
   [techn_field_nr] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO  











