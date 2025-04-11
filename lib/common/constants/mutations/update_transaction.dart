// update_transaction.dart - Versão Corrigida
const String mUpdateTransaction = r"""
mutation updateTransaction(
  $id: uuid!
  $category: String!
  $date: timestamptz!
  $description: String!
  $status: Boolean!
  $value: numeric!
) {
  update_transaction_by_pk(
    pk_columns: {id: $id}
    _set: {
      category: $category
      date: $date
      description: $description
      status: $status
      value: $value
    }
  ) {
    id
    category
    date
    description
    status
    value
  }
}
""";