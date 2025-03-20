import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/constants.dart';

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
        _errorText = AppConstants.pinCodeLengthError;
      });
      return;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() {
        _errorText = AppConstants.pinCodeDigitsError;
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
              labelText: AppConstants.pinCodeHint,
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
          child: Text(AppConstants.cancel),
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
        _errorText = AppConstants.pinCodeLengthError;
      });
      return;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() {
        _errorText = AppConstants.pinCodeDigitsError;
      });
      return;
    }

    if (widget.onVerifyWithResult != null) {
      widget.onVerifyWithResult!(pin, (success, error) {
        if (!success && error != null) {
          setState(() {
            _errorText = error;
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
      title: Text(AppConstants.lockedNoteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppConstants.lockedNoteDescription),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            focusNode: _pinFocusNode,
            decoration: InputDecoration(
              labelText: AppConstants.pinCodeLabel,
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
          child: Text(AppConstants.cancel),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text(AppConstants.lockButtonText),
        ),
      ],
    );
  }
}
