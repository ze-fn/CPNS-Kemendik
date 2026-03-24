-- \copy cpns2024.test1 FROM 'C:/Users/blast/OneDrive/Documents/CPNS-Kemendik/2024/test1.csv' CSV HEADER DELIMITER ',' QUOTE '"';

WITH scores AS(
	SELECT *
	FROM cpns2024.test1
	WHERE id LIKE '2430%'
),

unioned AS(
	SELECT 
		t1.rank, t1.id, t1.full_name, t1.last_edu,
		t1.twk, t1.skd, t1.decl_code
	FROM scores AS t1
	UNION
	SELECT 
		t2.rank, t2.id, t2.full_name, t2.last_edu,
		t2.twk, t2.skd, t2.decl_code
	FROM cpns2024.test1_context AS t2
),

contextualized AS(
	SELECT lt.*, rt.jp_code, rt.loc_code, rt.type_code, rt.edu_qual
	FROM unioned AS lt
	LEFT JOIN cpns2024.test1_context AS rt
		ON lt.id = rt.id
	ORDER BY rt.page_num::numeric, lt.rank::numeric
),

clean1 AS(
	SELECT 
		lt.rank::numeric, lt.id, lt.full_name, lt.last_edu,
		lt.twk, rt.tiu, rt.tkp, lt.skd, lt.decl_code, lt.jp_code,
		lt.loc_code, lt.type_code, rt.page_num::numeric
	FROM contextualized AS lt
	LEFT JOIN cpns2024.test1 AS rt
		ON lt.id = rt.id
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13
	HAVING COUNT(lt.id) < 2
	ORDER BY page_num, rank
),

clean2 AS(
	SELECT 
		rank, id, full_name, last_edu, twk, tiu, tkp, skd, decl_code, 
		SUBSTRING(jp_code FROM (POSITION(': ' IN jp_code) + 2) FOR 9) AS jp_code,
		SUBSTRING(loc_code FROM (POSITION(': ' IN loc_code)+2) FOR (LENGTH(loc_code) - (POSITION(': ' IN loc_code) + 2) - (POSITION(' - ' IN REVERSE(loc_code)))) ) AS loc_code, 
		SUBSTRING(type_code FROM (POSITION('- ' IN type_code) + 2) FOR (LENGTH(type_code) - (POSITION(' ' IN (REVERSE(type_code)))) - (POSITION('- ' IN type_code) + 1))) AS type_code,
		SUBSTRING(REVERSE(type_code) FROM 0 FOR (POSITION(' ' IN (REVERSE(type_code))))) AS allotment,
		-- SUBSTRING(type_code FROM (POSITION(': ' IN type_code)+2) FOR 1) AS type_code,
		page_num
	FROM clean1
)

SELECT *
FROM clean2