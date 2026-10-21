import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/core/network/connectivity_provider.dart';
import 'package:student_management/core/network/connectivity_status.dart';
import 'package:student_management/core/theme/app_colors.dart';

/// Application-wide connectivity overlay widget.
///
/// Wraps the root [Navigator] in `MaterialApp.router(builder: ...)`.
/// Displays a persistent, animated banner when offline or when internet
/// access is unreachable, pushing screen content downward rather than
/// obscuring navigation controls or app bars.
class GlobalConnectivityBanner extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalConnectivityBanner({super.key, required this.child});

  @override
  ConsumerState<GlobalConnectivityBanner> createState() =>
      _GlobalConnectivityBannerState();
}

class _GlobalConnectivityBannerState
    extends ConsumerState<GlobalConnectivityBanner> {
  bool _hasBeenOffline = false;
  bool _showRecovery = false;
  Timer? _recoveryTimer;

  @override
  void dispose() {
    _recoveryTimer?.cancel();
    super.dispose();
  }

  void _handleStatusChange(ConnectivityStatus status) {
    if (status.isOffline) {
      _hasBeenOffline = true;
      _recoveryTimer?.cancel();
      if (_showRecovery) {
        setState(() => _showRecovery = false);
      }
    } else if (status.isOnline && _hasBeenOffline) {
      setState(() {
        _showRecovery = true;
      });
      _recoveryTimer?.cancel();
      _recoveryTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _showRecovery = false;
            _hasBeenOffline = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(connectivityProvider);

    // React to status changes for recovery confirmation
    ref.listen<ConnectivityStatus>(connectivityProvider, (previous, current) {
      _handleStatusChange(current);
    });

    final isOffline = status.isOffline;
    final isCheckingWhileOffline = status.isChecking && _hasBeenOffline;
    final shouldShowBanner =
        isOffline || _showRecovery || isCheckingWhileOffline;

    return Column(
      children: [
        _BannerContainer(
          isVisible: shouldShowBanner,
          status: status,
          isRecovery: _showRecovery,
          onRetry: () => ref.read(connectivityProvider.notifier).recheck(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

class _BannerContainer extends StatelessWidget {
  final bool isVisible;
  final ConnectivityStatus status;
  final bool isRecovery;
  final VoidCallback onRetry;

  const _BannerContainer({
    required this.isVisible,
    required this.status,
    required this.isRecovery,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final IconData iconData;
    final String message;

    if (isRecovery) {
      backgroundColor = AppColors.success;
      iconData = Icons.wifi_rounded;
      message = 'Internet connection restored.';
    } else {
      switch (status) {
        case ConnectivityStatus.noNetwork:
          backgroundColor = AppColors.error;
          iconData = Icons.wifi_off_rounded;
          message = status.message;
          break;
        case ConnectivityStatus.networkWithoutInternet:
          backgroundColor = AppColors.warning;
          iconData = Icons.cloud_off_rounded;
          message = status.message;
          break;
        case ConnectivityStatus.checking:
          backgroundColor = AppColors.slate700;
          iconData = Icons.sync_rounded;
          message = 'Verifying internet access...';
          break;
        case ConnectivityStatus.online:
          backgroundColor = AppColors.success;
          iconData = Icons.wifi_rounded;
          message = 'Online';
          break;
      }
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child:
          isVisible
              ? Material(
                color: backgroundColor,
                elevation: 4,
                child: SafeArea(
                  bottom: false,
                  top: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        if (status == ConnectivityStatus.checking &&
                            !isRecovery)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        else
                          Icon(
                            iconData,
                            size: 18,
                            color: Colors.white,
                            semanticLabel: 'Connectivity indicator',
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRecovery &&
                            status != ConnectivityStatus.checking) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: onRetry,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Retry',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
              : const SizedBox.shrink(),
    );
  }
}
