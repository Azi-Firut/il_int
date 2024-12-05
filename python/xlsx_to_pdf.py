import os
import re
import sys
import win32com.client
import time  # Импортируем модуль для ожидания

sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

def excel_to_pdf(excel_path, pdf_path):
    """
    Конвертирует указанный Excel-файл в PDF.
    """
    # Инициализация приложения Excel
    excel = win32com.client.Dispatch("Excel.Application")
    excel.Visible = False

    try:
        # Открытие Excel-файла
        wb = excel.Workbooks.Open(excel_path)
        # Экспорт в формат PDF
        wb.ExportAsFixedFormat(0, pdf_path)
        print(f"Файл успешно конвертирован в PDF: {pdf_path}")
    except Exception as e:
        print(f"Ошибка при конвертации в PDF: {e}")
    finally:
        # Закрытие книги и завершение работы приложения Excel
        wb.Close(False)
        excel.Quit()

# Проверка, был ли передан аргумент командной строки
if len(sys.argv) > 1:
    excel_path = sys.argv[1]
    # Проверка, существует ли файл
    if not os.path.exists(excel_path):
        print(f"Указанный файл не существует: {excel_path}")
        time.sleep(5)  # Ожидание 5 секунд
        sys.exit(1)

    # Определение пути для сохранения PDF
    pdf_path = re.sub(r'\.xlsx$', '.pdf', excel_path, flags=re.IGNORECASE)
    # Конвертация файла
    excel_to_pdf(excel_path, pdf_path)
else:
    print("Не указан путь к Excel-файлу.")
