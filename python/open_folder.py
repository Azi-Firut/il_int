import os


def open_folder():
    folder_path = r"C:"
    if os.path.exists(folder_path):  # Проверяем, существует ли папка
        os.system(f'explorer "{folder_path}"')  # Открываем папку в проводнике
        print("Папка успешно открыта.")
    else:
        print("Указанная папка не существует.")

if __name__ == "__main__":
    open_folder()

