import 'package:walleta/core/voice_transaction/model/extracted_transaction.dart';
import 'package:walleta/screen/chart/viewmodel/add_transaction_viewmodel.dart';

abstract class TransactionExtractionService {
  Future<ExtractedTransaction> extract(
    String text,
    List<Category> categories, {
    String language,
  });
  ExtractionTier get tier;
}
