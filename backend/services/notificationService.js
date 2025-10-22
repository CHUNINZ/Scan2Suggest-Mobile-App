const Notification = require('../models/Notification');

class NotificationService {
  /**
   * Send a notification to a user
   * @param {Object} options - Notification options
   * @param {string} options.recipientId - ID of the user receiving the notification
   * @param {string} options.senderId - ID of the user sending the notification
   * @param {string} options.type - Type of notification
   * @param {string} options.title - Notification title
   * @param {string} options.message - Notification message
   * @param {Object} options.data - Additional data (recipeId, etc.)
   * @param {Object} options.io - Socket.IO instance for real-time notifications
   */
  static async sendNotification({
    recipientId,
    senderId,
    type,
    title,
    message,
    data = {},
    io = null
  }) {
    try {
      // Don't send notification to self
      if (recipientId.toString() === senderId.toString()) {
        return null;
      }

      // Create notification in database
      const notification = new Notification({
        recipient: recipientId,
        sender: senderId,
        type,
        title,
        message,
        data
      });

      await notification.save();

      // Populate sender info for real-time notification
      await notification.populate('sender', 'name profileImage');

      // Send real-time notification if Socket.IO is available
      if (io) {
        io.to(`user_${recipientId}`).emit('notification', {
          _id: notification._id,
          type,
          title,
          message,
          data,
          sender: notification.sender,
          createdAt: notification.createdAt
        });
      }

      return notification;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  }

  /**
   * Send like notification
   */
  static async sendLikeNotification(recipe, liker, io) {
    return await this.sendNotification({
      recipientId: recipe.creator,
      senderId: liker._id,
      type: 'like',
      title: 'Recipe Liked',
      message: `${liker.name} liked your recipe "${recipe.title}"`,
      data: { recipeId: recipe._id },
      io
    });
  }

  /**
   * Send bookmark notification
   */
  static async sendBookmarkNotification(recipe, bookmarker, io) {
    return await this.sendNotification({
      recipientId: recipe.creator,
      senderId: bookmarker._id,
      type: 'bookmark',
      title: 'Recipe Bookmarked',
      message: `${bookmarker.name} bookmarked your recipe "${recipe.title}"`,
      data: { recipeId: recipe._id },
      io
    });
  }

  /**
   * Send rating notification
   */
  static async sendRatingNotification(recipe, rater, rating, review, io) {
    return await this.sendNotification({
      recipientId: recipe.creator,
      senderId: rater._id,
      type: 'rating',
      title: 'New Rating',
      message: `${rater.name} rated your recipe "${recipe.title}" ${rating} star${rating > 1 ? 's' : ''}`,
      data: { 
        recipeId: recipe._id,
        rating: rating,
        review: review
      },
      io
    });
  }

  /**
   * Send comment notification
   */
  static async sendCommentNotification(recipe, commenter, commentText, io) {
    return await this.sendNotification({
      recipientId: recipe.creator,
      senderId: commenter._id,
      type: 'comment',
      title: 'New Comment',
      message: `${commenter.name} commented on your recipe "${recipe.title}"`,
      data: { 
        recipeId: recipe._id,
        commentText: commentText
      },
      io
    });
  }

  /**
   * Send follow notification
   */
  static async sendFollowNotification(followedUser, follower, io) {
    return await this.sendNotification({
      recipientId: followedUser._id,
      senderId: follower._id,
      type: 'follow',
      title: 'New Follower',
      message: `${follower.name} started following you`,
      data: {},
      io
    });
  }

  /**
   * Send share notification
   */
  static async sendShareNotification(recipe, sharer, platform, io) {
    return await this.sendNotification({
      recipientId: recipe.creator,
      senderId: sharer._id,
      type: 'share',
      title: 'Recipe Shared',
      message: `${sharer.name} shared your recipe "${recipe.title}" on ${platform}`,
      data: { 
        recipeId: recipe._id,
        platform: platform
      },
      io
    });
  }

  /**
   * Send recipe featured notification
   */
  static async sendRecipeFeaturedNotification(recipe, io) {
    return await this.sendNotification({
      recipientId: recipe.creator,
      senderId: null, // System notification
      type: 'recipe_featured',
      title: 'Recipe Featured',
      message: `Your recipe "${recipe.title}" has been featured!`,
      data: { recipeId: recipe._id },
      io
    });
  }

  /**
   * Send system notification
   */
  static async sendSystemNotification(recipientId, title, message, data = {}, io) {
    return await this.sendNotification({
      recipientId,
      senderId: null, // System notification
      type: 'system',
      title,
      message,
      data,
      io
    });
  }

  /**
   * Get notification statistics for a user
   */
  static async getNotificationStats(userId) {
    try {
      const stats = await Notification.aggregate([
        { $match: { recipient: userId, isDeleted: false } },
        {
          $group: {
            _id: null,
            total: { $sum: 1 },
            unread: {
              $sum: { $cond: [{ $eq: ['$isRead', false] }, 1, 0] }
            },
            byType: {
              $push: {
                type: '$type',
                isRead: '$isRead'
              }
            }
          }
        }
      ]);

      const userStats = stats[0] || { total: 0, unread: 0, byType: [] };

      // Group by type
      const typeStats = {};
      userStats.byType.forEach(item => {
        if (!typeStats[item.type]) {
          typeStats[item.type] = { total: 0, unread: 0 };
        }
        typeStats[item.type].total += 1;
        if (!item.isRead) {
          typeStats[item.type].unread += 1;
        }
      });

      return {
        total: userStats.total,
        unread: userStats.unread,
        read: userStats.total - userStats.unread,
        byType: typeStats
      };
    } catch (error) {
      console.error('Error getting notification stats:', error);
      return { total: 0, unread: 0, read: 0, byType: {} };
    }
  }

  /**
   * Mark notification as read
   */
  static async markAsRead(notificationId, userId) {
    try {
      const notification = await Notification.findOne({
        _id: notificationId,
        recipient: userId,
        isDeleted: false
      });

      if (!notification) {
        return false;
      }

      notification.isRead = true;
      notification.readAt = new Date();
      await notification.save();

      return true;
    } catch (error) {
      console.error('Error marking notification as read:', error);
      return false;
    }
  }

  /**
   * Mark all notifications as read for a user
   */
  static async markAllAsRead(userId) {
    try {
      await Notification.updateMany(
        { 
          recipient: userId,
          isRead: false,
          isDeleted: false
        },
        { 
          isRead: true,
          readAt: new Date()
        }
      );

      return true;
    } catch (error) {
      console.error('Error marking all notifications as read:', error);
      return false;
    }
  }

  /**
   * Delete notification
   */
  static async deleteNotification(notificationId, userId) {
    try {
      const notification = await Notification.findOne({
        _id: notificationId,
        recipient: userId,
        isDeleted: false
      });

      if (!notification) {
        return false;
      }

      notification.isDeleted = true;
      notification.deletedAt = new Date();
      await notification.save();

      return true;
    } catch (error) {
      console.error('Error deleting notification:', error);
      return false;
    }
  }

  /**
   * Delete all notifications for a user
   */
  static async deleteAllNotifications(userId) {
    try {
      await Notification.updateMany(
        { 
          recipient: userId,
          isDeleted: false
        },
        { 
          isDeleted: true,
          deletedAt: new Date()
        }
      );

      return true;
    } catch (error) {
      console.error('Error deleting all notifications:', error);
      return false;
    }
  }
}

module.exports = NotificationService;
