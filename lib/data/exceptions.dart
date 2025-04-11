abstract class Failure implements Exception {
  const Failure();

  String get message;

  @override
  String toString() {
    return '$runtimeType Exception';
  }
}

class GeneralException extends Failure {
  const GeneralException();

  @override
  String get message => 'An error has occurred. Please try again later.';
}

//API Exceptions

class APIException extends Failure {
  const APIException({
    required this.code,
    this.textCode,
  });

  final int code;
  final String? textCode;

  @override
  String get message {
    if (textCode != null) {
      switch (textCode) {
        case 'invalid-headers':
        case 'validation-failed':
          return 'Bad request. Check you request and try again.';
        default:
          return 'An internal error ocurred. Please try again later.';
      }
    }
    switch (code) {
      case 400:
        return 'Bad request. Check you request and try again.';
      case 401:
        return 'User not authorized to access this resource at this time. Please reauthenticate';
      case 404:
        return 'It was not possible to finish this operation. Please try again later';
      case 503:
        return 'Service unavailable at this time. Please try again later.';
      default:
        return 'An internal error ocurred. Please try again later.';
    }
  }
}

//Services Exceptions
class AuthException extends Failure {
  const AuthException({
    required this.code,
  });

  final String code;

  @override
  String get message {
    switch (code) {
  case 'user-not-authenticated':
    return 'Sua sessão expirou. Por favor, faça login novamente.';
  case 'email-already-exists':
    return 'O e-mail fornecido já está em uso. Verifique suas informações ou crie uma nova conta.';
  case 'user-not-found':
  case 'wrong-password':
    return 'E-mail ou senha incorretos. Verifique suas informações ou crie uma nova conta.';
  case 'network-request-failed':
    return 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.';
  case 'internal':
    return 'Não foi possível criar sua conta neste momento. Verifique suas informações e tente novamente.';
  default:
    return 'Ocorreu um erro durante a autenticação. Por favor, tente novamente mais tarde.';
}

    }
  }


class SecureStorageException extends Failure {
  const SecureStorageException();

  @override
  String get message => 'An error has occurred while fetching Secure Storage.';
}

class CacheException extends Failure {
  const CacheException();

  @override
  String get message => 'An error has occurred while fetching Local Cache.';
}

//System Exceptions
class ConnectionException extends Failure {
  const ConnectionException({
    required this.code,
  });

  final String code;

  @override
  String get message {
    switch (code) {
      case 'connection-error':
        return 'It was not possible to connect to the remote server. Please check you connection and try again.';
      default:
        return 'An internal error ocurred. Please try again later.';
    }
  }
}