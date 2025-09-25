import 'package:flutter/material.dart';

class FormStepLogo extends StatelessWidget {
  final String step;
  final bool isActive;
  final bool isCompleted;
  final double size;

  const FormStepLogo({
    super.key,
    required this.step,
    this.isActive = false,
    this.isCompleted = false,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getBackgroundColor(context),
        border: Border.all(
          color: _getBorderColor(context),
          width: 2,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: _getBorderColor(context).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Icon(
        _getIcon(),
        size: size * 0.5,
        color: _getIconColor(context),
      ),
    );
  }

  IconData _getIcon() {
    switch (step.toLowerCase()) {
      case 'info':
        return Icons.info_outline;
      case 'ministry':
        return Icons.church;
      case 'function':
        return Icons.work_outline;
      case 'terms':
        return Icons.check_circle_outline;
      case 'submit':
        return Icons.send;
      default:
        return Icons.star_outline;
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    if (isCompleted) {
      return Colors.green;
    } else if (isActive) {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Theme.of(context).colorScheme.surface;
    }
  }

  Color _getBorderColor(BuildContext context) {
    if (isCompleted) {
      return Colors.green;
    } else if (isActive) {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Theme.of(context).colorScheme.outline;
    }
  }

  Color _getIconColor(BuildContext context) {
    if (isCompleted || isActive) {
      return Colors.white;
    } else {
      return Theme.of(context).colorScheme.outline;
    }
  }
}

class FormProgressIndicator extends StatelessWidget {
  final List<String> steps;
  final int currentStep;

  const FormProgressIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FormStepLogo(
                step: step,
                isActive: isActive,
                isCompleted: isCompleted,
                size: 50,
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.green 
                          : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
