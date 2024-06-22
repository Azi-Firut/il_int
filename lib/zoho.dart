import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ZohoInvoiceScreen(),
    );
  }
}

class ZohoInvoiceScreen extends StatefulWidget {
  @override
  _ZohoInvoiceScreenState createState() => _ZohoInvoiceScreenState();
}

class _ZohoInvoiceScreenState extends State<ZohoInvoiceScreen> {
  final String apiUrl =
      'https://crm.zoho.com/crm/org2829569/tab/Invoices/178053000098254258';
  final String accessToken = '1000.O2UQZSKKF20ORURH1OPKUKBF332I2D';
  final String organizationId = '2829569';

  Future<Map<String, dynamic>> fetchInvoice() async {
    final Uri uri = Uri.parse(apiUrl); // Преобразование строки URL в объект Uri

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Zoho-oauthtoken $accessToken',
        'X-com-zoho-invoice-organizationid': organizationId,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch invoice');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zoho Invoice'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              Map<String, dynamic> invoice = await fetchInvoice();
              print('Invoice Data: $invoice');
            } catch (e) {
              print('Error: $e');
            }
          },
          child: Text('Fetch Invoice'),
        ),
      ),
    );
  }
}
