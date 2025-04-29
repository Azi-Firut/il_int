import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constant.dart';
import '../widgets/answer_from_unit.dart';

Future<void> changeLidarMode(updateState) async {
  pushUnitResponse(0, "Ouster setup started",updateState: updateState);
  try {
    final url = Uri.parse(
      'http://192.168.12.1:8001/api/v1/sensor/config?reinit=true&persist=false&staging=true',
   // 'http://192.168.12.1:8001/api/v1/sensor/config?reinit=false&persist=true'
    );

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'udp_dest': '192.168.219.1',
      'udp_port_lidar': '7502',
      'udp_port_imu': '7503',
      'lidar_mode': '1024x20',
      'operating_mode': 'NORMAL',
     // 'azimuth_window': 'min:0 max:360000',
      "azimuth_window": [0, 360000],

      'signal_multiplier': '1',
      'udp_profile_lidar': 'FUSA_RNG15_RFL8_NIR8_DUAL',
      'min_range_threshold_cm': '0',
      'return_order': 'STRONGEST_TO_WEAKEST',
      'timestamp_mode': 'TIME_FROM_SYNC_PULSE_IN',
      'multipurpose_io_mode': 'OFF',
      'nmea_in_polarity': 'ACTIVE_HIGH',
      'nmea_baud_rate': 'BAUD_9600',
      'nmea_leap_seconds': '0',
      'sync_pulse_in_polarity': 'ACTIVE_HIGH',
      'sync_pulse_out_polarity': 'ACTIVE_HIGH',
      'sync_pulse_out_frequency': '1',
      'sync_pulse_out_angle': '360',
      'sync_pulse_out_pulse_width': '10',
      'phase_lock_offset': '0',
      'gyro_fsr': 'NORMAL',
      'accel_fsr': 'NORMAL',

    });

    print('Отправляю POST с JSON...');
    final response = await http.post(headers: headers, body: body,url);
    if (response.statusCode == 204) {
      pushUnitResponse(1, "Ouster setup finished", updateState: updateState);
    } else {
      pushUnitResponse(2, "Ouster setup FAIL", updateState: updateState);
    }

    print('Код ответа: ${response.statusCode}');
    print('Ответ: ${response.body}');
  }
  catch (e){
    pushUnitResponse(2, "Ouster setup FAIL", updateState: updateState);
  }
}
