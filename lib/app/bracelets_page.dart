import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notifications_page.dart';
import 'account_page.dart';

class BraceletsPage extends StatefulWidget {
  final String userId;

  const BraceletsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _BraceletsPageState createState() => _BraceletsPageState();
}

class _BraceletsPageState extends State<BraceletsPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final CollectionReference braceletsCollection = FirebaseFirestore.instance
      .collection('Bracelet'); // Updated collection name

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    _fadeController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _addBracelet(String braceletName) async {
    try {
      await braceletsCollection.add({
        "braceletID":
            braceletName, // Use the user-provided name instead of generating one
        "purchaseDate": Timestamp.now(),
        "usageStatus": "Active",
        "userID": widget.userId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bracelet added successfully")),
      );
    } catch (e) {
      print("Error adding bracelet: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add bracelet")),
      );
    }
  }

  Future<void> _editBracelet(String documentId, String newName) async {
    try {
      await braceletsCollection.doc(documentId).update({
        "braceletID": newName, // Updating the braceletID
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bracelet updated successfully")),
      );
    } catch (e) {
      print("Error updating bracelet: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update bracelet")),
      );
    }
  }

  Future<void> _deleteBracelet(String documentId) async {
    try {
      await braceletsCollection.doc(documentId).delete();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bracelet deleted successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error deleting bracelet: $e");
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete bracelet'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddBraceletDialog() {
    String braceletName = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Bracelet", style: GoogleFonts.poppins()),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Bracelet ID',
              labelStyle: GoogleFonts.poppins(),
              hintText: 'e.g., BRACLET_001',
            ),
            style: GoogleFonts.poppins(),
            onChanged: (value) => braceletName = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B0000),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (braceletName.trim().isNotEmpty) {
                  _addBracelet(braceletName.trim());
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Add',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B0000),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(DocumentSnapshot bracelet) {
    String newName = bracelet['braceletID'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Bracelet", style: GoogleFonts.poppins()),
          content: TextField(
            controller: TextEditingController(text: newName),
            decoration: InputDecoration(
              labelText: 'Bracelet ID',
              labelStyle: GoogleFonts.poppins(),
            ),
            style: GoogleFonts.poppins(),
            onChanged: (value) => newName = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B0000),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (newName.trim().isNotEmpty) {
                  _editBracelet(bracelet.id, newName.trim());
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B0000),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: false,
            backgroundColor: Colors.white,
            elevation: 0,
            expandedHeight: 100.0,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Hero(
                      tag: 'logoHero',
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NotificationsPage(userId: widget.userId),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.notifications,
                                color: Color(0xFF8B0000),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 7),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AccountPage(userId: widget.userId),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF8B0000),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Bracelets',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B0000),
                        ),
                      ),
                      TextButton(
                        onPressed: _showAddBraceletDialog,
                        child: Text(
                          '+ Add New',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B0000),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: braceletsCollection
                .where('userID',
                    isEqualTo: widget.userId) // Exact field name match
                .orderBy('purchaseDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Error loading bracelets',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No bracelets found\nTap "+ Add New" to get started',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                );
              }

              final bracelets = snapshot.data!.docs;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final bracelet = bracelets[index];
                    final data = bracelet.data() as Map<String, dynamic>;

                    // Handle the purchase date (might be Timestamp or String)
                    DateTime purchaseDate;
                    if (data['purchaseDate'] is Timestamp) {
                      purchaseDate =
                          (data['purchaseDate'] as Timestamp).toDate();
                    } else {
                      // Try to parse if it's a string (like in the screenshot)
                      try {
                        purchaseDate = DateFormat('d MMMM yyyy')
                            .parse(data['purchaseDate']);
                      } catch (e) {
                        purchaseDate = DateTime.now();
                      }
                    }

                    final formattedDate =
                        DateFormat('MMM dd, yyyy').format(purchaseDate);

                    return ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Card(
                          margin: EdgeInsets.only(bottom: 15),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            title: Text(
                              data['braceletID'] ?? 'Unnamed Bracelet',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 5),
                                Text(
                                  'Purchased: $formattedDate',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 5),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(data[
                                            'usageStatus']), // Updated field name
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        data['usageStatus'] ??
                                            'Unknown', // Updated field name
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              icon: Icon(Icons.more_vert),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: Text('Edit'),
                                  value: 'edit',
                                ),
                                PopupMenuItem(
                                  child: Text('Delete'),
                                  value: 'delete',
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditDialog(bracelet);
                                } else if (value == 'delete') {
                                  _deleteBracelet(bracelet.id);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: bracelets.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
