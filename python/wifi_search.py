import datetime
import time

import pywifi
from pywifi import const


def add_network(iface, ssid, password):
    profiles = iface.network_profiles()
    for existing_profile in profiles:
        if existing_profile.ssid == ssid:
            print(f"Network '{ssid}' already exists.")
            return True  # Если профиль уже существует, возвращаем True
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

def scan_and_add_networks():
    wifi = pywifi.PyWiFi()
    iface = wifi.interfaces()[0]
    start_time = datetime.datetime.now()
    while (datetime.datetime.now() - start_time).seconds < 10:  # Работать только 60 секунд
        iface.scan()
        time.sleep(5)
        networks = iface.scan_results()
        for network in networks:
            ssid = network.ssid
            if ssid.startswith("WINGTRA"):
                added = add_network(iface, ssid, "WingtraLidar")
                if added:
                    print(f"Added network '{ssid}' to favorites.")
                else:
                    print(f"Failed to add network '{ssid}' to favorites.")
            # Добавьте другие сети по аналогии с предыдущими if-блоками
            if ssid.startswith("RESEPI"):
                added = add_network(iface, ssid, "LidarAndINS")
                if added:
                    print(f"Added network '{ssid}' to favorites.")
                else:
                    print(f"Failed to add network '{ssid}' to favorites.")
            if ssid.startswith("FLIGHTS"):
                added = add_network(iface, ssid, "FLIGHTSscan")
                if added:
                    print(f"Added network '{ssid}' to favorites.")
                else:
                    print(f"Failed to add network '{ssid}' to favorites.")
            if ssid.startswith("RECON"):
                added = add_network(iface, ssid, "LidarAndINS")
                if added:
                    print(f"Added network '{ssid}' to favorites.")
                else:
                    print(f"Failed to add network '{ssid}' to favorites.")
            if ssid.startswith("STONEX"):
                added = add_network(iface, ssid, "StoneXFLY")
                if added:
                    print(f"Added network '{ssid}' to favorites.")
                else:
                    print(f"Failed to add network '{ssid}' to favorites.")
            if ssid.startswith("TERSUS"):
                added = add_network(iface, ssid, "LidarAndINS")
                if added:
                    print(f"Added network '{ssid}' to favorites.")
                else:
                    print(f"Failed to add network '{ssid}' to favorites.")
            if ssid.startswith("TRIDAR"):
                 added = add_network(iface, ssid, "L!DAR2020")
                 if added:
                     print(f"Added network '{ssid}' to favorites.")
                 else:
                   print(f"Failed to add network '{ssid}' to favorites.")
            if ssid.startswith("ML-"):
                added = add_network(iface, ssid, "MICRoLiDAR")
                if added:
                    print(f"Added network '{ssid}' to favorites.")
                else:
                    print(f"Failed to add network '{ssid}' to favorites.")
            if ssid.startswith("ROCK"):
                added = add_network(iface, ssid, "rocklidar")
                if added:
                    print(f"Added network '{ssid}' to favorites.")
                else:
                    print(f"Failed to add network '{ssid}' to favorites.")
            if ssid.startswith("Redmi"):
                added = add_network(iface, ssid, "12345678")
                if added:
                    print(f"Added network '{ssid}' to favorites.")
                else:
                    print(f"Failed to add network '{ssid}' to favorites.")

            # Проверяем, прошла ли минута
            if (datetime.datetime.now() - start_time).seconds >= 10:
                break

if __name__ == "__main__":
    scan_and_add_networks()
