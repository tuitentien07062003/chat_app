import 'dart:typed_data';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/friend_request_model.dart';
import 'package:chat_app/models/friendship_model.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/notification_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('${e.toString()} An error occurred while creating user');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('${e.toString()} An error occurred while fetching user');
    }
  }

  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'isOnline': isOnline,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while updating online status',
      );
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('${e.toString()} An error occurred while deleting user');
    }
  }

  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('${e.toString()} An error occurred while updating user');
    }
  }

  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> sendFriendRequest(FriendRequestModel request) async {
    try {
      await _firestore
          .collection('friendRequests')
          .doc(request.id)
          .set(request.toMap());

      String notificationId =
          'friend_request_${request.senderId}_${request.receiverId}_${DateTime.now().millisecondsSinceEpoch}';

      await createNotification(
        NotificationModel(
          id: notificationId,
          userId: request.receiverId,
          title: 'New Friend Request',
          body: 'You have a new friend request from ${request.senderId}',
          type: NotificationType.friendRequest,
          data: {'senderId': request.senderId, 'requestId': request.id},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while sending friend request',
      );
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .get();

      if (doc.exists) {
        FriendRequestModel request = FriendRequestModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        await _firestore.collection('friendRequests').doc(requestId).delete();

        await deleteNotiByTypeAndUser(
          request.receiverId,
          NotificationType.friendRequest,
          request.senderId,
        );
      }
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while canceling friend request',
      );
    }
  }

  Future<void> respondToFriendRequest(
    String requestId,
    FriendRequestStatus status,
  ) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': status.toString().split('.').last,
        'respondedAt': DateTime.now().millisecondsSinceEpoch,
      });

      DocumentSnapshot doc = await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .get();

      if (doc.exists) {
        FriendRequestModel request = FriendRequestModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        if (status == FriendRequestStatus.accepted) {
          await createFriendShip(request.senderId, request.receiverId);

          await createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: request.senderId,
              title: 'Friend Request Accepted',
              body: '${request.receiverId} accepted your friend request',
              type: NotificationType.friendRequestAccepted,
              data: {'userId': request.receiverId},
              createdAt: DateTime.now(),
            ),
          );

          await _removeNotiCancelledRequest(
            request.receiverId,
            request.senderId,
          );
        } else if (status == FriendRequestStatus.declined) {
          await createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: request.senderId,
              title: 'Friend Request Declined',
              body: '${request.receiverId} declined your friend request',
              type: NotificationType.friendRequestDeclined,
              data: {'userId': request.receiverId},
              createdAt: DateTime.now(),
            ),
          );

          await _removeNotiCancelledRequest(
            request.receiverId,
            request.senderId,
          );
        }
      }
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to friend request',
      );
    }
  }

  Stream<List<FriendRequestModel>> getFriendRequestsStream(String userId) {
    return _firestore
        .collection("friendRequests")
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<FriendRequestModel>> getSentFriendRequestsStrean(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<FriendRequestModel?> getFriendRequest(
    String senderId,
    String receiverId,
  ) async {
    try {
      QuerySnapshot query = await _firestore
          .collection("friendRequests")
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();
      if (query.docs.isNotEmpty) {
        return FriendRequestModel.fromMap(
          query.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to get friend request',
      );
    }
  }

  // FRIENDSHIPS

  Future<void> createFriendShip(String userId, String friendId) async {
    try {
      List<String> userIds = [userId, friendId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      FriendshipModel friendShip = FriendshipModel(
        id: friendShipId,
        userId: userIds[0],
        friendId: userIds[1],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .set(friendShip.toMap());
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to create friendship',
      );
    }
  }

  Future<void> removeFriendShip(String userId, String friendId) async {
    try {
      List<String> userIds = [userId, friendId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      await _firestore.collection('friendships').doc(friendShipId).delete();
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to remove friendship',
      );
    }
  }

  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      List<String> userIds = [blockerId, blockedId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      await _firestore.collection('friendships').doc(friendShipId).update({
        'id': friendShipId,
        'userId': userIds[0],
        'friendId': userIds[1],
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isBlocked': true,
        'blockedBy': blockerId,
      });

      QuerySnapshot sentRequests = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: blockerId)
          .where('receiverId', isEqualTo: blockedId)
          .get();

      QuerySnapshot receivedRequests = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: blockedId)
          .where('receiverId', isEqualTo: blockerId)
          .get();

      for (var doc in sentRequests.docs) {
        await doc.reference.delete();
      }
      for (var doc in receivedRequests.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to block friend',
      );
    }
  }

  Future<void> unBlockUser(String blockerId, String blockedId) async {
    try {
      List<String> userIds = [blockerId, blockedId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      await _firestore.collection('friendships').doc(friendShipId).delete();
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to block friend',
      );
    }
  }

  Stream<List<FriendshipModel>> getBlockedUsersStream(String userId) {
    return _firestore
        .collection('friendships')
        .where('isBlocked', isEqualTo: true)
        .where('blockedBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    FriendshipModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  Stream<List<FriendshipModel>> getFriendsStream(String userId) {
    return _firestore
        .collection('friendships')
        .where(
          Filter.or(
            Filter('userId', isEqualTo: userId),
            Filter('friendId', isEqualTo: userId),
          ),
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    FriendshipModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .where((f) => !f.isBlocked)
              .toList();
        });
  }

  // Stream<List<FriendshipModel>> getFriendsStream(String userId) {
  //   return _firestore
  //       .collection('friendships')
  //       .where('userId', isEqualTo: userId)
  //       .snapshots()
  //       .asyncMap((snapshot1) async {
  //         QuerySnapshot snapshot2 = await _firestore
  //             .collection('friendships')
  //             .where('friendId', isEqualTo: userId)
  //             .get();

  //         List<FriendshipModel> friendships = [];

  //         for (var doc in snapshot1.docs) {
  //           friendships.add(
  //             FriendshipModel.fromMap(doc.data() as Map<String, dynamic>),
  //           );
  //         }

  //         for (var doc in snapshot2.docs) {
  //           friendships.add(
  //             FriendshipModel.fromMap(doc.data() as Map<String, dynamic>),
  //           );
  //         }

  //         return friendships.where((f) => !f.isBlocked).toList();
  //       });
  // }

  Stream<List<FriendshipModel>> getAllRelationshipsStream(String userId) {
    return _firestore
        .collection('friendships')
        .where(
          Filter.or(
            Filter('userId', isEqualTo: userId),
            Filter('friendId', isEqualTo: userId),
          ),
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    FriendshipModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  Future<FriendshipModel?> getFriendships(
    String userId,
    String friendId,
  ) async {
    try {
      List<String> userIds = [userId, friendId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .get();

      if (doc.exists) {
        return FriendshipModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to get friend',
      );
    }
  }

  Future<bool> isUserBlocked(String userId, String otherUserId) async {
    try {
      List<String> userIds = [userId, otherUserId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .get();

      if (doc.exists) {
        FriendshipModel friendship = FriendshipModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        return friendship.isBlocked;
      }

      return false;
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to ...',
      );
    }
  }

  Future<bool> isUnFriended(String userId, String otherUserId) async {
    try {
      List<String> userIds = [userId, otherUserId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .get();

      if (!doc.exists || doc.data() == null) return true;

      FriendshipModel friendship = FriendshipModel.fromMap(
        doc.data() as Map<String, dynamic>,
      );
      return friendship.isBlocked;
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to ...',
      );
    }
  }

  Future<List<UserModel>> getForwardableFriends(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('friendships')
          .where(
            Filter.or(
              Filter('userId', isEqualTo: userId),
              Filter('friendId', isEqualTo: userId),
            ),
          )
          .get();

      List<String> friendIds = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bool isBlocked = data['isBlocked'] ?? false;

        if (!isBlocked) {
          String otherId = data['userId'] == userId
              ? data['friendId']
              : data['userId'];
          friendIds.add(otherId);
        }
      }

      if (friendIds.isEmpty) return [];

      List<UserModel> validFriends = [];
      for (String id in friendIds) {
        UserModel? user = await getUser(id);
        if (user != null) {
          validFriends.add(user);
        }
      }

      return validFriends;
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while fetching forwardable friends',
      );
    }
  }

  // CHAT

  Future<DocumentSnapshot> getChatDoc(String chatId) async {
    try {
      return await _firestore.collection('chats').doc(chatId).get();
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while fetching chat document',
      );
    }
  }

  Future<String> createOrGetChat(String userId1, String userId2) async {
    try {
      List<String> participants = [userId1, userId2];
      participants.sort();

      String chatId = '${participants[0]}_ ${participants[1]}';

      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
      DocumentSnapshot chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        ChatModel newChat = ChatModel(
          id: chatId,
          participants: participants,
          unreadCounts: {userId1: 0, userId2: 0},
          deletedBy: {userId1: false, userId2: false},
          deletedAt: {userId1: null, userId2: null},
          lastSeenBy: {userId1: DateTime.now(), userId2: DateTime.now()},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await chatRef.set(newChat.toMap());
      } else {
        ChatModel existingChat = ChatModel.fromMap(
          chatDoc.data() as Map<String, dynamic>,
        );

        if (existingChat.isDeletedBy(userId1)) {
          await restoreChatForUser(chatId, userId1);
        }

        if (existingChat.isDeletedBy(userId2)) {
          await restoreChatForUser(chatId, userId2);
        }
      }

      return chatId;
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to create or get chat',
      );
    }
  }

  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data()))
              .where((chat) => !chat.isDeletedBy(userId))
              .toList(),
        );
  }

  Future<void> updateChatLastMessage(String chatId, String message) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        // 'lastMessageTime': message.timestamp.microsecondsSinceEpoch,
        // 'lastMessageSenderId': message.senderId,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to update chat last message',
      );
    }
  }

  Future<void> updateUserLastSeen(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastSeenBy.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to update last seen',
      );
    }
  }

  Future<void> deleteChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy.$userId': true,
        'deletedAt.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to delete chat',
      );
    }
  }

  Future<void> restoreChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy.$userId': false,
      });
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to restore chat',
      );
    }
  }

  Future<void> updateUnreadCount(
    String chatId,
    String userId,
    int count,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts.$userId': count,
      });
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to update unread count',
      );
    }
  }

  Future<void> restoreUnreadCount(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts.$userId': 0,
      });
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to restore unread count',
      );
    }
  }

  // MESSAGES

  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestore
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());

      String chatId = await createOrGetChat(
        message.senderId,
        message.receiverId,
      );

      await updateChatLastMessage(chatId, message.content);
      await updateUserLastSeen(chatId, message.senderId);

      DocumentSnapshot chatDoc = await _firestore
          .collection("chats")
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        ChatModel chat = ChatModel.fromMap(
          chatDoc.data() as Map<String, dynamic>,
        );

        int currentUnread = chat.getUnreadCount(message.receiverId);
        await updateUnreadCount(chatId, message.receiverId, currentUnread + 1);
      }

      String notificationBody = message.content;
      if (message.type == MessageType.icon) {
        notificationBody = "👍 Đã gửi một icon";
      }

      final notiId = _firestore.collection("notifications").doc().id;
      NotificationModel noti = NotificationModel(
        id: notiId,
        userId: message.receiverId,
        title: "Bạn nhận được tin nhắn mới",
        body: notificationBody,
        type: NotificationType.newMessage,
        createdAt: DateTime.now(),
        isRead: false,
        data: {
          "chatId": chatId,
          "senderId": message.senderId,
          "userId": message.senderId,
        },
      );

      await createNotification(noti);
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to send message',
      );
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String userId1, String userId2) {
    return _firestore
        .collection('messages')
        .where('senderId', whereIn: [userId1, userId2])
        .snapshots()
        .asyncMap((snapshot) async {
          List<String> participants = [userId1, userId2];
          participants.sort();
          String chatId = '${participants[0]}_ ${participants[1]}';

          DocumentSnapshot chatDoc = await _firestore
              .collection('chats')
              .doc(chatId)
              .get();

          ChatModel? chat;
          if (chatDoc.exists) {
            chat = ChatModel.fromMap(chatDoc.data() as Map<String, dynamic>);
          }

          List<MessageModel> messages = [];
          for (var doc in snapshot.docs) {
            MessageModel message = MessageModel.fromMap(doc.data());
            if ((message.senderId == userId1 &&
                    message.receiverId == userId2) ||
                (message.senderId == userId2 &&
                    message.receiverId == userId1)) {
              bool includeMessage = true;

              if (chat != null) {
                DateTime? currentUserDeletedAt = chat.getDeletedAt(userId1);
                if (currentUserDeletedAt != null &&
                    message.timestamp.isBefore(currentUserDeletedAt)) {
                  includeMessage = false;
                }
              }

              if (includeMessage) {
                messages.add(message);
              }
            }
          }
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages;
        });
  }

  Future<void> updateMessageReaction(
    String messageId,
    String userId,
    String? iconName,
  ) async {
    try {
      final docRef = _firestore.collection('messages').doc(messageId);
      if (iconName == null) {
        await docRef.update({'reactions.$userId': FieldValue.delete()});
      } else {
        await docRef.update({'reactions.$userId': iconName});
      }
    } catch (e) {
      throw Exception('Error updating reaction: ${e.toString()}');
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to mark message',
      );
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isDeleted': true,
        'content': 'Tin nhắn đã bị xóa',
        'deletedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to delete message',
      );
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'content': newContent,
        'isEdited': true,
        'editedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to edit message',
      );
    }
  }

  // NOTIFICATIONS

  Future<void> createNotification(NotificationModel noti) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(noti.id)
          .set(noti.toMap());
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to create notifications',
      );
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> markNotiAsRead(String notiId) async {
    try {
      await _firestore.collection('notifications').doc(notiId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to mark noti',
      );
    }
  }

  Future<void> markAllNotiAsRead(String userId) async {
    try {
      QuerySnapshot noti = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in noti.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to mark all noti',
      );
    }
  }

  Future<void> deleteNotifications(String notiId) async {
    try {
      await _firestore.collection('notifications').doc(notiId).delete();
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to delete noti',
      );
    }
  }

  Future<void> deleteNotiByTypeAndUser(
    String userId,
    NotificationType type,
    String relatedUserId,
  ) async {
    try {
      QuerySnapshot noti = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in noti.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['data'] != null &&
            (data['data']['senderId'] == relatedUserId ||
                data['data']['userId'] == relatedUserId)) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to delete noti by type and user',
      );
    }
  }

  Future<void> _removeNotiCancelledRequest(
    String receiverId,
    String senderId,
  ) async {
    try {
      await deleteNotiByTypeAndUser(
        receiverId,
        NotificationType.friendRequest,
        senderId,
      );
    } catch (e) {
      throw Exception(
        '${e.toString()} An error occurred while responding to remove noti for cancelled resquest',
      );
    }
  }

  // IMAGE & FILE

  Future<String> uploadToCloudinary(
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

      if (cloudName == null || uploadPreset == null) {
        throw Exception("Thiếu cấu hình Cloudinary trong file .env");
      }

      final String extension = p.extension(fileName).toLowerCase();
      String resourceType = 'raw';

      if ([
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.webp',
        '.bmp',
        '.svg',
      ].contains(extension)) {
        resourceType = 'image';
      } else if ([
        '.mp4',
        '.mov',
        '.avi',
        '.mkv',
        '.mp3',
        '.wav',
        '.aac',
      ].contains(extension)) {
        resourceType = 'video';
      }

      final String url =
          "https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload";

      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(fileBytes, filename: fileName),
        "upload_preset": uploadPreset,
      });

      Dio dio = Dio();
      Response response = await dio.post(url, data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['secure_url'];
      } else {
        throw Exception(
          "Lỗi từ Cloudinary: ${response.statusCode} - ${response.data}",
        );
      }
    } catch (e) {
      throw Exception('Lỗi upload file: ${e.toString()}');
    }
  }
}
