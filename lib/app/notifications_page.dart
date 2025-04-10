import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'account_page.dart';

class NotificationsPage extends StatefulWidget {
  final String userId;
  NotificationsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isBellTapped = false;
  bool _hasNewNotification = false;
  bool _isEditing = false;
  List<String> _selectedNotifications = [];

  final CollectionReference notificationsCollection =
      FirebaseFirestore.instance.collection('Notifications');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.jpg',
              width: 120,
              fit: BoxFit.contain,
            ),
            Spacer(),
            IconButton(
              icon: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isBellTapped
                        ? Color(0xFF8B0000)
                        : _hasNewNotification
                            ? Colors.red
                            : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.notifications,
                  color: _isBellTapped
                      ? Colors.red
                      : _hasNewNotification
                          ? Colors.red
                          : Color(0xFF8B0000),
                ),
              ),
              onPressed: () {
                setState(() {
                  _isBellTapped = !_isBellTapped;
                  _hasNewNotification = false;
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotificationsPage(userId: widget.userId),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccountPage(userId: widget.userId),
                    ),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: Color(0xFF8B0000),
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isEditing)
                  InkWell(
                    onTap: () {
                      _markAllAsRead();
                    },
                    highlightColor: Colors.red.withOpacity(0.1),
                    splashColor: Colors.red.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        "Mark all as read",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B0000),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF8B0000),
                        ),
                      ),
                    ),
                  ),
                if (_isEditing && _selectedNotifications.isNotEmpty)
                  InkWell(
                    onTap: () {
                      _showDeleteConfirmationDialog();
                    },
                    highlightColor: Colors.red.withOpacity(0.1),
                    splashColor: Colors.red.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        "Delete (${_selectedNotifications.length})",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.red,
                        ),
                      ),
                    ),
                  )
                else
                  Container(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isEditing = !_isEditing;
                      if (!_isEditing) {
                        _selectedNotifications.clear();
                      }
                    });
                  },
                  highlightColor: Colors.red.withOpacity(0.1),
                  splashColor: Colors.red.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      _isEditing ? "Cancel" : "Edit",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B0000),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF8B0000),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: notificationsCollection
                    .where('userID', isEqualTo: widget.userId)
                    .orderBy('Timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading notifications'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No notifications found'));
                  }

                  final notifications = snapshot.data!.docs;
                  _hasNewNotification = notifications.any(
                    (notification) =>
                        (notification.data()
                            as Map<String, dynamic>)['status'] ==
                        'Unread',
                  );

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification =
                          notifications[index].data() as Map<String, dynamic>;
                      String notificationId = notifications[index].id;
                      String message = notification['message'] ?? 'No message';
                      String emailAddress = notification['emailAddress'] ?? '';
                      String status = notification['status'] ?? 'Unread';
                      Timestamp timestamp =
                          notification['Timestamp'] ?? Timestamp.now();
                      DateTime dateTime = timestamp.toDate();
                      String formattedDate =
                          '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}';
                      String formattedTime =
                          '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
                      bool isRead = status == 'Read';

                      return buildNotificationItem(
                        context, // Pass the context here
                        notificationId, // Pass the notificationId
                        'Notification from $emailAddress',
                        message,
                        formattedDate,
                        formattedTime,
                        isRead,
                        isSelected:
                            _selectedNotifications.contains(notificationId),
                        isEditing: _isEditing,
                        onTap: () {
                          if (_isEditing) {
                            setState(() {
                              if (_selectedNotifications
                                  .contains(notificationId)) {
                                _selectedNotifications.remove(notificationId);
                              } else {
                                _selectedNotifications.add(notificationId);
                              }
                            });
                          } else {
                            if (!isRead) {
                              notificationsCollection
                                  .doc(notificationId)
                                  .update({'status': 'Read'});
                            }
                            // Navigate to details page
                            _navigateToNotificationDetails(
                                context, notification);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month - 1];
  }

  Widget buildNotificationItem(
    BuildContext context, // Add BuildContext
    String notificationId, // Add notificationId
    String title,
    String message,
    String date,
    String time,
    bool isRead, {
    bool isSelected = false,
    bool isEditing = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.red[100]
                : isRead
                    ? Colors.white
                    : Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Color(0xFF8B0000), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                if (isEditing)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? Color(0xFF8B0000) : Colors.grey,
                    ),
                  ),
                CircleAvatar(
                  backgroundColor: isSelected
                      ? Color(0xFF8B0000)
                      : isRead
                          ? Colors.red.shade200
                          : Color(0xFF8B0000),
                  radius: 24,
                  child: Icon(
                    Icons.notifications,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14, // Smaller title font size
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B0000),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        message,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$date at $time',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isEditing)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Colors.grey[200]
                          : Color(0xFF8B0000).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isRead ? "Read" : "New",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isRead ? Colors.black54 : Color(0xFF8B0000),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToNotificationDetails(
      BuildContext context, Map<String, dynamic> notificationData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NotificationDetailsPage(notificationData: notificationData),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Notifications"),
          content: Text(
              "Are you sure you want to delete ${_selectedNotifications.length} notification(s)?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel", style: TextStyle(color: Color(0xFF8B0000))),
            ),
            TextButton(
              onPressed: () {
                _deleteSelectedNotifications();
                Navigator.of(context).pop();
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteSelectedNotifications() async {
    try {
      for (String notificationId in _selectedNotifications) {
        await notificationsCollection.doc(notificationId).delete();
      }
      setState(() {
        _selectedNotifications.clear();
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Notifications deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete notifications"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _markAllAsRead() async {
    try {
      final querySnapshot = await notificationsCollection
          .where('userID', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'Unread')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'status': 'Read'});
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All notifications marked as read"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to mark notifications as read"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class NotificationDetailsPage extends StatelessWidget {
  final Map<String, dynamic> notificationData;

  NotificationDetailsPage({required this.notificationData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification from ${notificationData['emailAddress'] ?? ''}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              notificationData['message'] ?? 'No message',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '${DateTime.fromMillisecondsSinceEpoch(notificationData['Timestamp'].millisecondsSinceEpoch)}',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
