import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';

extension AsyncValueX<T> on AsyncValue<T> {
  AsyncValueLike<T> get asLike => AsyncValueLike<T>(
        isLoading: isLoading,
        hasValue: hasValue,
        hasError: hasError,
        value: valueOrNull,
        errorMessage: hasError
            ? (error is Failure ? (error as Failure).message : error.toString())
            : null,
      );
}
