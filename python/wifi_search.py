import json
import datetime
import time
import pywifi
from pywifi import const

def add_network(iface, ssid, password):
    profiles = iface.network_profiles()
    for existing_profile in profiles:
        if existing_profile.ssid == ssid:
            print(f"Network '{ssid}' already exists.")
            return True
    profile = pywifi.Profile()
    profile.ssid = ssid
    profile.auth = const.AUTH_ALG_OPEN
    profile.akm.append(const.AKM_TYPE_WPA2PSK)
    profile.cipher = const.CIPHER_TYPE_CCMP
    profile.key = password

    tmp_profile = iface.add_network_profile(profile)
    iface.connect(tmp_profile)
    time.sleep(5)
    return iface.status() == const.IFACE_CONNECTED

def scan_and_add_networks(credentials):
    wifi = pywifi.PyWiFi()
    iface = wifi.interfaces()[0]
    start_time = datetime.datetime.now()
    iface.scan()
    time.sleep(5)
    networks = iface.scan_results()
    for network in networks:
        for ssid, password in credentials.items():
            if network.ssid.startswith(ssid):
                added = add_network(iface, network.ssid, password)
                if added:
                    print(f"Added network '{network.ssid}' ")
                else:
                    print(f"Failed to add network '{network.ssid}' ")
                break
    if (datetime.datetime.now() - start_time).seconds >= 10:
        return

if __name__ == "__main__":
    # Чтение JSON из стандартного ввода
    credentials_json = input()

    # Преобразование JSON в объект Python
    credentials = json.loads(credentials_json)

    # Вызов функции для поиска и добавления сетей Wi-Fi
    scan_and_add_networks(credentials)
