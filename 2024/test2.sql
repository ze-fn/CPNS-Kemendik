/* Import missing columns from different PDF:
```psql
\copy cpns2024.test2_missings FROM '/test2_tiutkp.csv' CSV HEADER DELIMITER ',' QUOTE '"';
```
*/

-- CREATE TABLE cpns2024.ft2024 AS -- ft2024 = 'final table 2024' which contains rows from eliminated candidates at the 2nd stage of the recruitment process.
WITH rmv_header AS (
	SELECT *
	FROM cpns2024.test2
	WHERE 
		twk NOT LIKE 'TKW' AND
		skd NOT LIKE '(7%' AND
		rank IS NOT NULL AND
		rank NOT LIKE '(%'
	ORDER BY page_num::numeric, rank::numeric
),
rmv_newlines AS(
	SELECT
		rank::numeric, id,
		REGEXP_REPLACE(full_name, E'[\\n\\r]+', ' ', 'g') AS full_name,
		REGEXP_REPLACE(birthdate, E'[\\n\\r]+', ' ', 'g') AS birthdate,
		REGEXP_REPLACE(last_edu, E'[\\n\\r]+', ' ', 'g') AS last_edu,
		gpa, twk, skd, skd40, skb, skb60, final_score, decl_code,
		REGEXP_REPLACE(jp_code, E'[\\n\\r]+', ' ', 'g') AS jp_code,
		REGEXP_REPLACE(loc_code, E'[\\n\\r]+', ' ', 'g') AS loc_code,
		REGEXP_REPLACE(type_code, E'[\\n\\r]+', ' ', 'g') AS type_code,
		REGEXP_REPLACE(edu_qual, E'[\\n\\r]+', ' ', 'g') AS edu_qual,
		page_num
	FROM rmv_header
	ORDER BY page_num::numeric, rank::numeric
),
proper1 AS (
	SELECT
		rank, id, full_name,
		TO_DATE(
		    REPLACE(
		    REPLACE(
		    REPLACE(
		    REPLACE(
		    REPLACE(
		    REPLACE(
		    REPLACE(
		    REPLACE(
		    REPLACE(
		    REPLACE(
		    REPLACE(
		    REPLACE(birthdate,
		      'Januari','January'),
		      'Februari','February'),
		      'Maret','March'),
		      'April','April'),
		      'Mei','May'),
		      'Juni','June'),
		      'Juli','July'),
		      'Agustus','August'),
		      'September','September'),
		      'Oktober','October'),
		      'November','November'),
		      'Desember','December'),
		    'DD Month YYYY'
		  ) AS birthdate,
		  last_edu, gpa::double precision, twk::integer, skd::integer, skd40::double precision, 
		  skb::double precision, skb60::double precision, final_score::double precision, decl_code::VARCHAR(6), 
		  SUBSTRING(jp_code FROM (POSITION(':' IN jp_code) + 2) FOR 9) AS jp_code,
		  SUBSTRING(loc_code FROM (POSITION(':' IN loc_code) + 2) FOR 8) AS loc_code, 
		  SUBSTRING(type_code FROM (POSITION(':' IN type_code) + 2) FOR 1) AS type_code,
		  REGEXP_SPLIT_TO_ARRAY(REGEXP_REPLACE(REGEXP_REPLACE(REPLACE(edu_qual, 'Pendidikan ', ''), '\s+\d+$', ''), '\s+', ' ', 'g'), '\s*/\s*') AS edu_qual,
		  page_num
	FROM rmv_newlines
	ORDER BY page_num::numeric, rank::numeric
),
proper2 AS(
	SELECT
		rank, id, full_name, birthdate, last_edu, 
		(CASE 
		 WHEN last_edu LIKE 'SLTA%' THEN 'SHS'
		 WHEN last_edu LIKE 'SMK%' THEN 'VHS'
		 ELSE 'University'
		 END) AS edu_group,
		(CASE 
		 WHEN gpa > 4 THEN gpa/100*4
		 ELSE gpa 
		 END) AS gpa, 
		twk, skd, skd40, skb, skb60,
		final_score, decl_code, jp_code::char(9), loc_code::char(8), type_code::char(1), 
		edu_qual, page_num::numeric
	FROM proper1
	ORDER BY page_num::numeric, rank::numeric
)

SELECT
	rank, lt.id, birthdate, last_edu, edu_group, gpa, twk, tiu, tkp, skd, skd40, skb, skb60,
	final_score, decl_code, jp_code, loc_code, type_code, edu_qual, page_num
FROM proper2 AS lt
LEFT JOIN cpns2024.test2_missings AS rt
	ON rt.id = lt.id
ORDER BY page_num, rank;