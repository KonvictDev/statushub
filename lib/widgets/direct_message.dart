import 'package:flutter/material.dart';
import 'package:flutter/services.dart';// ✅ Ensure this import
import 'package:statushub/widgets/whatsapp_background.dart';

import '../l10n/app_localizations.dart';
import '../service/whatsapp_service.dart';

const String _defaultCountryCode = '+91';
const Duration _animationDuration = Duration(milliseconds: 400);

class DirectMessageWidget extends StatefulWidget {
  const DirectMessageWidget({super.key});

  @override
  State<DirectMessageWidget> createState() => _DirectMessageWidgetState();
}

class _DirectMessageWidgetState extends State<DirectMessageWidget>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _messageController = TextEditingController();
  final _numberFocusNode = FocusNode();
  final _messageFocusNode = FocusNode();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _numberController.dispose();
    _messageController.dispose();
    _numberFocusNode.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final number = '$_defaultCountryCode${_numberController.text.trim()}';
      final message = _messageController.text.trim();

      await WhatsAppService.sendMessage(context, number, message);
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorLaunchWhatsapp} ${e.message}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context)!; // ✅ Localizations reference

    return Scaffold(
      appBar: AppBar(
        title: Text(local.directMessageTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const WhatsAppBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        local.directMessageHeader,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        local.directMessageSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // ✅ Phone number field
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _numberController,
                        builder: (context, value, _) {
                          return _buildInputField(
                            controller: _numberController,
                            focusNode: _numberFocusNode,
                            labelText: local.phoneNumberLabel,
                            keyboardType: TextInputType.phone,
                            prefixText: '$_defaultCountryCode ',
                            validator: (value) {
                              final cleaned = value?.replaceAll(RegExp(r'\D'), '');
                              if (cleaned == null || cleaned.length < 10) {
                                return local.phoneNumberError;
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_messageFocusNode);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // ✅ Message field
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _messageController,
                        builder: (context, value, _) {
                          return _buildInputField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            labelText: local.optionalMessageLabel,
                            maxLines: 5,
                            suffixIcon: value.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => _messageController.clear(),
                            )
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      _buildSendButton(local),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    TextInputType? keyboardType,
    String? prefixText,
    int? maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    void Function(String)? onFieldSubmitted,
  }) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeInOut,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        textInputAction: onFieldSubmitted != null ? TextInputAction.next : TextInputAction.done,
        decoration: InputDecoration(
          prefixText: prefixText,
          labelText: labelText,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.primary, // Set the border color
              width: 1.5,                        // Border thickness
            ),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildSendButton(AppLocalizations local) {
    return AnimatedScale(
      scale: _isLoading ? 0.95 : 1.0,
      duration: _animationDuration,
      curve: Curves.easeOutBack,
      child: FilledButton.icon(
        icon: _isLoading
            ? Container(
          width: 24,
          height: 24,
          padding: const EdgeInsets.all(2.0),
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : const Icon(Icons.send_rounded),
        label: Text(_isLoading ? local.sendingLabel : local.sendMessageButton),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: _isLoading ? null : _sendMessage,
      ),
    );
  }
}
