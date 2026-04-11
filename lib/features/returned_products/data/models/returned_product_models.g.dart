// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'returned_product_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReturnedProductListResponse _$ReturnedProductListResponseFromJson(Map<String, dynamic> json) => ReturnedProductListResponse(
  count: (json['count'] as num).toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>).map((e) => ReturnedProduct.fromJson(e as Map<String, dynamic>)).toList(),
);

Map<String, dynamic> _$ReturnedProductListResponseToJson(ReturnedProductListResponse instance) => <String, dynamic>{
  'count': instance.count,
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};

ReturnedProduct _$ReturnedProductFromJson(Map<String, dynamic> json) => ReturnedProduct(
  id: json['id'] as String,
  returnedProductBarcode: json['returned_product_barcode'] as String,
  productUuid: json['product_uuid'] as String,
  count: (json['count'] as num).toInt(),
  isDefected: json['is_defected'] as bool,
  receiptNumber: json['receipt_number'] as String,
  refundAmount: (json['refund_amount'] as num?)?.toDouble(),
  paymentMethod: json['payment_method'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ReturnedProductToJson(ReturnedProduct instance) => <String, dynamic>{
  'id': instance.id,
  'returned_product_barcode': instance.returnedProductBarcode,
  'product_uuid': instance.productUuid,
  'count': instance.count,
  'is_defected': instance.isDefected,
  'receipt_number': instance.receiptNumber,
  'refund_amount': instance.refundAmount,
  'payment_method': instance.paymentMethod,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
