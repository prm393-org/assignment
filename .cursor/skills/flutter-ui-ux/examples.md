# Examples

## Good: list with triad + refresh + empty CTA

```dart
RefreshIndicator(
  onRefresh: () => ref.refresh(ordersProvider.future),
  child: AsyncBody(
    value: ordersAsync,
    onRetry: () => ref.invalidate(ordersProvider),
    empty: EmptyState(
      message: 'Chưa có đơn hàng',
      actionLabel: 'Đi chợ',
      onAction: () => context.go('/consumer/marketplace'),
    ),
    builder: (orders) => ListView.builder(
      itemCount: orders.length,
      itemBuilder: (_, i) => /* ... */,
    ),
  ),
);
```

## Good: form validators

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        controller: _phone,
        decoration: const InputDecoration(labelText: 'Số điện thoại'),
        validator: (v) {
          final t = v?.trim() ?? '';
          if (t.isEmpty) return 'Vui lòng nhập số điện thoại';
          if (t.length < 9) return 'Số điện thoại không hợp lệ';
          return null;
        },
      ),
      FilledButton(
        onPressed: _saving
            ? null
            : () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                _submit();
              },
        child: Text(_saving ? 'Đang xử lý…' : 'Xác nhận'),
      ),
    ],
  ),
);
```

## Bad → good: hardcoded color

```dart
// BAD
Container(color: const Color(0xFF1FA35A));

// GOOD
Container(color: AppColors.forestSoft);
```

## Bad → good: silent FAB

```dart
// BAD
onPressed: () {
  if (farms.isEmpty) return;
  _openSubmit();
}

// GOOD
onPressed: farms.isEmpty
    ? () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hãy tạo nông trại trước')),
        )
    : _openSubmit,
```

## Audit line examples

```
CRITICAL | lib/features/auth/presentation/screens/login_screen.dart | go('/consumer') no route | use /consumer/home
HIGH     | lib/features/cart/presentation/screens/checkout_screen.dart | no Form validators | wrap Form + phone/name validators
MEDIUM   | lib/features/order/presentation/screens/earnings_screen.dart | raw Card | migrate SurfaceCard + RefreshIndicator
LOW      | lib/core/widgets/role_shell.dart | no unread badge | optional badge on profile/chat entry
```
