import 'dart:async';
import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

class StepCounterWidget extends StatefulWidget {
  final ValueChanged<double> onDistanceUpdated;

  const StepCounterWidget({super.key, required this.onDistanceUpdated});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  bool _isWalking = false;
  double _distanceMeters = 0.0;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  Timer? _walkTimer;

  @override
  void initState() {
    super.initState();
    _startSensorMonitoring();
  }

  void _startSensorMonitoring() {
    // Acumula distancia cada segundo mientras se detecta movimiento de caminata
    _walkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isWalking) {
        setState(() {
          _distanceMeters += 1.2; // Velocidad promedio estimada (1.2 m/s)
        });
        widget.onDistanceUpdated(_distanceMeters);
      }
    });

    // Escucha el giroscopio para detectar la rotación rítmica del paso
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      final double rotationMagnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      final bool walkingNow = rotationMagnitude > 1.25;

      if (walkingNow != _isWalking) {
        setState(() {
          _isWalking = walkingNow;
        });
        if (_isWalking) {
          Vibration.vibrate(duration: 150);
        }
      }
    });
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    _walkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isWalking ? Icons.directions_walk : Icons.accessibility_new,
              size: 64,
              color: _isWalking ? const Color(0xFF2E7D32) : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              _isWalking ? 'Estado: Caminando' : 'Estado: Detenido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _isWalking ? const Color(0xFF2E7D32) : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Distancia estimada',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              '${_distanceMeters.toStringAsFixed(1)} m',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color:  Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}