import 'package:tcc_3/common/models/transaction_model.dart';

abstract class HomeState {}

class HomeStateInitial extends HomeState {}

class HomeStateLoading extends HomeState {}

class HomeStateSuccess extends HomeState {
  final List<TransactionModel> transactions;
  
  HomeStateSuccess(this.transactions);
}

class HomeStateError extends HomeState {
  final String error;
  
  HomeStateError(this.error);
}