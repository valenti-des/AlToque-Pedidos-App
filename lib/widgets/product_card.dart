import 'dart:async';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatefulWidget {
  const ProductCard(this.product, this.onAdd, {this.onOpen, super.key});

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback? onOpen;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isFlashing = false;
  Timer? _flashTimer;
  Timer? _openTimer;

  void _flash() {
    _flashTimer?.cancel();
    setState(() => _isFlashing = true);
    _flashTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _isFlashing = false);
    });
  }

  void _openProduct() {
    _flash();
    _openTimer?.cancel();
    _openTimer = Timer(const Duration(milliseconds: 110), () {
      if (mounted) widget.onOpen?.call();
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _openTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onOpen == null ? _flash : _openProduct,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedScale(
        scale: _isFlashing ? 0.985 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _isFlashing ? AppColors.paleBlue : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isFlashing ? AppColors.primary : AppColors.border,
              width: _isFlashing ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: _isFlashing ? 0.2 : 0.06,
                ),
                blurRadius: _isFlashing ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  color: widget.product.color,
                  alignment: Alignment.center,
                  child: Text(
                    widget.product.emoji,
                    style: const TextStyle(fontSize: 58),
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.muted),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.product.price,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _flash();
                              widget.onAdd();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 21,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
