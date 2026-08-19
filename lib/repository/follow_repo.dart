import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class FollowRepo {
  Future<ApiResponse> requestFollow({required String userId}) {
    return ApiHandler.request(
      api: Api.follow.request(userId),
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> unfollow({required String userId}) {
    return ApiHandler.request(
      api: Api.follow.unfollow(userId),
      method: ApiMethod.delete,
      authorization: true,
    );
  }

  Future<ApiResponse> accept({required String followId}) {
    return ApiHandler.request(
      api: Api.follow.accept(followId),
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> decline({required String followId}) {
    return ApiHandler.request(
      api: Api.follow.decline(followId),
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> notifications() {
    return ApiHandler.request(
      api: Api.follow.notifications,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> markAllRead() {
    return ApiHandler.request(
      api: Api.follow.markAllRead,
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> markRead({required String followId}) {
    return ApiHandler.request(
      api: Api.follow.markRead(followId),
      method: ApiMethod.post,
      authorization: true,
    );
  }
}
