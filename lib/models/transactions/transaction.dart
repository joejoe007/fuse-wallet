import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

@JsonSerializable(explicitToJson: true)
class Transaction extends Equatable {
  final String txHash;
  final int timestamp;
  final String type;
  final String status;
  final String text;
  final int blockNumber;
  final String jobId;
  final bool isSwap;

  @override
  List<Object> get props => [txHash, status, timestamp];

  Transaction(
      {this.txHash,
      this.type,
      this.isSwap = false,
      this.status,
      this.text,
      this.blockNumber,
      this.timestamp,
      this.jobId});

  Transaction copyWith({String status}) {
    return Transaction(
        isSwap: this.isSwap,
        txHash: this.txHash,
        type: this.type,
        timestamp: this.timestamp,
        status: status ?? this.status,
        text: this.text,
        blockNumber: this.blockNumber,
        jobId: this.jobId);
  }

  bool isPending() => this.status == 'PENDING';
  bool isFailed() => this.status == 'FAILED';
  bool isConfirmed() => this.status == 'CONFIRMED';

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}
