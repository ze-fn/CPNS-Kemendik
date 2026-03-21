import pdfplumber
import pandas as pd
import re
import sys
from datetime import datetime


# -----------------------------
# Helper functions
# -----------------------------

def clean_text(text):
    if not text:
        return ""
    return re.sub(r"\s+", " ", text).strip()


def extract_context_from_text(text):
    """
    Extracts contextual metadata that applies to all rows on a page
    """
    context = {
        "jabatan_formasi": None,
        "lokasi_formasi": None,
        "jenis_formasi": None,
        "pendidikan_formasi": None,
    }

    lines = text.split("\n")

    for line in lines:
        line_clean = clean_text(line)

        if "Jabatan Formasi" in line_clean:
            context["jabatan_formasi"] = line_clean

        elif "Lokasi Formasi" in line_clean:
            context["lokasi_formasi"] = line_clean

        elif "Jenis Formasi" in line_clean:
            context["jenis_formasi"] = line_clean

        elif line_clean.startswith("Pendidikan"):
            context["pendidikan_formasi"] = line_clean

    return context


def normalize_header(header_row):
    """
    Forces consistent, analyst-friendly column names
    """
    normalized = []
    for h in header_row:
        h = clean_text(h).lower()

        if "no peserta" in h:
            normalized.append("no_peserta")
        elif h == "no":
            normalized.append("no")
        elif "nama" in h:
            normalized.append("nama")
        elif "pendidikan" in h:
            normalized.append("pendidikan_peserta")
        elif "tahun" in h:
            normalized.append("tahun_skd")
        elif "twk" in h:
            normalized.append("twk")
        elif "tiu" in h:
            normalized.append("tiu")
        elif "tkp" in h:
            normalized.append("tkp")
        elif "total" in h:
            normalized.append("total_skd")
        elif "keterangan" in h:
            normalized.append("keterangan")
        else:
            normalized.append(h)

    return normalized


def is_participant_table(table):
    """
    Heuristic: participant tables always contain 'No Peserta' or 'Nama'
    """
    if not table or len(table) < 2:
        return False

    header = " ".join([str(c) for c in table[0] if c])
    return ("No Peserta" in header) or ("Nama" in header)


# -----------------------------
# Core extraction logic
# -----------------------------

def extract_rows(pdf_path, progress_every=1):
    all_rows = []

    with pdfplumber.open(pdf_path) as pdf:
        total_pages = len(pdf.pages)
        print(f"[INFO] Total pages detected: {total_pages}")

        for i, page in enumerate(pdf.pages, start=1):
            if i % progress_every == 0:
                print(f"[PROGRESS] Processing page {i}/{total_pages}")

            text = page.extract_text() or ""
            context = extract_context_from_text(text)

            tables = page.extract_tables()
            if not tables:
                continue

            for table in tables:
                if not is_participant_table(table):
                    continue

                header = normalize_header(table[0])

                for row in table[1:]:
                    if not any(row):
                        continue

                    record = dict(zip(header, row))

                    # Attach context
                    record["jabatan_formasi"] = context["jabatan_formasi"]
                    record["lokasi_formasi"] = context["lokasi_formasi"]
                    record["jenis_formasi"] = context["jenis_formasi"]
                    record["pendidikan_formasi"] = context["pendidikan_formasi"]
                    record["page_number"] = i

                    all_rows.append(record)

    return all_rows


# -----------------------------
# Main execution (INTENTIONALLY AT BOTTOM)
# -----------------------------

if __name__ == "__main__":
    pdf_path = "skd2024.pdf"
    output_csv = "skd_w_context.csv"

    print("[START] CPNS PDF extraction started")
    start_time = datetime.now()

    rows = extract_rows(pdf_path, progress_every=1)

    if not rows:
        print("[ERROR] No participant data extracted. CSV not created.")
        sys.exit(1)

    df = pd.DataFrame(rows)

    # Final light cleanup
    df.columns = [c.strip().lower() for c in df.columns]

    df.to_csv(output_csv, index=False, encoding="utf-8-sig")

    elapsed = datetime.now() - start_time

    print(f"[SUCCESS] Extraction completed")
    print(f"[INFO] Total rows saved: {len(df)}")
    print(f"[INFO] Output file: {output_csv}")
    print(f"[INFO] Time elapsed: {elapsed}")


#######################################################################################
#                                                                                     #
#                                    OLD CODE BELOW                                   #
#                                                                                     #
#                                                                                     #
#                                                                                     #
#########################################################################################
# import pdfplumber
# import pandas as pd
# import re
# import sys
# from pathlib import Path

# def extract_rows(pdf_path, progress_every=100):
#     """
#     Extract raw table-like rows from all pages of a PDF using pdfplumber.

#     Parameters
#     ----------
#     pdf_path : str or Path
#         Path to the input PDF file
#     progress_every : int
#         Print progress every N pages (after the first 10 pages)

#     Returns
#     -------
#     list[list[str]]
#         A list of extracted rows (still uncleaned)
#     """

#     all_rows = []

#     print("[INFO] Opening PDF...")
#     with pdfplumber.open(pdf_path) as pdf:
#         total_pages = len(pdf.pages)
#         print(f"[INFO] PDF opened successfully ({total_pages} pages)")
#         print("[INFO] Starting page-by-page extraction...")

#         for page_number, page in enumerate(pdf.pages, start=1):

#             # ---- Progress reporting (adaptive) ----
#             if page_number <= 10 or page_number % progress_every == 0:
#                 print(f"[EXTRACT] Page {page_number} / {total_pages}")

#             try:
#                 tables = page.extract_tables()
#             except Exception as e:
#                 print(f"[WARN] Failed to extract tables on page {page_number}: {e}")
#                 continue

#             if not tables:
#                 continue

#             for table in tables:
#                 for row in table:
#                     if row:
#                         cleaned_row = [
#                             cell.strip() if cell is not None else ""
#                             for cell in row
#                         ]
#                         all_rows.append(cleaned_row)

#     print("[INFO] Extraction complete")
#     print(f"[INFO] Total rows collected: {len(all_rows)}")

#     return all_rows


# # ---------- STEP 2: Detect participant row ----------
# def is_new_participant(cells):
#     """
#     Heuristic for detecting the first row of a participant.
#     """
#     if len(cells) < 3:
#         return False

#     return (
#         cells[0].isdigit() and
#         re.match(r"^\d{10,}$", cells[1].replace(",", "").replace(".", ""))
#     )

# # ---------- STEP 3: Reconstruct participants ----------
# def reconstruct_participants(rows):
#     participants = []
#     current = None

#     for row in rows:
#         cells = [c for c in row["cells"] if c]

#         if not cells:
#             continue

#         # Start of a new participant
#         if is_new_participant(cells):
#             if current:
#                 participants.append(current)

#             current = {
#                 "page": row["page"],
#                 "raw": cells.copy()
#             }

#         # Continuation of previous participant
#         elif current:
#             current["raw"].extend(cells)

#     if current:
#         participants.append(current)

#     return participants

# # ---------- STEP 4: Normalize participant ----------
# def normalize_participant(p):
#     r = p["raw"]

#     def safe(idx):
#         return r[idx] if idx < len(r) else None

#     return {
#         "page": p["page"],
#         "no": safe(0),
#         "no_peserta": safe(1),
#         "nama": safe(2),
#         "tanggal_lahir": safe(3),
#         "pendidikan": safe(6),
#         "ipk": safe(7),
#         "twk": safe(8),
#         "tiu": safe(9),
#         "tkp": safe(10),
#         "total_skd": safe(11),
#         "nilai_skb": safe(12),
#         "nilai_akhir": safe(13),
#         "status": safe(14),
#     }

# # ---------- STEP 5: Main execution ----------

# if __name__ == "__main__":
#     pdf_path = "HasilCPNS2024KemendikbudLampiran1.pdf"
#     output_csv = "cpns_final_clean.csv"

#     print("[START] CPNS PDF extraction started")

#     rows = extract_rows(pdf_path, progress_every=1)
#     participants = reconstruct_participants(rows)

#     print("[NORMALIZE] Building final table...")

#     clean_records = [normalize_participant(p) for p in participants]
#     df = pd.DataFrame(clean_records)

#     numeric_cols = [
#         "ipk", "twk", "tiu", "tkp",
#         "total_skd", "nilai_skb", "nilai_akhir"
#     ]

#     for col in numeric_cols:
#         df[col] = pd.to_numeric(df[col], errors="coerce")

#     print("[WRITE] Writing CSV...")
#     df.to_csv(output_csv, index=False)

#     print("[DONE] Clean CSV written:", output_csv)
#     print("[DONE] Rows:", len(df))