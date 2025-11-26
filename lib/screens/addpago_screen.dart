import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddPagoScreen extends StatefulWidget {
  const AddPagoScreen({super.key});

  @override
  State<AddPagoScreen> createState() => _AddPagoScreenState();
}

class _AddPagoScreenState extends State<AddPagoScreen> {
  int _step = 0;

  String _cardNumber = '';
  String _expiry = '';
  String _cvv = '';
  String _name = '';

  final PageController _controller = PageController();

  String _formatCardNumber(String input) {
    input = input.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < input.length; i++) {
      buffer.write(input[i]);
      if ((i + 1) % 4 == 0 && i != input.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  String _formatExpiry(String input) {
    input = input.replaceAll('/', '');
    if (input.length > 2) {
      return "${input.substring(0, 2)}/${input.substring(2)}";
    }
    return input;
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
      _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut);
    } else {
      Navigator.pop(context, {
        "cardNumber": _cardNumber,
        "expiry": _expiry,
        "cvv": _cvv,
        "name": _name,
      });
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _controller.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut);
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildCardPreview() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A5BD7), Color(0xFF2431A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      width: double.infinity,
      height: 190,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "BANCO DE CREDITO DEL PERU",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),

          Text(
            _cardNumber.isEmpty ? "**** **** **** ****" : _cardNumber,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, letterSpacing: 1.5),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _expiry.isEmpty ? "MM/AA" : _expiry,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                _name.isEmpty ? "Nombre en la tarjeta" : _name.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _input({
    required String label,
    required String value,
    required Function(String) onChanged,
    TextInputType type = TextInputType.number,
    List<TextInputFormatter>? formatters,
  }) {
    final isValid = value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 6),
        TextField(
          keyboardType: type,
          inputFormatters: formatters,
          onChanged: (v) {
            onChanged(v);
            setState(() {});
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            suffixIcon: isValid
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)),
        title: const Text("Agrega tu tarjeta"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF4F4F4),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= _step ? Colors.green : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildCardPreview(),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _input(
                    label: "Número de tarjeta",
                    value: _cardNumber,
                    onChanged: (v) =>
                        _cardNumber = _formatCardNumber(v),
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _input(
                    label: "Vence el",
                    value: _expiry,
                    onChanged: (v) =>
                        _expiry = _formatExpiry(v),
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _input(
                    label: "CVV",
                    value: _cvv,
                    onChanged: (v) => _cvv = v,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _input(
                      label: "Nombre del titular",
                      value: _name,
                      type: TextInputType.text,
                      onChanged: (v) => _name = v),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF2B53),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50))),
            child: Text(
              _step == 3 ? "Agregar tarjeta" : "Siguiente",
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
