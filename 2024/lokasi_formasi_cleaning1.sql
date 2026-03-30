SELECT * FROM hasil_cpns2024_kemendikbud.add_nulls_extd_loc_details1;

WITH raw_loc AS(
SELECT 
	CASE WHEN loc_code LIKE "%Lokasi%" THEN SUBSTRING(loc_code, LOCATE(": ", loc_code) + 2)
    ELSE loc_code END AS loc_code,
	string1, string2, string3, string4, string5, string6, NULL AS stage1
FROM add_nulls_extd_loc_details1),

cleaning_stage1 AS(
SELECT 
	CASE WHEN loc_code LIKE "%Lokasi Formasi%" THEN SUBSTRING(loc_code, LOCATE(": ", loc_code) + 2, 8)
    ELSE loc_code END AS loc_code,
    string1, string2, string3, string4, string5, string6,
    NULL AS stage1,
    NULL AS stage2,
    NULL AS stage3,
    NULL AS stage4,
    NULL AS stage5,
    NULL AS stage6
FROM add_nulls_extd_loc_details1)
,
-- SELECT DISTINCT string5
remove_noise AS(
SELECT loc_code,
	CASE 
		WHEN string1 LIKE "%KEMENTERIAN%" THEN NULL 
        WHEN string1 LIKE 'Nasional "Veteran"" Yogyakarta"' THEN "Universitas Pembangunan Nasional Veteran Yogyakarta"
        WHEN string1 LIKE 'Nasional "Veteran"" Jakarta"' THEN "Universitas Pembangunan Nasional Veteran Jakarta"
        WHEN string1 LIKE 'Nasional "Veteran"" Jawa Timur"' THEN "Universitas Pembangunan Nasional Veteran Jawa Timur"
        WHEN string1 LIKE 'MANGKURAT' THEN "Universitas Lambung Mangkurat"
        WHEN string1 LIKE 'Keguruan dan Ilmu Pendidikan' THEN "Fakultas Ilmu Keguruan dan Pendidikan"
        WHEN string1 LIKE 'Ilmu Sosial dan Ilmu Politik' THEN "Fakultas Ilmu Sosial dan Ilmu Politik"
        WHEN string1 LIKE 'Sains dan Teknologi' THEN "Fakultas Sains dan Teknologi"
        WHEN string1 LIKE 'November Kolaka' THEN 'Universitas Sembilanbelas November Kolaka'
        WHEN string1 LIKE 'INSPEKTORAT%' THEN 'Inspektorat Jenderal'
    ELSE string1 END AS data1,
    CASE 
		WHEN string2 LIKE 'PERGURUAN TINGGI%' THEN NULL
        WHEN string2 LIKE 'UMUM 35' THEN NULL
        WHEN string2 LIKE 'LULUSAN%' THEN NULL
        WHEN string2 LIKE 'PUTRA/%' THEN NULL
        ELSE string2 END AS data2,
    CASE
		WHEN string3 LIKE '_ KEMENTERIAN PENDIDIKAN%' THEN NULL
        WHEN string3 LIKE '__ KEMENTERIAN PENDIDIKAN%' THEN NULL
        ELSE string3 END AS data3,
	CASE
		WHEN string4 LIKE 'UMUM%' THEN NULL
        WHEN string4 LIKE 'LULUSAN%' THEN NULL
        WHEN string4 LIKE 'PUTRA%' THEN NULL
        WHEN string4 LIKE '_ KEMENTERIAN PENDIDIKAN%' THEN NULL
        WHEN string4 LIKE '__ KEMENTERIAN PENDIDIKAN%' THEN NULL
        WHEN string4 LIKE 'PERGURUAN TINGGI%' THEN NULL
        ELSE string4 END AS data4,
    CASE
		WHEN string5 LIKE 'PERGURUAN TINGGI%' THEN NULL
        WHEN string5 LIKE '_ KEMENTERIAN PENDIDIKAN%' THEN NULL
        WHEN string5 LIKE '__ KEMENTERIAN PENDIDIKAN%' THEN NULL
        WHEN string5 LIKE 'UMUM%' THEN NULL
        WHEN string5 LIKE 'LULUSAN%' THEN NULL
        WHEN string5 LIKE 'PUTRA%' THEN NULL
        ELSE string5 END AS data5,
    CASE
		WHEN string6 LIKE 'PERGURUAN TINGGI%' THEN NULL
        WHEN string6 LIKE '_ KEMENTERIAN PENDIDIKAN%' THEN NULL
        WHEN string6 LIKE '__ KEMENTERIAN PENDIDIKAN%' THEN NULL
        WHEN string6 LIKE 'UMUM%' THEN NULL
        WHEN string6 LIKE 'LULUSAN%' THEN NULL
        WHEN string6 LIKE 'PUTRA%' THEN NULL
        ELSE string6 END AS data6
FROM cleaning_stage1)

SELECT 
	*
FROM remove_noise