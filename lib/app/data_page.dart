import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'notifications_page.dart';
import 'account_page.dart';

class EmoBraceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DataPage(userId: 'sampleUserId'),
    );
  }
}

class DataPage extends StatefulWidget {
  final String userId;

  const DataPage({Key? key, required this.userId}) : super(key: key);

  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedDateTime;
  List<String> timestamps = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTimestamps();
  }

  Future<void> _fetchTimestamps() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final querySnapshot = await _firestore.collection('SensorData').get();

      final times = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data.containsKey('Timestamp')) {
              final timestamp = data['Timestamp'];
              if (timestamp is Timestamp) {
                return timestamp.toDate().toString();
              } else if (timestamp is String) {
                return timestamp;
              }
            }
            return null;
          })
          .where((dateString) => dateString != null)
          .map((dateString) => dateString!)
          .toSet()
          .toList();

      setState(() {
        timestamps = times;
      });
    } catch (e) {
      print('Error fetching timestamps: $e');
      setState(() {
        errorMessage = 'Error loading timestamps: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading timestamps: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _exportData() async {
    try {
      if (selectedDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a date/time')),
        );
        return;
      }

      final querySnapshot = await _firestore
          .collection('SensorData')
          .where('Timestamp',
              isEqualTo: Timestamp.fromDate(DateTime.parse(selectedDateTime!)))
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No data available to export.')),
        );
        return;
      }

      // Prepare CSV data
      List<List<String>> csvData = [
        ["Timestamp", "ECG", "GSR", "Temperature", "Emotion", "Suggestion"],
        ...querySnapshot.docs.map((doc) {
          final data = doc.data();
          final output = data['Output'] as Map<String, dynamic>? ?? {};
          return [
            (data['Timestamp'] as Timestamp?)?.toDate().toString() ?? '',
            data['ECG']?.toString() ?? '',
            data['GSR']?.toString() ?? '',
            data['Temperature']?.toString() ?? '',
            output['Emotion']?.toString() ?? '',
            output['Suggestion']?.toString() ?? '',
          ];
        }).toList(),
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get downloads directory
      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        // Try to get the downloads directory
        try {
          downloadsDirectory = Directory('/storage/emulated/0/Download');
          if (!await downloadsDirectory.exists()) {
            downloadsDirectory = await getExternalStorageDirectory();
          }
        } catch (e) {
          downloadsDirectory = await getExternalStorageDirectory();
        }
      } else {
        // For iOS, use documents directory
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      if (downloadsDirectory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create file with timestamp in filename
      final now = DateTime.now();
      final formattedDate =
          '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}';
      final fileName = 'EmoBrace_$formattedDate.csv';
      final filePath = '${downloadsDirectory.path}/$fileName';
      final File file = File(filePath);

      // Write to file
      await file.writeAsString(csv);

      // Show success message with option to open
      final snackBar = SnackBar(
        content: Text('Data exported successfully to ${file.path}'),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () async {
            try {
              // Try to open the file with the open_file package
              final result = await OpenFile.open(filePath);

              // If open_file fails, try using platform-specific methods
              if (result.type != ResultType.done) {
                if (Platform.isAndroid) {
                  // For Android, show the file path so user can navigate to it
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'File saved to: $filePath\nYou can find it in your Downloads folder.'),
                      duration: Duration(seconds: 10),
                    ),
                  );
                } else if (Platform.isIOS) {
                  // For iOS, show the file path in Documents directory
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'File saved to: $filePath\nYou can find it in your Files app.'),
                      duration: Duration(seconds: 10),
                    ),
                  );
                }
              }
            } catch (e) {
              // If all methods fail, show the file path
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File saved to: $filePath'),
                  duration: Duration(seconds: 10),
                ),
              );
            }
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export data: $e')),
      );
    }
  }

// Helper function to format two-digit numbers
  String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  if (isLoading)
                    Center(child: CircularProgressIndicator())
                  else if (errorMessage != null)
                    Center(
                      child: Text(
                        errorMessage!,
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.red),
                      ),
                    )
                  else ...[
                    _buildTimestampDropdown(),
                    SizedBox(height: 20),
                    _buildEmotionChart(),
                    SizedBox(height: 20),
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date & Time:",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            hint: Text(
              "Select the date & time",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            value: selectedDateTime,
            icon: Icon(Icons.arrow_drop_down),
            underline: SizedBox(),
            items: timestamps.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedDateTime = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionChart() {
    return Container(
      constraints: BoxConstraints(
        minHeight: 400,
        maxHeight: 500,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF8B0000), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: EmotionLineChart(userId: widget.userId),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _exportData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF8B0000),
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: Text(
            "Export Data",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShareDataPage(userId: widget.userId),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF8B0000),
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: Text(
            "Share Data",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class EmotionLineChart extends StatefulWidget {
  final String userId;

  const EmotionLineChart({Key? key, required this.userId}) : super(key: key);

  @override
  _EmotionLineChartState createState() => _EmotionLineChartState();
}

class _EmotionLineChartState extends State<EmotionLineChart> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<FlSpot> emotionSpots = [];
  List<String> emotionLabels = [];
  List<String> timestamps = [];
  List<String> suggestions = [];
  bool isLoading = true;
  String? errorMessage;

  final Map<String, int> emotionMapping = {
    "Happy": 6,
    "Neutral": 4,
    "Sad": 2,
    "Angry": 1,
    "Anxious": 3,
    "Stressed": 5
  };

  @override
  void initState() {
    super.initState();
    _fetchEmotionData();
  }

  Future<void> _fetchEmotionData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final querySnapshot = await _firestore
          .collection('SensorData')
          .where('userID', isEqualTo: widget.userId)
          .orderBy('Timestamp')
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No data available for this user';
        });
        return;
      }

      final spots = <FlSpot>[];
      final labels = <String>[];
      final timeList = <String>[];
      final suggestionList = <String>[];
      int index = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final timestamp = data['Timestamp'] as Timestamp?;
        final output = data['Output'] as Map<String, dynamic>? ?? {};
        final emotion = output['Emotion']?.toString() ?? 'Neutral';
        final suggestion = output['Suggestion']?.toString() ?? 'No suggestion';

        if (timestamp != null && emotionMapping.containsKey(emotion)) {
          spots.add(FlSpot(
            index.toDouble(),
            emotionMapping[emotion]!.toDouble(),
          ));
          labels.add(emotion);
          timeList.add(_formatTimestamp(timestamp));
          suggestionList.add(suggestion);
          index++;
        }
      }

      if (spots.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No emotion data available in the records';
        });
        return;
      }

      setState(() {
        emotionSpots = spots;
        emotionLabels = labels;
        timestamps = timeList;
        suggestions = suggestionList;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching emotion data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading emotion data: ${e.toString()}';
      });
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getEmoji(String emotion) {
    final emojiMap = {
      "Happy": '😊',
      "Neutral": '😐',
      "Sad": '😢',
      "Angry": '😠',
      "Anxious": '😰',
      "Stressed": '😫'
    };
    return emojiMap[emotion] ?? '😐';
  }

  Widget _buildChart() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 300,
          padding: EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < timestamps.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            timestamps[value.toInt()],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42, // Increased for better alignment
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      String emotion = '';
                      emotionMapping.forEach((key, val) {
                        if (val == value.toInt()) {
                          emotion = _getEmoji(key);
                        }
                      });
                      return Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Center(
                          child: Text(
                            emotion,
                            style: TextStyle(
                              fontSize: 20, // Larger emoji size
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60, // Increased for longer emotion names
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      String emotion = '';
                      emotionMapping.forEach((key, val) {
                        if (val == value.toInt()) {
                          emotion = key;
                        }
                      });
                      return Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          emotion,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: const Color(0xff37434d),
                  width: 1,
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: emotionSpots,
                  isCurved: true,
                  color: Color(0xFF8B0000),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: Color(0xFF8B0000),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              minY: 0,
              maxY: 6,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      final emotion = emotionLabels[spot.spotIndex];
                      return LineTooltipItem(
                        '$emotion\n${timestamps[spot.spotIndex]}',
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        if (suggestions.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF8B0000).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest Suggestion:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  suggestions.last,
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildChart();
  }
}

class ShareDataPage extends StatefulWidget {
  final String userId;

  const ShareDataPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ShareDataPageState createState() => _ShareDataPageState();
}

class _ShareDataPageState extends State<ShareDataPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSending = false;
  String? selectedDateTime;
  List<String> timestamps = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTimestamps();
  }

  Future<void> _fetchTimestamps() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final querySnapshot = await _firestore
          .collection('SensorData')
          .where('userID', isEqualTo: widget.userId)
          .get();

      final times = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data.containsKey('Timestamp')) {
              final timestamp = data['Timestamp'];
              if (timestamp is Timestamp) {
                return timestamp.toDate().toString();
              } else if (timestamp is String) {
                return timestamp;
              }
            }
            return null;
          })
          .where((dateString) => dateString != null)
          .map((dateString) => dateString!)
          .toSet()
          .toList();

      setState(() {
        timestamps = times;
      });
    } catch (e) {
      print('Error fetching timestamps: $e');
      setState(() {
        errorMessage = 'Error loading timestamps: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildTimestampDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select a Timestamp to Share:",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            hint: Text(
              "Select the date & time",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            value: selectedDateTime,
            icon: Icon(Icons.arrow_drop_down),
            underline: SizedBox(),
            items: timestamps.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedDateTime = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  Future<void> _shareData() async {
    final email = _emailController.text.trim();

    // Input validation
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    if (selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a timestamp')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Fetch sensor data for selected timestamp
      final dataQuery = await _firestore
          .collection('SensorData')
          .where('userID', isEqualTo: widget.userId)
          .where('Timestamp',
              isEqualTo: Timestamp.fromDate(DateTime.parse(selectedDateTime!)))
          .limit(1)
          .get();

      if (dataQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No data found for the selected timestamp')),
        );
        return;
      }

      final data = dataQuery.docs.first.data();
      final pdfFile = await _generateAndSavePdf(data);

      // Show confirmation that PDF was saved
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to Downloads: ${pdfFile.path}'),
          duration: Duration(seconds: 3),
        ),
      );

      // Prepare email content
      final subject = 'EmoBrace Sensor Data - $selectedDateTime';
      final body = '''
Hello,

Attached is the sensor data shared with you from EmoBrace.

User ID: ${widget.userId}
Timestamp: $selectedDateTime

Best regards,
The EmoBrace Team
''';

      await _launchEmailWithAttachment(email, subject, body, pdfFile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share data: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<File> _generateAndSavePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Add content to PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('EmoBrace Sensor Data Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('User ID: ${widget.userId}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Timestamp: $selectedDateTime',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            ...data.entries.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${e.key}: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(child: pw.Text(e.value.toString())),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );

    // Get downloads directory - always save to Downloads
    Directory downloadsDirectory;
    if (Platform.isAndroid) {
      try {
        downloadsDirectory = Directory('/storage/emulated/0/Download');
        if (!await downloadsDirectory.exists()) {
          downloadsDirectory = (await getExternalStorageDirectory())!;
        }
      } catch (e) {
        downloadsDirectory = (await getExternalStorageDirectory())!;
      }
    } else {
      downloadsDirectory = await getApplicationDocumentsDirectory();
    }

    // Create PDF file with timestamp in filename
    final cleanTimestamp =
        selectedDateTime!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final fileName = 'EmoBrace_Data_${widget.userId}_$cleanTimestamp.pdf';
    final filePath = '${downloadsDirectory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> _launchEmailWithAttachment(
      String email, String subject, String body, File pdfFile) async {
    try {
      // Show a dialog explaining what to do
      bool? emailOpened = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Ready to Send'),
          content: Text('Your email client will open with the data attached. '
              'Please click "Send" to complete the sharing process.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF8B0000)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Continue',
                style: TextStyle(color: Color(0xFF8B0000)),
              ),
            ),
          ],
        ),
      );

      if (emailOpened != true) return;

      // First try to launch mailto with attachment
      final mailtoUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': subject,
          'body': body,
          'attachment': pdfFile.path,
        },
      ).toString().replaceAll('+', '%20');

      if (await canLaunchUrl(Uri.parse(mailtoUri))) {
        await launchUrl(
          Uri.parse(mailtoUri),
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      // Fallback to Gmail web interface
      final gmailUri = Uri(
        scheme: 'https',
        host: 'mail.google.com',
        path: '/mail/u/0/',
        queryParameters: {
          'view': 'cm',
          'fs': '1',
          'to': email,
          'su': subject,
          'body': body,
          'attach': pdfFile.path,
        },
      );

      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(
          gmailUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved to: ${pdfFile.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch email: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Share Data',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF8B0000),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the email address of the person you want to share data with:',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                hintText: 'example@domain.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Center(
                child: Text(
                  errorMessage!,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                ),
              )
            else
              _buildTimestampDropdown(),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isSending ? null : _shareData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B0000),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Share via Email",
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
