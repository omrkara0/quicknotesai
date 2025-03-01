import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class PinCodeDialog extends StatefulWidget {
  final Function(String) onSubmit;
  final String title;
  final String confirmButtonText;

  const PinCodeDialog({
    super.key,
    required this.onSubmit,
    required this.title,
    required this.confirmButtonText,
  });

  @override
  State<PinCodeDialog> createState() => _PinCodeDialogState();
}

class _PinCodeDialogState extends State<PinCodeDialog> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() {
        _errorText = 'PIN kodu 4 haneli olmalıdır';
      });
      return;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() {
        _errorText = 'PIN kodu sadece rakamlardan oluşmalıdır';
      });
      return;
    }

    widget.onSubmit(pin);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            focusNode: _pinFocusNode,
            decoration: InputDecoration(
              labelText: '4 haneli PIN kodu',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            obscureText: true,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 10,
            ),
            onChanged: (value) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.confirmButtonText),
        ),
      ],
    );
  }
}

class VerifyPinDialog extends StatefulWidget {
  final Function(String) onVerify;
  final Function() onCancel;
  final Function(String, Function(bool, String?))? onVerifyWithResult;

  const VerifyPinDialog({
    super.key,
    required this.onVerify,
    required this.onCancel,
    this.onVerifyWithResult,
  });

  @override
  State<VerifyPinDialog> createState() => _VerifyPinDialogState();
}

class _VerifyPinDialogState extends State<VerifyPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  String? _errorText;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _verifyPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() {
        _errorText = 'PIN kodu 4 haneli olmalıdır';
      });
      return;
    }

    if (widget.onVerifyWithResult != null) {
      setState(() {
        _isVerifying = true;
      });

      widget.onVerifyWithResult!(pin, (isValid, errorMessage) {
        if (mounted) {
          setState(() {
            _isVerifying = false;
            if (!isValid) {
              _errorText = errorMessage ?? 'Yanlış PIN kodu';
              _pinController.clear();
              _pinFocusNode.requestFocus();
            } else {
              Navigator.of(context).pop();
            }
          });
        }
      });
    } else {
      widget.onVerify(pin);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kilitli Not'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Bu not kilitlidir. Görüntülemek için PIN kodunu giriniz.'),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            focusNode: _pinFocusNode,
            decoration: InputDecoration(
              labelText: 'PIN Kodu',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            obscureText: true,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 10,
            ),
            onChanged: (value) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onCancel();
            Navigator.of(context).pop();
          },
          child: const Text('İptal'),
        ),
        _isVerifying
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : ElevatedButton(
                onPressed: _verifyPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Doğrula'),
              ),
      ],
    );
  }
}
