import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CheckinQrScreen extends StatelessWidget {
  const CheckinQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in por QR Code')),
      body: MobileScanner(
        onDetect: (result) {
          final String? code = result.barcodes.first.rawValue;
          if (code != null) {
            debugPrint('Código lido: $code');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('QR lido: $code')),
            );
            Navigator.of(context).pop(); // Fecha a tela de QR Code
            // TODO: Chamar sua API de check-in aqui
          }
        },
        // onDetect: (barcode, args) {
        //   // final String? code = barcode.rawValue;
        //   // if (code != null) {
        //   //   debugPrint('Código lido: $code');
        //   //   ScaffoldMessenger.of(context).showSnackBar(
        //   //     SnackBar(content: Text('QR lido: $code')),
        //   //   );

        //     // TODO: Chamar sua API de check-in aqui
        //   }
        // },
      ),
    );
  }
}
