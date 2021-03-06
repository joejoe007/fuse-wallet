import 'package:fusecash/models/jobs/base.dart';
import 'package:fusecash/models/plugins/join_bonus.dart';
import 'package:fusecash/models/tokens/token.dart';
import 'package:fusecash/models/transactions/transfer.dart';
import 'package:fusecash/redux/actions/cash_wallet_actions.dart';
import 'package:fusecash/redux/state/store.dart';
import 'package:fusecash/services.dart';
import 'package:json_annotation/json_annotation.dart';

part 'join_community_job.g.dart';

@JsonSerializable(explicitToJson: true, createToJson: false)
class JoinCommunityJob extends Job {
  JoinCommunityJob({id, jobType, name, status, data, arguments, lastFinishedAt, timeStart, isReported, isFunderJob})
      : super(
            id: id,
            jobType: jobType,
            name: name,
            status: status,
            data: data,
            arguments: arguments,
            lastFinishedAt: lastFinishedAt,
            isReported: isReported,
            timeStart: timeStart ?? new DateTime.now().millisecondsSinceEpoch,
            isFunderJob: isFunderJob);

  @override
  fetch() async {
    return api.getJob(this.id);
  }

  @override
  onDone(store, dynamic fetchedData) async {
    final logger = await AppFactory().getLogger('Job');
    if (isReported == true) {
      this.status = 'FAILED';
      logger.info('JoinCommunityJob FAILED');
      store.dispatch(transactionFailed(arguments['transfer'], arguments['communityAddress']));
      store.dispatch(segmentTrackCall('Wallet: JoinCommunityJob FAILED'));
      return;
    }
    Job job = JobFactory.create(fetchedData);
    int current = DateTime.now().millisecondsSinceEpoch;
    int jobTime = this.timeStart;
    final int millisecondsIntoMin = 2 * 60 * 1000;
    if ((current - jobTime) > millisecondsIntoMin && isReported != null && !isReported) {
      store.dispatch(segmentTrackCall('Wallet: pending job', properties: new Map<String, dynamic>.from({ 'id': id, 'name': name })));
    }

    if (fetchedData['failReason'] != null && fetchedData['failedAt'] != null) {
      logger.info('JoinCommunityJob FAILED');
      this.status = 'FAILED';
      String failReason = fetchedData['failReason'];
      store.dispatch(transactionFailed(arguments['transfer'], arguments['communityAddress']));
      store.dispatch(segmentTrackCall('Wallet: job failed', properties: new Map<String, dynamic>.from({ 'id': id, 'failReason': failReason, 'name': name })));
      return;
    }

    Transfer transfer = arguments['transfer'];
    String txHash = job.data['txHash'];
    Transfer confirmedTx = transfer.copyWith(txHash: txHash);
    if (![null, ''].contains(txHash)) {
      logger.info('JoinCommunityJob txHash txHash txHash $txHash');
      store.dispatch(new ReplaceTransaction(
          transaction: transfer,
          transactionToReplace: confirmedTx,
          communityAddress: arguments['communityAddress']));
      arguments['transfer'] = confirmedTx.copyWith();
      store.dispatch(UpdateJob(communityAddress: arguments['communityAddress'], job: this));
    }

    if (job.lastFinishedAt == null || job.lastFinishedAt.isEmpty) {
      logger.info('JoinCommunityJob not done');
      return;
    }
    this.status = 'DONE';
    store.dispatch(joinCommunitySuccessCall(job, fetchedData, confirmedTx, arguments['communityAddress'], arguments['communityName'], arguments['joinBonusPlugin'], arguments['token']));
    store.dispatch(segmentTrackCall('Wallet: job succeeded', properties: new Map<String, dynamic>.from({ 'id': id, 'name': name })));
  }

  @override
  dynamic argumentsToJson() => {
      'transfer': arguments['transfer'].toJson(),
      'communityAddress': arguments['communityAddress'],
      'communityName': arguments['communityName'],
      'joinBonusPlugin': arguments['joinBonusPlugin']?.toJson(),
      'token': arguments['token']?.toJson()
    };

  @override
  Map<String, dynamic> argumentsFromJson(arguments) {
    if (arguments == null) {
      return arguments;
    }
    if (arguments.containsKey('transfer')) {
      Map<String, dynamic> nArgs = Map<String, dynamic>.from(arguments);
      if (arguments['transfer'] is Map) {
        nArgs['transfer'] = TransactionFactory.fromJson(arguments['transfer']);
      }
      if (arguments['token'] is Map) {
        nArgs['token'] = Token.fromJson(arguments['token']);
      }
      if (arguments['joinBonusPlugin'] is Map) {
        nArgs['joinBonusPlugin'] = JoinBonusPlugin.fromJson(arguments['joinBonusPlugin']);
      }
      return nArgs;
    }
    return arguments;
  }

  static JoinCommunityJob fromJson(dynamic json) => _$JoinCommunityJobFromJson(json);
}