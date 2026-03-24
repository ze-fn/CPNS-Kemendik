import pdfplumber
import pandas as pd

file_path = "skd2024.pdf"
output_csv = "test1v2.csv"

all_tables = []

with pdfplumber.open(file_path) as pdf:
    for page_number, page in enumerate(pdf.pages, start=1):
        print(f"Processing page {page_number}...")
        tables = page.extract_tables()

        for table_number, table in enumerate(tables, start=1):
            df = pd.DataFrame(table)

            # Normalize columns to positional indices (CRITICAL FIX)
            df.columns = range(df.shape[1])

            # Provenance metadata
            df["__page__"] = page_number
            df["__table__"] = table_number

            all_tables.append(df)

# Concatenate once (memory-safe and fast given your RAM)
final_df = pd.concat(all_tables, ignore_index=True)

# Save to CSV
final_df.to_csv(output_csv, index=False)

print(f"Extraction complete. Saved to '{output_csv}'.")
print("Final shape:", final_df.shape)


################################################################################
#                                                                              #
#                       OLD CODE BELOW  - FOR REFERENCE                        #
#                                                                              #
################################################################################

# import PyPDF2
# import pdfplumber
# import pandas as pd

# file_path = "HasilCPNS2024KemendikbudLampiran1.pdf"

# with open(file_path, "rb") as file:
#     with pdfplumber.open(file) as pdf:
#         reader = PyPDF2.PdfReader(file)
#         print(f"Total pages: {len(reader.pages)}")
#         page = reader.pages[1]
#         text = page.extract_text()
#         print("Text from PyPDF2:", text)

# with pdfplumber.open(file_path) as pdf:
#     first_page = pdf.pages[1]
#     text = first_page.extract_text()
#     print("Raw Text:\n", text)

# table = first_page.extract_table()
# print("Extracted Table:\n", table)

# if table:
#     df = pd.DataFrame(table[1:], columns=table[0])
#     print("DataFrame:\n", df)

